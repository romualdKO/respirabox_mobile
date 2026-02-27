import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'cough_analysis_extension.dart';
import 'audio_features_extractor.dart';

/// 🎤 SERVICE ASSEMBLYAI
/// Transcription vocale et analyse audio (toux, respiration)
class AssemblyAIService {
  static const String _apiKey = 'a4daf92b53b84a198633a77a2c4b8616';
  static const String _uploadUrl = 'https://api.assemblyai.com/v2/upload';
  static const String _transcriptUrl =
      'https://api.assemblyai.com/v2/transcript';

  /// 📤 Uploader un fichier audio vers AssemblyAI
  Future<String> uploadAudio(String filePath) async {
    try {
      print('🎤 Upload du fichier audio vers AssemblyAI...');

      Uint8List bytes;

      if (kIsWeb) {
        // Sur web, filePath est un blob URL (blob:http://...)
        // On doit le télécharger pour obtenir les bytes
        print('🌐 Mode web: Téléchargement du blob URL...');
        final blobResponse = await http.get(Uri.parse(filePath));
        if (blobResponse.statusCode != 200) {
          throw Exception(
              'Impossible de lire le blob audio: ${blobResponse.statusCode}');
        }
        bytes = blobResponse.bodyBytes;
        print('✅ Blob audio récupéré: ${bytes.length} bytes');
      } else {
        // Sur mobile/desktop, filePath est un chemin de fichier
        final file = File(filePath);
        bytes = await file.readAsBytes();
        print('✅ Fichier audio lu: ${bytes.length} bytes');
      }

      // Upload vers AssemblyAI
      final response = await http.post(
        Uri.parse(_uploadUrl),
        headers: {
          'authorization': _apiKey,
          'Content-Type': 'application/octet-stream',
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final uploadUrl = data['upload_url'];
        print('✅ Fichier uploadé vers AssemblyAI: $uploadUrl');
        return uploadUrl;
      } else {
        throw Exception(
            'Erreur upload AssemblyAI: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur upload audio: $e');
      rethrow;
    }
  }

  /// 🎯 Transcrire un audio en texte
  Future<String> transcribeAudio(String audioUrl,
      {bool analyzeCough = false}) async {
    try {
      print('🎤 Lancement de la transcription...');

      // Créer la requête de transcription
      final transcriptRequest = {
        'audio_url': audioUrl,
        'language_code': 'fr', // Français
        'punctuate': true,
        'format_text': true,
      };

      // Si on veut analyser des sons (toux, respiration)
      if (analyzeCough) {
        transcriptRequest['audio_events_detection'] = true;
      }

      final response = await http.post(
        Uri.parse(_transcriptUrl),
        headers: {
          'authorization': _apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode(transcriptRequest),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final transcriptId = data['id'];
        print('✅ Transcription lancée, ID: $transcriptId');

        // Attendre que la transcription soit terminée
        return await _waitForTranscription(transcriptId, analyzeCough);
      } else {
        throw Exception(
            'Erreur transcription: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur transcription: $e');
      rethrow;
    }
  }

  /// ⏳ Attendre que la transcription soit terminée
  Future<String> _waitForTranscription(
      String transcriptId, bool analyzeCough) async {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));

      final response = await http.get(
        Uri.parse('$_transcriptUrl/$transcriptId'),
        headers: {
          'authorization': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];

        print('📊 Statut transcription: $status');

        if (status == 'completed') {
          final text = data['text'] ?? '';

          // Si analyse audio activée
          if (analyzeCough && data['audio_events'] != null) {
            final events = data['audio_events'] as List;
            if (events.isNotEmpty) {
              final coughEvents = events
                  .where((e) =>
                      e['label'].toString().toLowerCase().contains('cough') ||
                      e['label'].toString().toLowerCase().contains('toux'))
                  .toList();

              if (coughEvents.isNotEmpty) {
                return '🔊 ANALYSE AUDIO DÉTECTÉE:\n\n'
                    '⚠️ ${coughEvents.length} événement(s) de toux détecté(s)\n\n'
                    'Transcription: $text';
              }
            }
          }

          return text;
        } else if (status == 'error') {
          throw Exception('Erreur transcription: ${data['error']}');
        }
        // Continuer à attendre si status == 'queued' ou 'processing'
      } else {
        throw Exception('Erreur vérification: ${response.statusCode}');
      }
    }
  }

  /// 🎤 Transcrire depuis un fichier local
  Future<String> transcribeFromFile(String filePath,
      {bool analyzeCough = false}) async {
    try {
      // 1. Upload le fichier
      final audioUrl = await uploadAudio(filePath);

      // 2. Transcrire
      final transcription =
          await transcribeAudio(audioUrl, analyzeCough: analyzeCough);

      return transcription;
    } catch (e) {
      print('❌ Erreur transcription depuis fichier: $e');
      rethrow;
    }
  }

  /// 🩺 Analyser spécifiquement la toux avec détection TB/Pneumonie
  ///
  /// NOUVEAU: Intègre analyse acoustique avancée (FFT, MFCC, spectral)
  /// et contexte patient pour scoring médical personnalisé
  Future<Map<String, dynamic>> analyzeCough(
    String audioFilePath, {
    Map<String, dynamic>? patientContext,
  }) async {
    try {
      print('🩺 Analyse avancée de la toux avec features acoustiques...');

      // 🎵 ÉTAPE 1: EXTRACTION FEATURES ACOUSTIQUES (NOUVEAU)
      print('🎵 Extraction features audio (FFT, MFCC, spectral)...');
      final audioFeatures =
          await AudioFeaturesExtractor.extractFeatures(audioFilePath);

      print('✅ Features extraites:');
      print('   - Fréquence: ${audioFeatures['frequency']} Hz');
      print(
          '   - Énergie: ${(audioFeatures['energy'] * 100).toStringAsFixed(1)}%');
      print('   - ZCR: ${audioFeatures['zeroCrossingRate']}');
      print('   - Crépitements: ${audioFeatures['crackles']}');

      // 🎤 ÉTAPE 2: TRANSCRIPTION ASSEMBLYAI
      final audioUrl = await uploadAudio(audioFilePath);

      // Configuration avancée pour analyse audio
      final response = await http.post(
        Uri.parse(_transcriptUrl),
        headers: {
          'authorization': _apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'audio_url': audioUrl,
          'language_code': 'fr',
          'speech_model': 'nano',
          'punctuate': false,
          'format_text': false,
          // Activer l'analyse audio avancée
          'audio_start_from': 0,
          'audio_end_at': null,
          'word_boost': ['toux', 'respiration', 'crachat'],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final transcriptId = data['id'];

        // Attendre le résultat avec analyse avancée
        print('⏳ Analyse en cours (ID: $transcriptId)...');
        while (true) {
          await Future.delayed(const Duration(seconds: 2));

          final result = await http.get(
            Uri.parse('$_transcriptUrl/$transcriptId'),
            headers: {'authorization': _apiKey},
          );

          if (result.statusCode == 200) {
            final resultData = json.decode(result.body);

            if (resultData['status'] == 'completed') {
              print('✅ Analyse terminée');
              print('📊 Text transcrit: "${resultData['text']}"');
              print('📊 Confiance: ${resultData['confidence']}');
              print('📊 Durée: ${resultData['audio_duration']}s');

              final text = resultData['text'] ?? '';
              final confidence = resultData['confidence'] ?? 0.0;
              final duration = resultData['audio_duration'] ?? 0.0;

              // 🧠 ÉTAPE 3: ANALYSE INTELLIGENTE AVEC FEATURES ACOUSTIQUES + CONTEXTE
              // ⚠️ NE DÉPEND PLUS DU TEXTE TRANSCRIT!
              // La détection repose sur: durée, énergie, pics sonores
              print(
                  '🎯 Analyse acoustique (transcription ignorée pour détection):');
              print('   - Texte AssemblyAI: "$text"');
              print('   - Durée audio: ${duration}s');
              print('   - Énergie: ${audioFeatures['energy']}');

              final coughAnalysis = CoughAnalysisHelper.analyzeCoughPattern(
                  text.isEmpty ? 'son non-verbal' : text, duration, confidence,
                  audioFeatures: audioFeatures, patientContext: patientContext);

              print('✅ Résultat analyse:');
              print('   - Toux détectée: ${coughAnalysis['hasCough']}');
              print('   - Type toux: ${coughAnalysis['type']}');
              print('   - Risque TB: ${coughAnalysis['tbRisk']}%');
              print(
                  '   - Risque Pneumonie: ${coughAnalysis['pneumoniaRisk']}%');
              print('   - Niveau urgence: ${coughAnalysis['urgencyLevel']}');

              return {
                'status': 'completed',
                'hasCough':
                    coughAnalysis['hasCough'], // Basé UNIQUEMENT sur acoustique
                'text': text.isEmpty
                    ? '[Son non-verbal - analyse acoustique effectuée]'
                    : text,
                'confidence': confidence,
                'duration': duration,
                // Résultats d'analyse médicale
                'coughType': coughAnalysis['type'], // sèche, productive, grasse
                'intensity':
                    coughAnalysis['intensity'], // légère, modérée, sévère
                'frequency':
                    coughAnalysis['frequency'], // nombre estimé de toux
                'tuberculosisRisk': coughAnalysis['tbRisk'], // 0-100
                'pneumoniaRisk': coughAnalysis['pneumoniaRisk'], // 0-100
                'recommendation': coughAnalysis['recommendation'],
                'medicalScore': coughAnalysis['medicalScore'],
                // 🆕 NOUVELLES DONNÉES
                'urgencyLevel': coughAnalysis['urgencyLevel'],
                'actions': coughAnalysis['actions'],
                'diseaseComparison': coughAnalysis['diseaseComparison'],
                'acousticFeatures': coughAnalysis['acousticFeatures'],
                'wetnessProbability': coughAnalysis['wetnessProbability'],
              };
            } else if (resultData['status'] == 'error') {
              throw Exception('Erreur analyse: ${resultData['error']}');
            }
          }
        }
      } else {
        throw Exception(
            'Erreur requête: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur analyse toux: $e');
      return {
        'hasCough': false,
        'coughCount': 0,
        'duration': 0,
        'text': '',
        'error': e.toString(),
      };
    }
  }
}
