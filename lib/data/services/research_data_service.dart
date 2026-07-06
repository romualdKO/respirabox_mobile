import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:crypto/crypto.dart';

/// 🔬 CONTRIBUTION DE DONNÉES POUR LA RECHERCHE (opt-in)
///
/// Envoie l'enregistrement de toux + résultats d'analyse vers un jeu de
/// données de recherche séparé, uniquement si l'utilisateur a explicitement
/// consenti (`UserModel.allowResearchDataSharing`, voir profile_screen.dart).
///
/// Objectif : constituer un vrai dataset de toux enregistrées au micro de
/// smartphone (contrairement à ICBHI 2017, enregistré au stéthoscope — voir
/// ml/README.md) pour ré-entraîner un modèle mieux adapté à l'usage réel.
///
/// Pseudonymisation : l'identifiant utilisateur n'est jamais transmis en
/// clair, seulement un hash SHA-256 salé, non réversible vers l'identité
/// réelle. La voix elle-même reste un identifiant biométrique potentiel —
/// limite assumée et explicitée dans le dialog de consentement.
class ResearchDataService {
  static const String _collection = 'research_cough_dataset';
  static const String _storagePath = 'research_audio';

  /// Salt fixe côté app — suffisant ici car l'objectif n'est pas la sécurité
  /// cryptographique mais d'éviter de stocker le userId réel en clair.
  static const String _salt = 'respirabox_research_v1';

  static String pseudonymize(String userId) {
    final bytes = utf8.encode('$_salt::$userId');
    return sha256.convert(bytes).toString();
  }

  /// Soumet la contribution si [consented] est vrai. Échoue silencieusement
  /// (non bloquant pour le flux principal d'analyse) en cas d'erreur réseau.
  static Future<void> submitIfConsented({
    required String userId,
    required bool consented,
    required String audioFilePath,
    required Map<String, dynamic> analysisResult,
  }) async {
    if (!consented) return;

    try {
      final pseudoId = pseudonymize(userId);
      final testId = DateTime.now().millisecondsSinceEpoch.toString();

      final audioFile = File(audioFilePath);
      if (!await audioFile.exists()) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('$_storagePath/$pseudoId/$testId.wav');
      await storageRef.putFile(
        audioFile,
        SettableMetadata(contentType: 'audio/wav'),
      );
      final audioUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection(_collection).add({
        'pseudonymId': pseudoId,
        'audioUrl': audioUrl,
        'acousticFeatures': analysisResult['acousticFeatures'],
        'tbRisk': analysisResult['tbRisk'],
        'pneumoniaRisk': analysisResult['pneumoniaRisk'],
        'coughType': analysisResult['type'],
        'intensity': analysisResult['intensity'],
        'wetnessProbability': analysisResult['wetnessProbability'],
        'isReliable': analysisResult['isReliable'],
        'submittedAt': FieldValue.serverTimestamp(),
      });

      print('🔬 Contribution recherche envoyée (pseudonyme: $pseudoId)');
    } catch (e) {
      print('⚠️ Contribution recherche échouée (non bloquant): $e');
    }
  }
}
