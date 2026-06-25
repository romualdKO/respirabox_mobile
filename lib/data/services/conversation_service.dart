import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation_model.dart';

/// 💬 SERVICE DE GESTION DES CONVERSATIONS
/// Gère l'historique et la persistance des conversations du chatbot
class ConversationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer une nouvelle conversation
  Future<ConversationModel> createConversation({
    required String userId,
    String? firstMessage,
  }) async {
    try {
      // Générer un titre basé sur le premier message ou l'heure
      final title = firstMessage != null && firstMessage.length > 30
          ? '${firstMessage.substring(0, 30)}...'
          : firstMessage ?? 'Nouvelle conversation';

      final now = DateTime.now();
      final conversationData = {
        'userId': userId,
        'title': title,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'messages': [],
        'isActive': true,
      };

      final docRef =
          await _firestore.collection('conversations').add(conversationData);

      return ConversationModel(
        id: docRef.id,
        userId: userId,
        title: title,
        createdAt: now,
        updatedAt: now,
        messages: [],
        isActive: true,
      );
    } catch (e) {
      print('❌ Erreur création conversation: $e');
      rethrow;
    }
  }

  /// Ajouter un message à une conversation
  Future<void> addMessage({
    required String conversationId,
    required String text,
    required bool isUser,
  }) async {
    try {
      final message = MessageModel(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('conversations').doc(conversationId).update({
        'messages': FieldValue.arrayUnion([message.toJson()]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Erreur ajout message: $e');
      rethrow;
    }
  }

  /// Récupérer toutes les conversations d'un utilisateur (tri client-side)
  Future<List<ConversationModel>> getUserConversations(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .where('userId', isEqualTo: userId)
          .get();

      final list = snapshot.docs
          .map((doc) => ConversationModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    } catch (e) {
      print('❌ Erreur récupération conversations: $e');
      return [];
    }
  }

  /// Récupérer une conversation spécifique
  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      final doc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (doc.exists) {
        return ConversationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération conversation: $e');
      return null;
    }
  }

  /// Récupérer la dernière conversation active
  /// Tri côté client pour éviter l'index composite Firestore
  Future<ConversationModel?> getActiveConversation(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) return null;

      // Trier par updatedAt côté client (évite l'index composite)
      final docs = snapshot.docs
        ..sort((a, b) {
          final aDate = a.data()['updatedAt'] as String? ?? '';
          final bDate = b.data()['updatedAt'] as String? ?? '';
          return bDate.compareTo(aDate);
        });

      return ConversationModel.fromFirestore(docs.first);
    } catch (e) {
      print('Erreur récupération conversation active: $e');
      return null;
    }
  }

  /// Marquer toutes les conversations comme inactives
  Future<void> deactivateAllConversations(String userId) async {
    try {
      // Récupérer TOUTES les conversations de l'utilisateur (pas de filtre isActive)
      final snapshot = await _firestore
          .collection('conversations')
          .where('userId', isEqualTo: userId)
          .get();

      print('🔄 Désactivation de ${snapshot.docs.length} conversations...');

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isActive': false});
      }
      await batch.commit();
      
      print('✅ Conversations désactivées');
    } catch (e) {
      print('❌ Erreur désactivation conversations: $e');
    }
  }

  /// Activer une conversation spécifique
  Future<void> activateConversation(String conversationId) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'isActive': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Conversation $conversationId activée');
    } catch (e) {
      print('❌ Erreur activation conversation: $e');
      rethrow;
    }
  }

  /// Supprimer une conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).delete();
    } catch (e) {
      print('❌ Erreur suppression conversation: $e');
      rethrow;
    }
  }

  /// Mettre à jour le titre d'une conversation
  Future<void> updateConversationTitle({
    required String conversationId,
    required String title,
  }) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'title': title,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Erreur mise à jour titre: $e');
      rethrow;
    }
  }

  /// Stream des conversations en temps réel (tri client-side, pas d'index composite)
  Stream<List<ConversationModel>> watchUserConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ConversationModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  /// Stream d'une conversation spécifique
  Stream<ConversationModel?> watchConversation(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return ConversationModel.fromFirestore(doc);
      }
      return null;
    });
  }
}
