import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/test_result_model.dart';
import 'patient_context_service.dart';
import '../../core/constants/app_constants.dart';

/// SERVICE IA — GOOGLE GEMINI (REST v1) + Cohere fallback
class GeminiAIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get _hasGeminiKey {
    final key = AppConstants.geminiApiKey;
    return key.isNotEmpty && key.startsWith('AIza');
  }

  GeminiAIService() {
    if (_hasGeminiKey) {
      print('[GeminiAI] Clé Gemini détectée (${AppConstants.geminiModel})');
    } else {
      print('[GeminiAI] Clé Gemini absente → mode Cohere/Offline');
    }
  }

  // ── POINT D'ENTRÉE UNIQUE ─────────────────────────────────────────────────
  Future<String> _callAI(String prompt) async {
    if (_hasGeminiKey) {
      try {
        final result = await _callGeminiRest(prompt);
        if (result.isNotEmpty) return result;
      } catch (e) {
        print('[GeminiAI] Erreur REST: $e → bascule sur Cohere');
      }
    }
    return _callCohere(prompt);
  }

  /// Appel direct à l'API Gemini REST v1 (sans SDK — plus compatible)
  Future<String> _callGeminiRest(String prompt) async {
    final key = AppConstants.geminiApiKey;
    final model = AppConstants.geminiModel;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/$model:generateContent?key=$key',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    });

    final response = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (text != null && text.trim().isNotEmpty) {
        print('[GeminiAI] ✅ Réponse reçue (${text.length} chars)');
        return text.trim();
      }
    } else {
      print('[GeminiAI] HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}');
    }
    return '';
  }

  /// Fallback HTTP vers Cohere quand Gemini est absent ou échoue
  Future<String> _callCohere(String prompt) async {
    final key = AppConstants.cohereApiKey;
    if (key.isEmpty) return _callOffline(prompt);

    final models = ['command-a-03-2025', 'command-r-plus-08-2024', 'command-r7b-12-2024'];
    for (final model in models) {
      try {
        final response = await http.post(
          Uri.parse(AppConstants.cohereApiUrl),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'model': model, 'message': prompt, 'temperature': 0.7}),
        ).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            print('[Cohere] Réponse reçue (model: $model)');
            return text.trim();
          }
        }
      } catch (e) {
        print('[Cohere] Modèle $model indisponible: $e');
      }
    }
    return _callOffline(prompt);
  }

  /// Mode hors-ligne intelligent — répond sans API via règles médicales
  String _callOffline(String prompt) {
    print('[OfflineAI] Mode hors-ligne activé');
    final p = prompt.toLowerCase();

    // Urgences
    if (p.contains('spo2') && (p.contains('< 90') || p.contains('90%') || p.contains('hypox'))) {
      return '🚨 SpO2 inférieure à 90% — situation critique. Consultez un médecin ou appelez les urgences immédiatement. Asseyez-vous, respirez lentement par le nez.';
    }
    if (p.contains('urgence') || p.contains('difficul') && p.contains('respir')) {
      return '🚨 En cas de détresse respiratoire, appelez le 15 (SAMU) ou rendez-vous aux urgences immédiatement. Ne restez pas seul.';
    }

    // Tuberculose
    if (p.contains('tuberculose') || p.contains(' tb ') || p.contains('toux') && p.contains('semaine')) {
      return '🔴 La tuberculose (TB) se manifeste par : toux persistante >3 semaines, sueurs nocturnes, fièvre légère, perte de poids. Un test GeneXpert ou radio thorax est nécessaire. Consultez un médecin pour un dépistage.';
    }

    // Pneumonie
    if (p.contains('pneumonie') || p.contains('poumon') || p.contains('fièvre') && p.contains('toux')) {
      return '🔵 La pneumonie combine toux + fièvre >38.5°C + SpO2 basse. Si SpO2 < 94%, consultez rapidement. Un antibiotique prescrit par médecin est nécessaire. Hydratez-vous bien.';
    }

    // SpO2 normale
    if (p.contains('spo2') || p.contains('oxygène') || p.contains('saturation')) {
      return 'La SpO2 mesure l\'oxygène dans le sang. Normale : 95–100%. Entre 90–94% : surveillance nécessaire. En dessous de 90% : urgence médicale. Votre capteur ESP32 mesure cela en temps réel.';
    }

    // Fréquence cardiaque
    if (p.contains('fréquence') || p.contains('cardiaque') || p.contains('pouls') || p.contains('bpm')) {
      return 'La fréquence cardiaque normale au repos est 60–100 bpm. En dessous de 50 bpm : bradycardie. Au-dessus de 120 bpm au repos : tachycardie. RespiraBox mesure votre FC via le capteur MAX30100.';
    }

    // Température
    if (p.contains('température') || p.contains('fièvre') || p.contains('°c')) {
      return 'Température normale : 36.1–37.2°C. Légère fièvre : 37.3–38.4°C. Fièvre : >38.5°C. En cas de fièvre persistante avec toux, consultez un médecin. Prenez du paracétamol si nécessaire.';
    }

    // Résultats de test
    if (p.contains('résultat') || p.contains('score') || p.contains('risque')) {
      return '📊 Votre score de risque est calculé à partir de la SpO2, fréquence cardiaque et température. Score >70 = risque élevé (consultation urgente). Score 30–70 = risque modéré (surveillance). Score <30 = risque faible (continuer les tests réguliers).';
    }

    // Conseils généraux
    if (p.contains('conseil') || p.contains('recommand') || p.contains('améliorer')) {
      return '✅ Conseils pour une bonne santé respiratoire :\n1. Évitez la fumée et la pollution\n2. Aérez votre domicile quotidiennement\n3. Lavez-vous les mains régulièrement\n4. Faites 30 min d\'exercice par jour\n5. Effectuez des tests RespiraBox régulièrement';
    }

    // Réponse générique médicale
    return '🏥 Je suis l\'assistant médical RespiraBox. Je peux vous aider sur :\n• Interprétation de vos mesures (SpO2, FC, Température)\n• Symptômes de tuberculose ou pneumonie\n• Conseils de santé respiratoire\n• Résultats de vos tests\n\nPour une vraie consultation IA, configurez une clé Gemini dans les paramètres.';
  }

  Future<String> _callGemini(String prompt) => _callAI(prompt);

  // ──────────────────────────────────────────────────────────────
  //  CHATBOT PRINCIPAL
  // ──────────────────────────────────────────────────────────────

  /// Envoie un message au chatbot médical avec contexte patient + historique
  Future<String> sendMessage({
    required String userMessage,
    required String userId,
    List<Map<String, String>>? history, // Derniers échanges [{role, text}]
  }) async {
    try {
      final firestoreContext = await _getUserHealthContext(userId);
      final localContext = await PatientContextService.buildPatientContext();
      final localContextStr = _formatLocalContext(localContext);

      final prompt = _buildIntelligentPrompt(
        userMessage,
        firestoreContext,
        localContextStr,
        history: history,
      );

      return await _callAI(prompt);
    } catch (e) {
      print('[GeminiAI] Erreur sendMessage: $e');
      return 'Une erreur s\'est produite. Veuillez réessayer.';
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  ANALYSE AUDIO MULTIMODALE (Gemini 1.5 Flash — vrai modèle ML)
  // ──────────────────────────────────────────────────────────────

  /// Envoie l'audio WAV à Gemini 1.5 Flash pour analyse ML de la toux.
  /// Retourne {} si Gemini non configuré (clé invalide) → fallback FFT.
  Future<Map<String, dynamic>> analyzeAudio(
    String audioPath, {
    Map<String, dynamic>? patientContext,
  }) async {
    if (!_hasGeminiKey) {
      print('[GeminiAudio] Clé invalide — analyse ML indisponible');
      return {};
    }

    try {
      final file = File(audioPath);
      if (!await file.exists()) return {};
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.length < 1000) return {};

      final contextStr = _buildClinicalContextString(patientContext);
      final audioMime = audioPath.endsWith('.wav') ? 'audio/wav' : 'audio/aac';
      final audioB64 = base64Encode(bytes);

      final prompt = '''
Tu es un médecin pneumologue expert en tuberculose et pneumonie.
Analyse cet enregistrement audio et réponds UNIQUEMENT avec du JSON valide (aucun texte autour).

$contextStr

TÂCHE :
1. Détecte si l'audio contient une toux réelle
2. Classifie acoustiquement la toux
3. Calcule les scores de risque TB et Pneumonie

JSON attendu :
{
  "hasCough": true,
  "coughType": "sèche",
  "intensity": "modérée",
  "coughCount": 3,
  "rhythm": "paroxystique",
  "tbScore": 20,
  "pneumoniaScore": 15,
  "mlConfidence": 0.85,
  "acousticNotes": "Toux sèche haute fréquence"
}''';

      final key = AppConstants.geminiApiKey;
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$key',
      );
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {'inline_data': {'mime_type': audioMime, 'data': audioB64}},
            ]
          }
        ],
        'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 512},
      });

      final resp = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 30));

      final text = resp.statusCode == 200
          ? (jsonDecode(resp.body)['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '')
          : '';

      // Extraire le JSON de la réponse
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}');
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        try {
          final result =
              jsonDecode(text.substring(jsonStart, jsonEnd + 1)) as Map<String, dynamic>;
          if (result.containsKey('tbScore') && result.containsKey('pneumoniaScore')) {
            print('[GeminiAudio] ✅ ML hasCough=${result['hasCough']}  TB=${result['tbScore']}  Pneumonie=${result['pneumoniaScore']}  Confiance=${result['mlConfidence']}');
            return result;
          }
        } on FormatException catch (e) {
          print('[GeminiAudio] JSON invalide: $e');
        }
      }
      return {};
    } catch (e) {
      print('[GeminiAudio] ⚠️ Analyse ML échouée: $e');
      return {};
    }
  }

  String _buildClinicalContextString(Map<String, dynamic>? ctx) {
    if (ctx == null || ctx.isEmpty) return '';
    final buf = StringBuffer('CONTEXTE CLINIQUE :\n');
    if (ctx['age'] != null) buf.writeln('- Âge : ${ctx['age']} ans');
    if (ctx['gender'] != null) buf.writeln('- Sexe : ${ctx['gender']}');
    if (ctx['spo2'] != null) buf.writeln('- SpO2 : ${ctx['spo2']}%');
    if (ctx['temperature'] != null) buf.writeln('- Température : ${ctx['temperature']}°C');
    if (ctx['heartRate'] != null) buf.writeln('- FC : ${ctx['heartRate']} bpm');
    if (ctx['symptomDurationDays'] != null && ctx['symptomDurationDays'] > 0)
      buf.writeln('- Toux depuis : ${ctx['symptomDurationDays']} jours');
    if (ctx['hasFever'] == true) buf.writeln('- Fièvre : OUI');
    if (ctx['hasNightSweats'] == true) buf.writeln('- Sueurs nocturnes : OUI');
    if (ctx['hasWeightLoss'] == true) buf.writeln('- Perte de poids inexpliquée : OUI');
    if (ctx['hasChestPain'] == true) buf.writeln('- Douleur thoracique : OUI');
    if (ctx['hasDyspnea'] == true) buf.writeln('- Essoufflement : OUI');
    if (ctx['tbContact'] == true) buf.writeln('- Contact TB connu : OUI (facteur de risque majeur)');
    if (ctx['isImmunocompromised'] == true) buf.writeln('- Immunodéprimé (VIH/chimio/corticoïdes) : OUI');
    if (ctx['medicalConditions'] != null) buf.writeln('- Antécédents : ${ctx['medicalConditions']}');
    return buf.toString();
  }

  String _formatLocalContext(Map<String, dynamic> ctx) {
    if (ctx.isEmpty) return '';
    final buf = StringBuffer();
    buf.writeln('📡 MESURES ESP32 RÉCENTES :');
    if (ctx['spo2'] != null) buf.writeln('  SpO2 : ${ctx['spo2']}%');
    if (ctx['temperature'] != null) buf.writeln('  Température : ${ctx['temperature']}°C');
    if (ctx['heartRate'] != null) buf.writeln('  Fréquence cardiaque : ${ctx['heartRate']} bpm');
    if (ctx['vitalsAge'] != null) buf.writeln('  (mesurées il y a ${ctx['vitalsAge']} minutes)');
    return buf.toString();
  }

  // ──────────────────────────────────────────────────────────────
  //  ANALYSE DES TENDANCES
  // ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> analyzeHealthTrends(String userId) async {
    try {
      final testsSnapshot = await _firestore
          .collection('tests')
          .where('userId', isEqualTo: userId)
          .orderBy('testDate', descending: true)
          .limit(20)
          .get();

      if (testsSnapshot.docs.isEmpty) {
        return {
          'status': 'no_data',
          'message': 'Aucun test disponible pour l\'analyse.',
        };
      }

      final tests = testsSnapshot.docs
          .map((doc) => TestResultModel.fromFirestore(doc))
          .toList();

      final analysis = await _callGemini(_buildAnalysisPrompt(tests));

      return {
        'status': 'success',
        'analysis': analysis,
        'testsAnalyzed': tests.length,
        'lastTestDate': tests.first.testDate.toIso8601String(),
      };
    } catch (e) {
      print('[GeminiAI] Erreur analyzeHealthTrends: $e');
      return {'status': 'error', 'message': 'Erreur lors de l\'analyse: $e'};
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  PRÉDICTION RISQUES FUTURS
  // ──────────────────────────────────────────────────────────────

  Future<String> predictFutureRisks(String userId) async {
    try {
      final testsSnapshot = await _firestore
          .collection('tests')
          .where('userId', isEqualTo: userId)
          .orderBy('testDate', descending: true)
          .limit(10)
          .get();

      if (testsSnapshot.docs.length < 3) {
        return 'Données insuffisantes pour une prédiction fiable. Continuez à effectuer des tests réguliers.';
      }

      final tests = testsSnapshot.docs
          .map((doc) => TestResultModel.fromFirestore(doc))
          .toList();

      final prompt = '''
Tu es un assistant médical IA spécialisé en santé respiratoire.

Analyse l'historique et PRÉDIS l'évolution probable sur 30 jours :

${_formatTestsForPrediction(tests)}

Fournis une prédiction structurée :
1. TENDANCE ACTUELLE : Amélioration, stabilité ou détérioration
2. RISQUES PRÉVUS dans les 30 prochains jours
3. RECOMMANDATIONS PRÉVENTIVES concrètes
4. URGENCE : faible, modéré ou élevé

Maximum 250 mots. Ton professionnel mais rassurant.
''';

      return await _callGemini(prompt);
    } catch (e) {
      print('[GeminiAI] Erreur predictFutureRisks: $e');
      return 'Impossible de générer une prédiction pour le moment.';
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  RECOMMANDATIONS PERSONNALISÉES
  // ──────────────────────────────────────────────────────────────

  Future<String> generatePersonalizedRecommendations(String userId) async {
    try {
      final lastTestSnapshot = await _firestore
          .collection('tests')
          .where('userId', isEqualTo: userId)
          .orderBy('testDate', descending: true)
          .limit(1)
          .get();

      if (lastTestSnapshot.docs.isEmpty) {
        return 'Effectuez votre premier test pour recevoir des recommandations personnalisées.';
      }

      final lastTest =
          TestResultModel.fromFirestore(lastTestSnapshot.docs.first);

      final prompt = '''
Tu es un assistant médical IA. Voici les résultats du dernier test respiratoire :

📊 DONNÉES :
- SpO2 : ${lastTest.spo2}%
- Fréquence cardiaque : ${lastTest.heartRate} bpm
- Température : ${lastTest.temperature}°C
- Niveau de risque : ${lastTest.riskLevel.toString().split('.').last}
- Date : ${lastTest.testDate.toString().split(' ')[0]}

Génère des RECOMMANDATIONS PERSONNALISÉES :
1. ACTIONS IMMÉDIATES si nécessaire
2. HABITUDES DE VIE adaptées
3. SUIVI MÉDICAL recommandé
4. SIGNAUX D'ALERTE (quand consulter)

Pratique, actionnable, rassurant. Maximum 200 mots.
''';

      return await _callGemini(prompt);
    } catch (e) {
      print('[GeminiAI] Erreur generatePersonalizedRecommendations: $e');
      return 'Impossible de générer des recommandations pour le moment.';
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  INTERPRÉTATION D'UN TEST
  // ──────────────────────────────────────────────────────────────

  Future<String> interpretTestResult(TestResultModel test) async {
    try {
      final prompt = '''
Tu es un médecin spécialiste en pneumologie. Analyse ce résultat :

📊 TEST DU ${test.testDate.toString().split(' ')[0]} :
- SpO2 : ${test.spo2}%
- Fréquence cardiaque : ${test.heartRate} bpm
- Température : ${test.temperature}°C
- Score de risque : ${test.riskScore}/100
- Niveau de risque : ${test.riskLevel.toString().split('.').last}

Fournis :
1. ÉVALUATION CLINIQUE (chaque paramètre normal ou non ?)
2. SIGNAUX D'ALERTE (valeurs préoccupantes ?)
3. RECOMMANDATIONS (actions immédiates + suivi)
4. ÉDUCATION PATIENT (signification des mesures)

Langage clair, rassurant. Maximum 300 mots.
''';

      return await _callGemini(prompt);
    } catch (e) {
      print('[GeminiAI] Erreur interpretTestResult: $e');
      return 'Impossible d\'interpréter ce test pour le moment.';
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  COMPARAISON DE DEUX TESTS
  // ──────────────────────────────────────────────────────────────

  Future<String> compareTests(
      TestResultModel oldTest, TestResultModel newTest) async {
    try {
      final daysBetween =
          newTest.testDate.difference(oldTest.testDate).inDays;

      final prompt = '''
Tu es un médecin analysant l'évolution respiratoire ($daysBetween jours d'écart).

TEST PRÉCÉDENT (${oldTest.testDate.toString().split(' ')[0]}) :
- SpO2 : ${oldTest.spo2}% | FC : ${oldTest.heartRate} bpm | Temp : ${oldTest.temperature}°C | Risque : ${oldTest.riskLevel.toString().split('.').last}

TEST RÉCENT (${newTest.testDate.toString().split(' ')[0]}) :
- SpO2 : ${newTest.spo2}% | FC : ${newTest.heartRate} bpm | Temp : ${newTest.temperature}°C | Risque : ${newTest.riskLevel.toString().split('.').last}

Analyse :
1. CHANGEMENTS OBSERVÉS (amélioration / stabilité / dégradation)
2. SIGNIFICATION CLINIQUE
3. INTERPRÉTATION globale
4. PROCHAINES ÉTAPES recommandées

Maximum 200 mots.
''';

      return await _callGemini(prompt);
    } catch (e) {
      print('[GeminiAI] Erreur compareTests: $e');
      return 'Impossible de comparer ces tests pour le moment.';
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  HELPERS PRIVÉS
  // ──────────────────────────────────────────────────────────────

  Future<String> _getUserHealthContext(String userId) async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(userId).get();
      final context = StringBuffer();

      if (userDoc.exists) {
        final d = userDoc.data()!;
        int? age;
        if (d['dateOfBirth'] != null) {
          try {
            final birth = DateTime.parse(d['dateOfBirth']);
            final now = DateTime.now();
            age = now.year - birth.year;
            if (now.month < birth.month ||
                (now.month == birth.month && now.day < birth.day)) age--;
          } catch (_) {}
        }

        context.writeln('👤 PROFIL PATIENT :');
        context.writeln('  Nom : ${d['firstName'] ?? ''} ${d['lastName'] ?? ''}');
        context.writeln('  Âge : ${age ?? 'Non renseigné'} ans');
        context.writeln('  Sexe : ${d['gender'] ?? 'Non renseigné'}');
        context.writeln('  Groupe sanguin : ${d['bloodType'] ?? 'Non renseigné'}');
        if (d['medicalConditions']?.isNotEmpty == true)
          context.writeln('  Conditions : ${d['medicalConditions']}');
        if (d['allergies']?.isNotEmpty == true)
          context.writeln('  Allergies : ${d['allergies']}');
        if (d['medications']?.isNotEmpty == true)
          context.writeln('  Médicaments : ${d['medications']}');
        context.writeln();
      }

      final testsSnap = await _firestore
          .collection('tests')
          .where('userId', isEqualTo: userId)
          .orderBy('testDate', descending: true)
          .limit(5)
          .get();

      if (testsSnap.docs.isEmpty) {
        context.writeln('📊 HISTORIQUE : Aucun test effectué.');
        return context.toString();
      }

      final tests = testsSnap.docs
          .map((doc) => TestResultModel.fromFirestore(doc))
          .toList();

      context.writeln('📊 DERNIERS TESTS (${tests.length}) :');
      for (var i = 0; i < tests.length; i++) {
        final t = tests[i];
        context.writeln(
            'Test ${i + 1} (${t.testDate.toString().split(' ')[0]}) : SpO2=${t.spo2}% | FC=${t.heartRate}bpm | T°=${t.temperature}°C | Risque=${t.riskLevel.toString().split('.').last}');
      }

      return context.toString();
    } catch (e) {
      print('[GeminiAI] Erreur _getUserHealthContext: $e');
      return '';
    }
  }

  String _buildIntelligentPrompt(
      String userMessage, String firestoreContext, String localContext,
      {List<Map<String, String>>? history}) {
    final historySection = StringBuffer();
    if (history != null && history.isNotEmpty) {
      historySection.writeln('HISTORIQUE DE CONVERSATION :');
      for (final msg in history) {
        final role = msg['role'] == 'user' ? 'Patient' : 'RespiraBox';
        historySection.writeln('$role: ${msg['text']}');
      }
      historySection.writeln();
    }

    return '''
Tu es un assistant médical IA RespiraBox, spécialisé en santé respiratoire (Tuberculose, Pneumonie).

$firestoreContext
$localContext
${historySection.toString()}
BASE MÉDICALE :
🔴 TUBERCULOSE : Toux >3 semaines, sueurs nocturnes, fièvre, perte de poids. Test GeneXpert.
🔵 PNEUMONIE : Toux + fièvre >38.5°C + SpO2 bas. SpO2 <90% = urgence.
⚠️ SpO2 <94% persistant = alerte. FC >100 bpm + SpO2 bas = détresse respiratoire.

QUESTION DU PATIENT : "$userMessage"

RÈGLES :
- Tiens compte de tout l'historique ci-dessus pour donner une réponse cohérente
- Maximum 5 phrases courtes et directes
- 2 émojis maximum
- Personnalise selon le profil patient
- Si SpO2 < 90% → ALERTE IMMÉDIATE, consultation urgente
- Si suspicion TB/Pneumonie → insiste sur consultation médicale URGENTE
- Réponds en français

RÉPONSE :
''';
  }

  String _buildAnalysisPrompt(List<TestResultModel> tests) {
    final buf = StringBuffer();
    buf.writeln('Tu es un analyste médical IA. Analyse ces ${tests.length} tests respiratoires :\n');
    for (var i = 0; i < tests.length; i++) {
      final t = tests[i];
      buf.writeln('Test ${i + 1} (${t.testDate.toString().split(' ')[0]}) : SpO2=${t.spo2}% | FC=${t.heartRate}bpm | T°=${t.temperature}°C | Risque=${t.riskLevel.toString().split('.').last}');
    }
    buf.writeln('''
\nFournis une ANALYSE STRUCTURÉE :
1. ÉVOLUTION GLOBALE (amélioration / stable / dégradation)
2. ANOMALIES DÉTECTÉES
3. INDICATEURS CLÉS
4. RECOMMANDATIONS
5. NIVEAU D'URGENCE

Maximum 250 mots.''');
    return buf.toString();
  }

  String _formatTestsForPrediction(List<TestResultModel> tests) {
    final buf = StringBuffer();
    for (var i = 0; i < tests.length; i++) {
      final t = tests[i];
      final daysAgo = DateTime.now().difference(t.testDate).inDays;
      buf.writeln('Test ${i + 1} (il y a $daysAgo jours) : SpO2=${t.spo2}% | FC=${t.heartRate}bpm | T°=${t.temperature}°C | Risque=${t.riskLevel.toString().split('.').last}');
    }
    return buf.toString();
  }
}
