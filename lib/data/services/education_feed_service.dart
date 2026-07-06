import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/education_post_model.dart';

/// 📰 SERVICE FLUX ÉDUCATIF SANTÉ RESPIRATOIRE
///
/// Les posts sont alimentés par `EducationSyncService` (synchronisation
/// côté app depuis le flux RSS OMS Afrique — voir ce fichier pour le
/// contexte sur pourquoi ce n'est pas une Cloud Function). Ce service-ci ne
/// fait que lire Firestore et gérer les réactions emoji des utilisateurs.
class EducationFeedService {
  static const String _collection = 'education_posts';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Flux des posts, triés du plus récent au plus ancien, filtrés par
  /// catégorie si différente de [EducationCategory.all].
  Stream<List<EducationPostModel>> watchPosts({String category = EducationCategory.all}) {
    Query query = _firestore
        .collection(_collection)
        .orderBy('publishedAt', descending: true)
        .limit(100);

    if (category != EducationCategory.all) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => EducationPostModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Réaction actuelle de l'utilisateur pour un post (null si aucune)
  Future<String?> getUserReaction(String postId, String userId) async {
    final doc = await _firestore
        .collection(_collection)
        .doc(postId)
        .collection('reactions')
        .doc(userId)
        .get();
    return doc.data()?['emoji'] as String?;
  }

  /// Définit (ou change) la réaction emoji de l'utilisateur sur un post.
  /// Met à jour le compteur agrégé `reactionCounts` de façon transactionnelle.
  Future<void> setReaction({
    required String postId,
    required String userId,
    required String emoji,
  }) async {
    final postRef = _firestore.collection(_collection).doc(postId);
    final reactionRef = postRef.collection('reactions').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final reactionSnap = await transaction.get(reactionRef);
      final previousEmoji = reactionSnap.data()?['emoji'] as String?;

      if (previousEmoji == emoji) {
        // Cliquer sur la même réaction = la retirer
        transaction.delete(reactionRef);
        transaction.update(postRef, {
          'reactionCounts.$emoji': FieldValue.increment(-1),
        });
        return;
      }

      transaction.set(reactionRef, {'emoji': emoji});
      transaction.update(postRef, {
        'reactionCounts.$emoji': FieldValue.increment(1),
        if (previousEmoji != null)
          'reactionCounts.$previousEmoji': FieldValue.increment(-1),
      });
    });
  }
}
