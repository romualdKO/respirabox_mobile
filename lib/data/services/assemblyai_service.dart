import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'cough_analysis_extension.dart';
import 'audio_features_extractor.dart';
import 'gemini_ai_service.dart';
import '../../core/constants/app_constants.dart';

/// SERVICE ASSEMBLYAI
/// Transcription vocale et analyse audio (toux, respiration)
class AssemblyAIService {
  static String get _apiKey => AppConstants.assemblyAiApiKey;
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

  /// ⏳ Attendre que la transcription soit terminée (max 60s)
  Future<String> _waitForTranscription(
      String transcriptId, bool analyzeCough) async {
    const maxRetries = 30; // 30 × 2s = 60s maximum
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      await Future.delayed(const Duration(seconds: 2));

      try {
        final response = await http.get(
          Uri.parse('$_transcriptUrl/$transcriptId'),
          headers: {'authorization': _apiKey},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final status = data['status'];

          if (status == 'completed') {
            final text = data['text'] as String? ?? '';

            if (analyzeCough && data['audio_events'] != null) {
              final events = data['audio_events'] as List;
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

            return text;
          } else if (status == 'error') {
            throw Exception('Erreur transcription: ${data['error']}');
          }
        } else {
          throw Exception('Erreur vérification: ${response.statusCode}');
        }
      } catch (e) {
        if (attempt >= maxRetries - 1) rethrow;
        print('⚠️ Polling tentative $attempt: $e');
      }
    }
    throw Exception('Transcription timeout après ${maxRetries * 2}s');
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
    // ÉTAPE 1a : Gemini ML audio (si clé valide) — vrai modèle ML multimodal
    print('🤖 Tentative analyse ML Gemini Audio...');
    final geminiML = await GeminiAIService().analyzeAudio(
      audioFilePath,
      patientContext: patientContext,
    );
    final hasGeminiML = geminiML.isNotEmpty;
    if (hasGeminiML) {
      print('✅ Gemini ML disponible — scores ML utilisés en priorité');
    }

    // ÉTAPE 1b : Extraction acoustique locale (WAV → PCM) — fallback FFT
    print('🎵 Extraction features audio FFT locales...');
    final audioFeatures =
        await AudioFeaturesExtractor.extractFeatures(audioFilePath);
    final localDuration = (audioFeatures['duration'] as double?) ?? 0.0;
    print(
        '✅ FFT: durée=${localDuration.toStringAsFixed(1)}s  énergie=${(audioFeatures['energy'] * 100).toStringAsFixed(0)}%  pics=${(audioFeatures['energyPeaks'] as List).length}');

    // ÉTAPE 2 : Transcription AssemblyAI (optionnelle — enrichit le texte)
    String transcribedText = '';
    double confidence = 0.8;
    double assemblyDuration = localDuration;

    try {
      final audioUrl = await uploadAudio(audioFilePath);
      final response = await http
          .post(
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
              'word_boost': ['toux', 'respiration', 'crachat'],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final transcriptId = json.decode(response.body)['id'];
        print('⏳ Transcription AssemblyAI (ID: $transcriptId)...');

        for (int i = 0; i < 30; i++) {
          await Future.delayed(const Duration(seconds: 2));
          final poll = await http.get(
            Uri.parse('$_transcriptUrl/$transcriptId'),
            headers: {'authorization': _apiKey},
          );
          if (poll.statusCode == 200) {
            final d = json.decode(poll.body);
            if (d['status'] == 'completed') {
              transcribedText = d['text'] ?? '';
              confidence = (d['confidence'] as num?)?.toDouble() ?? 0.8;
              assemblyDuration =
                  (d['audio_duration'] as num?)?.toDouble() ?? localDuration;
              print('✅ AssemblyAI: "$transcribedText" (${assemblyDuration}s)');
              break;
            } else if (d['status'] == 'error') {
              break;
            }
          }
        }
      }
    } catch (e) {
      // AssemblyAI facultatif — on continue avec l'analyse acoustique seule
      print('⚠️ AssemblyAI indisponible: $e → analyse acoustique seule');
    }

    // Meilleure durée disponible (AssemblyAI > locale)
    final bestDuration = assemblyDuration > 0 ? assemblyDuration : localDuration;

    // Durée symptômes déclarée par le patient (questionnaire)
    final symptomDurationDays =
        (patientContext?['symptomDurationDays'] as int?) ?? 0;

    // ÉTAPE 3 : Analyse clinique règles (WHO TB + PSI Pneumonie)
    final coughAnalysis = CoughAnalysisHelper.analyzeCoughPattern(
      transcribedText.isEmpty ? 'son non-verbal' : transcribedText,
      bestDuration,
      confidence,
      audioFeatures: audioFeatures,
      patientContext: patientContext,
      symptomDurationDays: symptomDurationDays,
    );

    // ÉTAPE 4 : Fusion ML Gemini + scoring clinique
    // Si Gemini ML disponible : pondération dynamique selon mlConfidence
    // (avant: 60/40 fixe, qui ignorait la confiance réelle du modèle ML)
    // Si Gemini indisponible : scoring clinique seul
    int finalTbRisk;
    int finalPneumoniaRisk;
    bool finalHasCough;
    String finalCoughType;
    String finalIntensity;
    double mlConfidence = 0.0;

    if (hasGeminiML) {
      final mlTb = (geminiML['tbScore'] as num?)?.toInt() ?? 0;
      final mlPneumonia = (geminiML['pneumoniaScore'] as num?)?.toInt() ?? 0;
      final mlHasCough = geminiML['hasCough'] as bool? ?? true;
      mlConfidence = (geminiML['mlConfidence'] as num?)?.toDouble() ?? 0.8;

      // Poids ML proportionnel à sa confiance, borné à [30%, 80%] pour que
      // le scoring clinique garde toujours un poids significatif même quand
      // Gemini est très confiant, et inversement ML garde un poids minimal
      // quand sa confiance est faible plutôt que d'être ignoré à 0%.
      final mlWeight = (0.3 + mlConfidence * 0.5).clamp(0.3, 0.8);
      final clinicalWeight = 1 - mlWeight;

      finalTbRisk = ((mlTb * mlWeight) + (coughAnalysis['tbRisk'] * clinicalWeight)).round().clamp(0, 100);
      finalPneumoniaRisk = ((mlPneumonia * mlWeight) + (coughAnalysis['pneumoniaRisk'] * clinicalWeight)).round().clamp(0, 100);
      // hasCough : OR entre ML et acoustique (si l'un des deux le détecte → vrai)
      finalHasCough = mlHasCough || (coughAnalysis['hasCough'] as bool? ?? false);
      finalCoughType = geminiML['coughType'] as String? ?? coughAnalysis['type'] as String;
      finalIntensity = geminiML['intensity'] as String? ?? coughAnalysis['intensity'] as String;

      print('🩺 FUSION ML+Clinique: hasCough=$finalHasCough  TB=$finalTbRisk%  Pneumonie=$finalPneumoniaRisk%  (poids ML=${(mlWeight*100).toInt()}% confiance=${(mlConfidence*100).toInt()}%)');
    } else {
      finalTbRisk = coughAnalysis['tbRisk'] as int;
      finalPneumoniaRisk = coughAnalysis['pneumoniaRisk'] as int;
      finalHasCough = coughAnalysis['hasCough'] as bool? ?? false;
      finalCoughType = coughAnalysis['type'] as String;
      finalIntensity = coughAnalysis['intensity'] as String;
      print('🩺 Scoring clinique seul: hasCough=$finalHasCough  TB=$finalTbRisk%  Pneumonie=$finalPneumoniaRisk%');
    }

    // Fiabilité: fausse si l'audio local était illisible/vide ET que Gemini
    // ML n'a pas pu compenser avec sa propre analyse.
    final bool isReliable =
        (coughAnalysis['isReliable'] as bool? ?? true) || hasGeminiML;

    return {
      'status': 'completed',
      'hasCough': finalHasCough,
      'isReliable': isReliable,
      'text': transcribedText.isEmpty ? '[Analyse acoustique]' : transcribedText,
      'confidence': confidence,
      'duration': bestDuration,
      'type': finalCoughType,
      'intensity': finalIntensity,
      'frequency': coughAnalysis['frequency'],
      'tbRisk': finalTbRisk,
      'pneumoniaRisk': finalPneumoniaRisk,
      'recommendation': coughAnalysis['recommendation'],
      'medicalScore': coughAnalysis['medicalScore'],
      'urgencyLevel': coughAnalysis['urgencyLevel'],
      'actions': coughAnalysis['actions'],
      'diseaseComparison': coughAnalysis['diseaseComparison'],
      'acousticFeatures': coughAnalysis['acousticFeatures'],
      'wetnessProbability': coughAnalysis['wetnessProbability'],
      // Méta-données sur la source d'analyse
      'analysisSource': hasGeminiML ? 'gemini-ml+clinical' : 'clinical-only',
      'mlConfidence': mlConfidence,
      'mlNotes': hasGeminiML ? (geminiML['acousticNotes'] ?? '') : '',
    };
  }
}
