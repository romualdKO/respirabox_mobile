import 'package:cloud_firestore/cloud_firestore.dart';

/// 📰 POST D'ÉDUCATION SANTÉ RESPIRATOIRE
///
/// Synchronisé depuis le flux RSS officiel OMS Afrique (afro.who.int) par
/// `EducationSyncService` à l'ouverture de l'écran éducation. Le contenu
/// éditorial n'est réécrit que pour des upserts identiques (voir
/// firestore.rules) — seul `reactionCounts` change vraiment côté utilisateur
/// via les réactions emoji.
class EducationPostModel {
  final String id;
  final String title;
  final String summary;
  final String? imageUrl;
  final String sourceUrl;
  final String sourceName;
  final DateTime publishedAt;
  final String category; // 'air_quality', 'tuberculosis', 'pneumonia', 'asthma', 'emergency', 'general'
  final Map<String, int> reactionCounts;

  const EducationPostModel({
    required this.id,
    required this.title,
    required this.summary,
    this.imageUrl,
    required this.sourceUrl,
    required this.sourceName,
    required this.publishedAt,
    required this.category,
    this.reactionCounts = const {},
  });

  factory EducationPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EducationPostModel(
      id: doc.id,
      title: data['title'] ?? '',
      summary: data['summary'] ?? '',
      imageUrl: data['imageUrl'],
      sourceUrl: data['sourceUrl'] ?? '',
      sourceName: data['sourceName'] ?? 'OMS Afrique',
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: data['category'] ?? 'general',
      reactionCounts: Map<String, int>.from(data['reactionCounts'] ?? {}),
    );
  }
}

/// 🏷️ CATÉGORIES DE FILTRAGE DU FLUX ÉDUCATIF
class EducationCategory {
  static const String all = 'all';
  static const String airQuality = 'air_quality';
  static const String tuberculosis = 'tuberculosis';
  static const String pneumonia = 'pneumonia';
  static const String asthma = 'asthma';
  static const String emergency = 'emergency';
  static const String general = 'general';

  static const List<String> values = [
    all, airQuality, tuberculosis, pneumonia, asthma, emergency, general,
  ];

  static String label(String category) {
    switch (category) {
      case airQuality:
        return 'Qualité de l\'air';
      case tuberculosis:
        return 'Tuberculose';
      case pneumonia:
        return 'Pneumonie';
      case asthma:
        return 'Asthme';
      case emergency:
        return 'Urgences';
      case general:
        return 'Général';
      default:
        return 'Tout';
    }
  }
}
