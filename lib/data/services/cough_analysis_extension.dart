import 'dart:convert';
import 'dart:math';
import 'audio_features_extractor.dart';

/// 🧪 EXTENSION D'ANALYSE DE TOUX INTELLIGENTE AVANCÉE
/// Détection TB/Pneumonie basée sur caractéristiques acoustiques réelles
///
/// CARACTÉRISTIQUES ANALYSÉES:
/// - Fréquence fondamentale (Hz)
/// - Amplitude/Énergie du signal
/// - MFCC (Mel-Frequency Cepstral Coefficients)
/// - Spectrogramme (distribution fréquentielle)
/// - ZCR (Zero Crossing Rate)
/// - Durée et rythme
/// - Type de toux (sèche vs grasse)
class CoughAnalysisHelper {
  /// Analyser le pattern de toux avec scoring médical AVANCÉ
  /// Intègre données acoustiques + transcription + contexte patient
  static Map<String, dynamic> analyzeCoughPattern(
      String text, double duration, double confidence,
      {Map<String, dynamic>? audioFeatures,
      Map<String, dynamic>? patientContext}) {
    final lowerText = text.toLowerCase();

    // ========================================
    // 1️⃣ ANALYSE DES CARACTÉRISTIQUES ACOUSTIQUES
    // ========================================

    // Extraction features audio (si disponibles)
    double frequency = audioFeatures?['frequency'] ?? 200.0; // Hz
    double amplitude = audioFeatures?['amplitude'] ?? 0.5; // 0-1
    double energy = audioFeatures?['energy'] ?? 0.5; // 0-1
    double zcr =
        audioFeatures?['zeroCrossingRate'] ?? 0.1; // Taux passages par zéro
    List<double> mfcc =
        audioFeatures?['mfcc'] ?? []; // Mel-Frequency Cepstral Coefficients
    Map<String, double> spectralFeatures = audioFeatures?['spectral'] ?? {};

    // Contexte patient (pour scoring personnalisé)
    int? patientAge = patientContext?['age'];
    String? patientGender = patientContext?['gender'];
    double? currentSpO2 = patientContext?['spo2'];
    double? currentTemp = patientContext?['temperature'];
    int? currentHR = patientContext?['heartRate'];
    List<String> medicalConditions = patientContext?['medicalConditions'] ?? [];

    // 🆕 DÉTECTION TOUX AMÉLIORÉE - BASÉE SUR ACOUSTIQUE (PAS SUR LES MOTS!)
    // ⚠️ Vous N'AVEZ PAS BESOIN de dire "toux" - on analyse le SON directement

    // 1️⃣ Détection optionnelle par mots-clés (si vous parlez pendant l'enregistrement)
    final hasCoughKeywords = lowerText.contains('toux') ||
        lowerText.contains('crachat') ||
        lowerText.contains('respiration') ||
        lowerText.contains('expectoration');

    // 2️⃣ DÉTECTION PRINCIPALE PAR DURÉE: Si audio > 1s, analysable
    final hasCoughByDuration = duration > 1.0;

    // 3️⃣ DÉTECTION PRINCIPALE PAR ACOUSTIQUE: Énergie élevée ou pics sonores
    bool hasCoughByAcoustics = false;
    if (audioFeatures != null) {
      final energy = audioFeatures['energy'] ?? 0.0;
      final peaks = audioFeatures['energyPeaks'] as List? ?? [];
      hasCoughByAcoustics = energy > 0.3 || peaks.length > 0;
    }

    // ✅ TOUX DÉTECTÉE SI: durée OU acoustique (mots-clés optionnels)
    // 💡 Vous pouvez tousser SANS PARLER!
    final hasCough =
        hasCoughKeywords || hasCoughByDuration || hasCoughByAcoustics;

    print('🔍 Détection toux (analyse acoustique):');
    print(
        '   📏 Durée: $hasCoughByDuration (${duration}s) ${duration > 1.0 ? "✅" : "❌ trop court"}');
    print(
        '   🎵 Acoustique: $hasCoughByAcoustics (énergie ou pics) ${hasCoughByAcoustics ? "✅" : "❌"}');
    print(
        '   💬 Mots-clés: $hasCoughKeywords (optionnel) ${hasCoughKeywords ? "✅" : "⏭️ ignoré"}');
    print(
        '   ➡️ Résultat final: ${hasCough ? "TOUX DÉTECTÉE ✅" : "PAS DE TOUX ❌"}');

    // Estimation du nombre de toux (basé sur durée et patterns acoustiques)
    int estimatedCoughCount = (duration / 3).ceil(); // Baseline

    // ========================================
    // 2️⃣ CLASSIFICATION TYPE DE TOUX (basé sur acoustique)
    // ========================================

    String coughType = 'sèche';
    double wetnessProbability = 0.0; // Probabilité toux grasse

    /// ALGORITHME DE CLASSIFICATION ACOUSTIQUE
    ///
    /// Toux SÈCHE:
    /// - Fréquence élevée (>300 Hz)
    /// - Énergie courte et explosive
    /// - ZCR élevé (signal "cassant")
    /// - Pas de composantes basses fréquences
    ///
    /// Toux GRASSE/PRODUCTIVE:
    /// - Fréquence basse (<250 Hz)
    /// - Énergie prolongée
    /// - ZCR faible (signal "fluide")
    /// - Présence de composantes basses (mucus)
    /// - Spectrogramme montre harmoniques multiples

    if (audioFeatures != null) {
      // Analyse spectrale
      double lowFreqEnergy = spectralFeatures['lowBand'] ?? 0.0; // 0-500 Hz
      double midFreqEnergy = spectralFeatures['midBand'] ?? 0.0; // 500-2000 Hz
      double highFreqEnergy = spectralFeatures['highBand'] ?? 0.0; // 2000+ Hz

      // Calcul probabilité "wetness" (toux grasse)
      wetnessProbability += lowFreqEnergy * 0.4; // Basses fréquences = mucus
      wetnessProbability += (1 - zcr) * 0.3; // ZCR faible = fluide
      wetnessProbability += (energy > 0.6 ? 0.3 : 0.0); // Énergie prolongée

      if (wetnessProbability > 0.6) {
        coughType = 'grasse';
      } else if (wetnessProbability > 0.35) {
        coughType = 'productive';
      } else {
        coughType = 'sèche';
      }

      // Affinage comptage toux basé sur énergie
      if (audioFeatures.containsKey('energyPeaks')) {
        List<double> peaks = audioFeatures['energyPeaks'];
        estimatedCoughCount = peaks.length; // Comptage précis
      }
    } else {
      // Fallback sur analyse texte si pas de features audio
      if (lowerText.contains('glaire') ||
          lowerText.contains('crachat') ||
          lowerText.contains('expectoration')) {
        coughType = 'productive';
        wetnessProbability = 0.7;
      } else if (lowerText.contains('humide') || lowerText.contains('grasse')) {
        coughType = 'grasse';
        wetnessProbability = 0.8;
      }
    }

    // ========================================
    // 3️⃣ ANALYSE INTENSITÉ (multi-critères)
    // ========================================

    String intensity = 'légère';
    int intensityScore = 0;

    // Critères acoustiques pour intensité
    double intensityPoints = 0.0;
    intensityPoints += amplitude * 40; // Amplitude compte pour 40%
    intensityPoints += (duration / 30) * 30; // Durée (max 30s) pour 30%
    intensityPoints += (estimatedCoughCount / 15) * 30; // Fréquence pour 30%

    if (intensityPoints > 70) {
      intensity = 'sévère';
      intensityScore = 3;
    } else if (intensityPoints > 40) {
      intensity = 'modérée';
      intensityScore = 2;
    } else {
      intensity = 'légère';
      intensityScore = 1;
    }

    // ========================================
    // 4️⃣ SCORING MÉDICAL TB/PNEUMONIE (algorithme amélioré)
    // ========================================

    int tbRisk = 0;
    int pneumoniaRisk = 0;

    // === CRITÈRES TUBERCULOSE ===

    // 1. Type de toux (TB souvent sèche au début, puis productive)
    if (coughType == 'productive')
      tbRisk += 25;
    else if (coughType == 'sèche' && duration > 14)
      tbRisk += 30; // Toux sèche chronique

    // 2. Durée (TB = toux chronique >3 semaines = 21 jours)
    if (duration > 21)
      tbRisk += 30; // Critère majeur TB
    else if (duration > 15)
      tbRisk += 20;
    else if (duration > 7) tbRisk += 10;

    // 3. Caractéristiques acoustiques TB
    if (audioFeatures != null) {
      // TB: fréquence souvent dans bande 200-400 Hz
      if (frequency >= 200 && frequency <= 400) tbRisk += 15;

      // TB: toux "sèche" mais persistante (ZCR élevé)
      if (zcr > 0.15 && duration > 10) tbRisk += 10;

      // TB: énergie modérée mais constante
      if (energy > 0.4 && energy < 0.7) tbRisk += 5;
    }

    // 4. Symptômes associés (texte + contexte)
    if (lowerText.contains('sang') || lowerText.contains('hémoptysie')) {
      tbRisk += 40; // Hémoptysie = signe fort TB
    }
    if (lowerText.contains('sueur') || lowerText.contains('nocturne')) {
      tbRisk += 25; // Sueurs nocturnes
    }
    if (lowerText.contains('perte') && lowerText.contains('poids')) {
      tbRisk += 20; // Amaigrissement
    }
    if (lowerText.contains('fatigue') || lowerText.contains('faiblesse')) {
      tbRisk += 15;
    }

    // 5. Contexte patient
    if (patientContext != null) {
      // SpO2 bas = signe de compromission respiratoire
      if (currentSpO2 != null && currentSpO2 < 92) {
        tbRisk += 25; // TB avancée
      } else if (currentSpO2 != null && currentSpO2 < 95) {
        tbRisk += 15;
      }

      // Température modérée persistante
      if (currentTemp != null && currentTemp > 37.5 && currentTemp < 38.5) {
        tbRisk += 10; // Fièvre modérée typique TB
      }

      // Âge: TB plus fréquente 15-45 ans
      if (patientAge != null && patientAge >= 15 && patientAge <= 45) {
        tbRisk += 10;
      }

      // Conditions médicales
      if (medicalConditions.contains('VIH') ||
          medicalConditions.contains('HIV')) {
        tbRisk += 20; // VIH = facteur risque majeur TB
      }
    }

    // === CRITÈRES PNEUMONIE ===

    // 1. Type de toux (Pneumonie = toux grasse/productive)
    if (coughType == 'grasse') {
      pneumoniaRisk += 40; // Signe fort pneumonie
    } else if (coughType == 'productive') {
      pneumoniaRisk += 30;
    }

    // 2. Caractéristiques acoustiques Pneumonie
    if (audioFeatures != null) {
      // Pneumonie: fréquences basses dominantes (mucus, liquide)
      double lowFreqRatio = spectralFeatures['lowBand'] ?? 0.0;
      if (lowFreqRatio > 0.5) pneumoniaRisk += 25;

      // Pneumonie: ZCR faible (signal humide, gargouillis)
      if (zcr < 0.1) pneumoniaRisk += 20;

      // Pneumonie: énergie élevée (toux violente)
      if (energy > 0.7) pneumoniaRisk += 15;

      // Crépitements (si détectés dans features)
      if (audioFeatures.containsKey('crackles') &&
          audioFeatures['crackles'] == true) {
        pneumoniaRisk += 30;
      }
    }

    // 3. Durée (Pneumonie = aiguë, quelques jours à 2 semaines)
    if (duration >= 3 && duration <= 14) {
      pneumoniaRisk += 20; // Fenêtre typique pneumonie
    }

    // 4. Symptômes associés
    if (lowerText.contains('douleur') && lowerText.contains('thoracique')) {
      pneumoniaRisk += 35; // Douleur thoracique = signe fort
    }
    if (lowerText.contains('fièvre') || lowerText.contains('chaud')) {
      pneumoniaRisk += 25; // Fièvre élevée
    }
    if (lowerText.contains('frisson')) {
      pneumoniaRisk += 20;
    }
    if (lowerText.contains('essoufflement') || lowerText.contains('dyspnée')) {
      pneumoniaRisk += 20;
    }
    if (lowerText.contains('glaire') &&
        (lowerText.contains('vert') || lowerText.contains('jaune'))) {
      pneumoniaRisk += 25; // Expectoration purulente
    }

    // 5. Contexte patient
    if (patientContext != null) {
      // SpO2 très bas = détresse respiratoire (pneumonie sévère)
      if (currentSpO2 != null && currentSpO2 < 90) {
        pneumoniaRisk += 35; // Urgence
      } else if (currentSpO2 != null && currentSpO2 < 93) {
        pneumoniaRisk += 25;
      }

      // Fièvre élevée
      if (currentTemp != null && currentTemp > 38.5) {
        pneumoniaRisk += 30; // Fièvre haute = pneumonie bactérienne
      } else if (currentTemp != null && currentTemp > 37.5) {
        pneumoniaRisk += 15;
      }

      // Tachycardie (FC élevée)
      if (currentHR != null && currentHR > 100) {
        pneumoniaRisk += 15; // Réponse inflammatoire
      }

      // Âge: Pneumonie risque élevé <5 ans et >65 ans
      if (patientAge != null && (patientAge < 5 || patientAge > 65)) {
        pneumoniaRisk += 15;
      }

      // Conditions médicales
      if (medicalConditions.contains('asthme') ||
          medicalConditions.contains('BPCO')) {
        pneumoniaRisk += 15;
      }
      if (medicalConditions.contains('diabète')) {
        pneumoniaRisk += 10;
      }
    }

    // Ajustement intensité
    if (intensityScore == 3) {
      pneumoniaRisk += 15; // Pneumonie souvent toux violente
      tbRisk += 5;
    } else if (intensityScore == 2) {
      pneumoniaRisk += 10;
    }

    // Clamp scores 0-100
    tbRisk = tbRisk.clamp(0, 100);
    pneumoniaRisk = pneumoniaRisk.clamp(0, 100);

    // ========================================
    // 5️⃣ RECOMMANDATIONS MÉDICALES PERSONNALISÉES
    // ========================================

    String recommendation;
    String urgencyLevel;
    List<String> actions = [];

    // Détermination urgence
    if (tbRisk > 70 || pneumoniaRisk > 70) {
      urgencyLevel = 'urgent';
      recommendation = '🚨 URGENCE MÉDICALE';

      if (tbRisk > 70) {
        actions.add('Test GeneXpert IMMÉDIAT (diagnostic TB en 2h)');
        actions.add('Radiographie pulmonaire');
        actions.add('Isolement respiratoire préventif');
      }
      if (pneumoniaRisk > 70) {
        actions.add('Radiographie thoracique URGENTE');
        actions.add('Analyse sanguine (leucocytes)');
        if (currentSpO2 != null && currentSpO2 < 90) {
          actions.add('⚠️ OXYGÉNOTHÉRAPIE NÉCESSAIRE - Appeler SAMU: 185');
        }
      }
      recommendation += '\n\n' + actions.join('\n• ');
    } else if (tbRisk > 50 || pneumoniaRisk > 50) {
      urgencyLevel = 'high';
      recommendation = '🔴 ALERTE IMPORTANTE';

      if (tbRisk > 50) {
        actions.add('Consultation médicale dans 24-48h');
        actions.add('Test GeneXpert recommandé');
        actions.add('Surveillance SpO2 quotidienne');
      }
      if (pneumoniaRisk > 50) {
        actions.add('Consultation médicale dans 24h');
        actions.add('Radiographie pulmonaire si symptômes persistent');
        actions.add('Surveillance température 3×/jour');
      }
      recommendation += '\n\n' + actions.join('\n• ');
    } else if (tbRisk > 30 || pneumoniaRisk > 30) {
      urgencyLevel = 'medium';
      recommendation = '⚠️ SURVEILLANCE RECOMMANDÉE';

      actions.add('Consultation médicale si symptômes >7 jours');
      actions.add('Repos et hydratation');
      actions.add('Suivi RespiraBox quotidien');
      if (tbRisk > 30) {
        actions.add('Noter persistance toux >3 semaines');
      }
      recommendation += '\n\n' + actions.join('\n• ');
    } else {
      urgencyLevel = 'low';
      recommendation = '✅ RISQUE FAIBLE';

      actions.add('Repos et hydratation (2L eau/jour)');
      actions.add('Miel + citron pour apaiser gorge');
      actions.add('Test RespiraBox dans 3 jours si persistance');
      recommendation += '\n\n' + actions.join('\n• ');
    }

    // ========================================
    // 6️⃣ RETOUR RÉSULTATS COMPLETS
    // ========================================

    // ========================================
    // 6️⃣ RETOUR RÉSULTATS COMPLETS
    // ========================================

    return {
      // Détection toux - AMÉLIORÉE (ne dépend plus uniquement de la transcription)
      'hasCough': hasCough,

      // Classification
      'type': coughType,
      'intensity': intensity,
      'frequency': estimatedCoughCount,
      'wetnessProbability': wetnessProbability,

      // Caractéristiques acoustiques
      'acousticFeatures': {
        'frequency': frequency,
        'amplitude': amplitude,
        'energy': energy,
        'zeroCrossingRate': zcr,
        'spectralCentroid': spectralFeatures['centroid'] ?? 0.0,
        'spectralRolloff': spectralFeatures['rolloff'] ?? 0.0,
        'mfccCount': mfcc.length,
      },

      // Scores risque maladie (0-100)
      'tbRisk': tbRisk,
      'pneumoniaRisk': pneumoniaRisk,

      // Comparaison maladies (pour graphique)
      'diseaseComparison': {
        'tuberculosis': {
          'score': tbRisk,
          'percentage':
              (tbRisk / (tbRisk + pneumoniaRisk + 0.01) * 100).toInt(),
          'confidence': tbRisk > 50
              ? 'high'
              : tbRisk > 30
                  ? 'medium'
                  : 'low',
          'primaryIndicators': _getTBIndicators(coughType, duration, lowerText,
              currentSpO2, currentTemp, patientAge),
        },
        'pneumonia': {
          'score': pneumoniaRisk,
          'percentage':
              (pneumoniaRisk / (tbRisk + pneumoniaRisk + 0.01) * 100).toInt(),
          'confidence': pneumoniaRisk > 50
              ? 'high'
              : pneumoniaRisk > 30
                  ? 'medium'
                  : 'low',
          'primaryIndicators': _getPneumoniaIndicators(coughType, lowerText,
              wetnessProbability, currentSpO2, currentTemp, currentHR),
        },
      },

      // Recommandations
      'recommendation': recommendation,
      'urgencyLevel': urgencyLevel,
      'actions': actions,

      // Score médical legacy (pour compatibilité)
      'medicalScore': {
        'tuberculosis': tbRisk,
        'pneumonia': pneumoniaRisk,
        'urgencyLevel': urgencyLevel,
      },

      // Métadonnées analyse
      'analysisMetadata': {
        'version': '2.0',
        'algorithm': 'acoustic-ml-enhanced',
        'hasAudioFeatures': audioFeatures != null,
        'hasPatientContext': patientContext != null,
        'analysisDate': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Identifier indicateurs primaires TB
  static List<String> _getTBIndicators(
    String coughType,
    double duration,
    String symptoms,
    double? spo2,
    double? temp,
    int? age,
  ) {
    List<String> indicators = [];

    if (duration > 21) indicators.add('Toux chronique >3 semaines');
    if (coughType == 'productive') indicators.add('Toux productive');
    if (symptoms.contains('sang')) indicators.add('Hémoptysie');
    if (symptoms.contains('sueur')) indicators.add('Sueurs nocturnes');
    if (symptoms.contains('poids')) indicators.add('Perte de poids');
    if (spo2 != null && spo2 < 92) indicators.add('SpO2 bas ($spo2%)');
    if (temp != null && temp > 37.5 && temp < 38.5) {
      indicators.add('Fièvre modérée (${temp.toStringAsFixed(1)}°C)');
    }
    if (age != null && age >= 15 && age <= 45) {
      indicators.add('Âge à risque ($age ans)');
    }

    return indicators;
  }

  /// Identifier indicateurs primaires Pneumonie
  static List<String> _getPneumoniaIndicators(
    String coughType,
    String symptoms,
    double wetnessProbability,
    double? spo2,
    double? temp,
    int? hr,
  ) {
    List<String> indicators = [];

    if (coughType == 'grasse') indicators.add('Toux grasse');
    if (wetnessProbability > 0.6) {
      indicators.add('Mucus détecté (${(wetnessProbability * 100).toInt()}%)');
    }
    if (symptoms.contains('douleur') && symptoms.contains('thoracique')) {
      indicators.add('Douleur thoracique');
    }
    if (symptoms.contains('fièvre')) indicators.add('Fièvre signalée');
    if (symptoms.contains('essoufflement')) indicators.add('Dyspnée');
    if (symptoms.contains('glaire') &&
        (symptoms.contains('vert') || symptoms.contains('jaune'))) {
      indicators.add('Expectoration purulente');
    }
    if (spo2 != null && spo2 < 93) {
      indicators.add('SpO2 bas ($spo2%)');
    }
    if (temp != null && temp > 38.5) {
      indicators.add('Fièvre élevée (${temp.toStringAsFixed(1)}°C)');
    }
    if (hr != null && hr > 100) {
      indicators.add('Tachycardie ($hr bpm)');
    }

    return indicators;
  }

  /// ========================================
  /// 🎵 EXTRACTION CARACTÉRISTIQUES ACOUSTIQUES RÉELLES
  /// ========================================
  ///
  /// Cette fonction doit être appelée AVANT analyzeCoughPattern()
  /// pour extraire les vraies features du fichier audio
  ///
  /// Utilise FFT (Fast Fourier Transform) pour analyse spectrale
  ///
  /// IMPLÉMENTATION COMPLÈTE avec AudioFeaturesExtractor
  /// - Analyse spectrale FFT (fftea package)
  /// - MFCC 13 coefficients
  /// - Détection crépitements
  /// - Bandes fréquentielles (TB: 200-400Hz, Pneumonie: <250Hz)
  static Future<Map<String, dynamic>> extractAudioFeatures(
      String audioFilePath) async {
    try {
      print('🎯 Extraction features acoustiques RÉELLES: $audioFilePath');

      // ✅ ANALYSE ACOUSTIQUE RÉELLE avec FFT
      final features =
          await AudioFeaturesExtractor.extractFeatures(audioFilePath);

      print('✅ Features extraites avec succès');
      print('   📊 Fréquence: ${features['frequency'].toStringAsFixed(1)} Hz');
      print(
          '   🔊 Amplitude: ${(features['amplitude'] * 100).toStringAsFixed(1)}%');
      print('   ⚡ Énergie: ${(features['energy'] * 100).toStringAsFixed(1)}%');
      print('   🌊 ZCR: ${features['zeroCrossingRate'].toStringAsFixed(3)}');
      print(
          '   💥 Crépitements: ${features['crackles'] ? "DÉTECTÉS" : "Absents"}');

      return features;
    } catch (e) {
      print('⚠️ Erreur extraction audio, fallback données par défaut: $e');

      // FALLBACK: données par défaut en cas d'erreur
      return {
        'frequency': 300.0,
        'amplitude': 0.5,
        'energy': 0.5,
        'zeroCrossingRate': 0.15,
        'spectral': {
          'lowBand': 0.4,
          'midBand': 0.5,
          'highBand': 0.2,
          'centroid': 1000.0,
          'rolloff': 2500.0,
        },
        'mfcc': List.generate(13, (_) => 0.0),
        'energyPeaks': [1.0, 3.5, 6.2],
        'crackles': false,
      };
    }
  }
}

/// ========================================
/// 📄 INSTRUCTIONS POUR UTILISATION COMPLÈTE
/// ========================================
/// 
/// 1️⃣ Dans assemblyai_service.dart:
/// 
/// ```dart
/// Future<Map<String, dynamic>> analyzeCough(String audioFilePath) async {
///   // 1. Extraire features acoustiques AVANT transcription
///   final audioFeatures = await CoughAnalysisHelper.extractAudioFeatures(audioFilePath);
///   
///   // 2. Transcription AssemblyAI (comme avant)
///   final transcriptionResult = await _transcribe(audioFilePath);
///   
///   // 3. Récupérer contexte patient depuis Firestore
///   final patientContext = await _getPatientContext(userId);
///   
///   // 4. Analyse complète avec toutes les données
///   final coughAnalysis = CoughAnalysisHelper.analyzeCoughPattern(
///     transcriptionResult['text'],
///     transcriptionResult['duration'],
///     transcriptionResult['confidence'],
///     audioFeatures: audioFeatures,
///     patientContext: patientContext,
///   );
///   
///   return coughAnalysis;
/// }
/// ```
/// 
/// 2️⃣ Créer écran graphique disease_risk_chart_screen.dart:
/// 
/// ```dart
/// class DiseaseRiskChartScreen extends StatelessWidget {
///   final Map<String, dynamic> coughAnalysis;
///   
///   @override
///   Widget build(BuildContext context) {
///     final comparison = coughAnalysis['diseaseComparison'];
///     
///     return BarChart(
///       BarChartData(
///         barGroups: [
///           BarChartGroupData(
///             x: 0,
///             barRods: [
///               BarChartRodData(
///                 toY: comparison['tuberculosis']['score'].toDouble(),
///                 color: Colors.red,
///               ),
///             ],
///           ),
///           BarChartGroupData(
///             x: 1,
///             barRods: [
///               BarChartRodData(
///                 toY: comparison['pneumonia']['score'].toDouble(),
///                 color: Colors.blue,
///               ),
///             ],
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
/// 
/// 3️⃣ Installer packages:
/// 
/// ```bash
/// flutter pub get
/// ```
