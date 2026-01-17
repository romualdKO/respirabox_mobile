import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/test_result_model.dart';

/// 🤖 SERVICE IA COHERE
/// Analyse les données de tests et fournit des prédictions/recommandations intelligentes
class GeminiAIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 🔑 Clé API Cohere : https://dashboard.cohere.com/api-keys
  static const String _apiKey = 'zFG0EfXmnaaOxAkC98GMiJWjue3u8n4J1It1biFj';
  static const String _apiUrl = 'https://api.cohere.ai/v1/chat';

  GeminiAIService() {
    print('✅ Cohere AI initialisé avec succès');
  }

  /// 🌐 APPEL À L'API COHERE
  /// Méthode helper pour envoyer des prompts à Cohere
  Future<String> _callCohereAPI(String prompt) async {
    try {
      // Essayer différents modèles disponibles
      final models = ['command-light', 'command-nightly', 'command-light-nightly'];
      
      for (final model in models) {
        try {
          final response = await http.post(
            Uri.parse(_apiUrl),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'message': prompt,
              'temperature': 0.7,
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            print('✅ Modèle fonctionnel: $model');
            return (data['text'] as String).trim();
          }
        } catch (e) {
          print('⏭️ Modèle $model non disponible, essai suivant...');
          continue;
        }
      }
      
      return '🤖 Aucun modèle Cohere disponible. Veuillez vérifier votre clé API ou réessayer plus tard.';
    } catch (e) {
      print('❌ Erreur appel Cohere: $e');
      return 'Erreur de connexion à l\'IA.';
    }
  }

  /// 💬 ENVOYER UN MESSAGE AU CHATBOT
  /// Analyse le contexte utilisateur et répond intelligemment à TOUT
  Future<String> sendMessage({
    required String userMessage,
    required String userId,
  }) async {
    try {
      // Récupérer le contexte utilisateur (derniers tests + profil)
      final userContext = await _getUserHealthContext(userId);
      
      // Détecter automatiquement l'intention et agir
      final prompt = _buildIntelligentPrompt(userMessage, userContext);
      
      print('🔍 Envoi à Cohere API...');
      print('📝 Prompt length: ${prompt.length} caractères');
      
      // Utiliser la méthode helper qui teste plusieurs modèles
      return await _callCohereAPI(prompt);
    } catch (e, stackTrace) {
      print('❌ Erreur Cohere AI: $e');
      print('📍 Stack trace: $stackTrace');
      
      return 'Une erreur s\'est produite. Veuillez réessayer.';
    }
  }

  /// 📊 ANALYSER LES TENDANCES DE SANTÉ
  /// Analyse tous les tests d'un utilisateur et prédit les risques futurs
  Future<Map<String, dynamic>> analyzeHealthTrends(String userId) async {
    try {
      // Récupérer tous les tests de l'utilisateur
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

      // Construire le prompt d'analyse
      final analysisPrompt = _buildAnalysisPrompt(tests);

      // Demander l'analyse à Gemini
      final response = await _callCohereAPI(analysisPrompt);

      return {
        'status': 'success',
        'analysis': 'Analyse non disponible',
        'testsAnalyzed': tests.length,
        'lastTestDate': tests.first.testDate.toIso8601String(),
      };
    } catch (e) {
      print('❌ Erreur analyse tendances: $e');
      return {
        'status': 'error',
        'message': 'Erreur lors de l\'analyse: $e',
      };
    }
  }

  /// 🔮 PRÉDIRE LES RISQUES FUTURS
  /// Utilise l'historique pour prédire l'évolution de la santé respiratoire
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

      final predictionPrompt = '''
Tu es un assistant médical IA spécialisé en santé respiratoire.

Analyse l'historique de tests suivant et PRÉDIS l'évolution probable de la santé respiratoire de ce patient :

${_formatTestsForPrediction(tests)}

Fournis une prédiction structurée :
1. TENDANCE ACTUELLE : Amélioration, stabilité ou détérioration
2. RISQUES PRÉVUS : Dans les 30 prochains jours
3. RECOMMANDATIONS PRÉVENTIVES : Actions concrètes
4. URGENCE : Niveau de priorité (faible, modéré, élevé)

Sois précis, basé sur les données, et utilise un ton professionnel mais rassurant.
''';

      final response = await _callCohereAPI(predictionPrompt);

      return 'Prédiction non disponible';
    } catch (e) {
      print('❌ Erreur prédiction: $e');
      return 'Impossible de générer une prédiction pour le moment.';
    }
  }

  /// 💊 RECOMMANDATIONS PERSONNALISÉES
  /// Génère des conseils basés sur le dernier test
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

      final lastTest = TestResultModel.fromFirestore(lastTestSnapshot.docs.first);

      final recommendationPrompt = '''
Tu es un assistant médical IA. Voici les résultats du dernier test respiratoire d'un patient :

📊 DONNÉES DU TEST :
- SpO2 : ${lastTest.spo2}%
- Fréquence cardiaque : ${lastTest.heartRate} bpm
- Température : ${lastTest.temperature}°C
- Niveau de risque : ${lastTest.riskLevel.toString().split('.').last}
- Date du test : ${lastTest.testDate.toString().split(' ')[0]}

Génère des RECOMMANDATIONS PERSONNALISÉES :
1. 🎯 ACTIONS IMMÉDIATES (si nécessaire)
2. 🏃 HABITUDES DE VIE (exercice, hydratation, etc.)
3. 🩺 SUIVI MÉDICAL (fréquence des tests, consultation)
4. ⚠️ SIGNAUX D'ALERTE (quand consulter en urgence)

Sois pratique, actionnable et rassurant. Maximum 200 mots.
''';

      final response = await _callCohereAPI(recommendationPrompt);

      return 'Recommandations non disponibles';
    } catch (e) {
      print('❌ Erreur recommandations: $e');
      return 'Impossible de générer des recommandations pour le moment.';
    }
  }

  /// 🔍 RÉCUPÉRER LE CONTEXTE SANTÉ DE L'UTILISATEUR
  Future<String> _getUserHealthContext(String userId) async {
    try {
      // 1️⃣ RÉCUPÉRER LE PROFIL UTILISATEUR COMPLET
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      final context = StringBuffer();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        
        // Calculer l'âge à partir de dateOfBirth
        int? age;
        if (userData['dateOfBirth'] != null) {
          try {
            final birthDate = DateTime.parse(userData['dateOfBirth']);
            final now = DateTime.now();
            age = now.year - birthDate.year;
            if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
              age--;
            }
          } catch (e) {
            age = null;
          }
        }
        
        context.writeln('👤 PROFIL DU PATIENT :');
        context.writeln('  Nom: ${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}');
        context.writeln('  Email: ${userData['email'] ?? 'Non renseigné'}');
        context.writeln('  Téléphone: ${userData['phoneNumber'] ?? 'Non renseigné'}');
        context.writeln('  Âge: ${age ?? 'Non renseigné'} ans');
        context.writeln('  Sexe: ${userData['gender'] ?? 'Non renseigné'}');
        context.writeln('  Groupe sanguin: ${userData['bloodType'] ?? 'Non renseigné'}');
        context.writeln('  Taille: ${userData['height'] ?? 'Non renseigné'} cm');
        context.writeln('  Poids: ${userData['weight'] ?? 'Non renseigné'} kg');
        
        if (userData['medicalConditions'] != null && userData['medicalConditions'] != '') {
          context.writeln('  ⚠️ Conditions médicales: ${userData['medicalConditions']}');
        }
        
        if (userData['allergies'] != null && userData['allergies'] != '') {
          context.writeln('  🚨 Allergies: ${userData['allergies']}');
        }
        
        if (userData['medications'] != null && userData['medications'] != '') {
          context.writeln('  💊 Médicaments: ${userData['medications']}');
        }
        
        if (userData['emergencyContact'] != null && userData['emergencyContact'] != '') {
          context.writeln('  📞 Contact urgence: ${userData['emergencyContact']}');
        }
        
        context.writeln('');
      }
      
      // 2️⃣ RÉCUPÉRER L'HISTORIQUE DES TESTS
      final testsSnapshot = await _firestore
          .collection('tests')
          .where('userId', isEqualTo: userId)
          .orderBy('testDate', descending: true)
          .limit(5)
          .get();

      if (testsSnapshot.docs.isEmpty) {
        context.writeln('📊 HISTORIQUE DES TESTS : Aucun test effectué pour le moment.');
        return context.toString();
      }

      final tests = testsSnapshot.docs
          .map((doc) => TestResultModel.fromFirestore(doc))
          .toList();

      context.writeln('📊 HISTORIQUE DES TESTS (${tests.length} derniers) :');
      
      for (var i = 0; i < tests.length; i++) {
        final test = tests[i];
        context.writeln('Test ${i + 1} (${test.testDate.toString().split(' ')[0]}) :');
        context.writeln('  - SpO2: ${test.spo2}%');
        context.writeln('  - FC: ${test.heartRate} bpm');
        context.writeln('  - Température: ${test.temperature}°C');
        context.writeln('  - Risque: ${test.riskLevel.toString().split('.').last}');
      }

      return context.toString();
    } catch (e) {
      print('❌ Erreur récupération contexte utilisateur: $e');
      return 'Erreur de récupération du contexte utilisateur.';
    }
  }

  /// 📝 CONSTRUIRE LE PROMPT INTELLIGENT
  /// L'IA détecte automatiquement l'intention et agit en conséquence
  String _buildIntelligentPrompt(String userMessage, String userContext) {
    return '''
Tu es un assistant médical IA spécialisé en santé respiratoire RespiraBox avec expertise en Tuberculose et Pneumonie.

DONNÉES PATIENT :
$userContext

QUESTION :
"$userMessage"

BASE DE CONNAISSANCES MÉDICALES (MALADIES RESPIRATOIRES) :

🔴 TUBERCULOSE (TB) :
- Agent : Mycobacterium tuberculosis
- Symptômes clés : Toux persistante >3 semaines avec expectorations, sueurs nocturnes, fièvre, perte de poids, hémoptysie
- SpO2 : Peut diminuer en phase avancée (<92% = sévère)
- Diagnostic : Test GeneXpert, radiographie pulmonaire, culture des crachats
- Traitement : 6 mois d'antibiotiques (Rifampicine, Isoniazide, Pyrazinamide, Ethambutol)
- Contagiosité : Élevée via gouttelettes aériennes

🔵 PNEUMONIE :
- Agent : Streptococcus pneumoniae (bactérie), virus influenza, COVID-19
- Symptômes clés : Toux avec glaires jaunes/vertes, fièvre >38.5°C, douleur thoracique, dyspnée
- SpO2 : Indicateur critique (<93% = oxygénothérapie nécessaire, <90% = urgence)
- Diagnostic : Radiographie thoracique, analyse sanguine (leucocytes élevés)
- Traitement : Antibiotiques si bactérienne, antiviraux si virale
- Complications : Pleurésie, septicémie si non traitée

🎯 INDICATEURS RESPIRABOX POUR DÉTECTION :
- SpO2 <94% persistant = Signal d'alerte respiratoire
- Toux + Fièvre >38°C + SpO2 <93% = SUSPICION PNEUMONIE → Consultation urgente
- Toux >3 semaines + Perte poids + Sueurs nocturnes = SUSPICION TB → Test GeneXpert
- FC >100 bpm au repos + SpO2 bas = Détresse respiratoire

RÈGLES STRICTES :
- Maximum 4-5 phrases courtes et directes
- Réponds UNIQUEMENT à ce qui est demandé
- 2 émojis maximum
- Personnalise selon âge/sexe/conditions
- Listes à puces si > 2 points
- Alerte IMMÉDIATE si SpO2 < 90%
- Si suspicion TB/Pneumonie → INSISTER sur consultation médicale URGENTE

CAPACITÉS INTELLIGENTES :
Tu dois COMPRENDRE L'INTENTION de l'utilisateur et agir automatiquement :

1. Si demande d'ANALYSE/TENDANCES :
   - Analyse l'historique complet des tests
   - Identifie les patterns (amélioration, stabilité, dégradation)
   - Détecte les anomalies dans SpO2, FC, température
   - Donne un résumé structuré avec tendances
   - PRENDS EN COMPTE le profil (âge, sexe, conditions médicales)

2. Si demande de PRÉDICTION/FUTUR :
   - Prévois l'évolution probable sur 30 jours
   - Base-toi sur les tendances observées
   - Identifie les risques potentiels
   - Recommande des actions préventives
   - CONSIDÈRE les conditions médicales existantes

3. Si demande de RECOMMANDATIONS/CONSEILS :
   - Donne des conseils personnalisés selon le dernier test
   - Actions immédiates si risque élevé
   - Habitudes de vie adaptées à l'ÂGE et SEXE
   - Fréquence de suivi recommandée
   - TIENS COMPTE des allergies et médicaments

4. Si QUESTION GÉNÉRALE de santé :
   - Réponds avec les connaissances médicales
   - Contextualise avec les données du patient si pertinent
   - Éduque sur les métriques respiratoires
   - PERSONNALISE selon le profil (âge, conditions)

5. Si INTERPRÉTATION de résultats :
   - Explique la signification clinique
   - Compare avec les normes pour l'ÂGE et SEXE
   - Identifie les signaux d'alerte
   - Recommande la suite
   - ALERTE si conflit avec conditions médicales

6. Si COMPARAISON demandée :
   - Compare le dernier test avec le précédent
   - Explique l'évolution
   - Donne la signification clinique

7. Si ANALYSE DE TOUX ou SUSPICION MALADIE :
   - Utilise la BASE DE CONNAISSANCES MÉDICALES ci-dessus
   - Croise les données (SpO2, température, fréquence cardiaque, durée toux)
   - Identifie les SIGNES CLINIQUES de TB ou Pneumonie
   - Si concordance avec TB : Toux >3 semaines + symptômes → "Suspicion de tuberculose, test GeneXpert recommandé"
   - Si concordance avec Pneumonie : Toux + Fièvre + SpO2 bas → "Suspicion de pneumonie, consultation urgente nécessaire"
   - Donne recommandations PRÉCISES basées sur la pathologie suspectée
   - TOUJOURS recommander confirmation par professionnel de santé

INSTRUCTIONS CRITIQUES :
- Détecte AUTOMATIQUEMENT l'intention sans que l'utilisateur utilise des mots-clés précis
- Réponds en français de manière claire et professionnelle
- Base TOUJOURS tes réponses sur les DONNÉES RÉELLES du patient (profil + tests)
- PERSONNALISE selon l'âge, sexe, conditions médicales, allergies, médicaments
- Utilise des émojis pertinents (maximum 3)
- Sois empathique, rassurant et actionnable
- Si urgence (SpO2 < 90%, douleur thoracique), insiste sur consultation IMMÉDIATE
- Si conditions médicales préexistantes, adapte tes conseils en conséquence
- Recommande TOUJOURS une consultation médicale pour diagnostic précis

RÉPONSE CONCISE INTELLIGENTE :
''';
  }

  /// 📊 CONSTRUIRE LE PROMPT D'ANALYSE
  String _buildAnalysisPrompt(List<TestResultModel> tests) {
    final buffer = StringBuffer();
    buffer.writeln('Tu es un analyste médical IA spécialisé en santé respiratoire.');
    buffer.writeln('\nAnalyse les ${tests.length} tests suivants et identifie les TENDANCES CRITIQUES :\n');

    for (var i = 0; i < tests.length; i++) {
      final test = tests[i];
      buffer.writeln('TEST ${i + 1} (${test.testDate.toString().split(' ')[0]}) :');
      buffer.writeln('  SpO2: ${test.spo2}%');
      buffer.writeln('  FC: ${test.heartRate} bpm');
      buffer.writeln('  Température: ${test.temperature}°C');
      buffer.writeln('  Risque: ${test.riskLevel.toString().split('.').last}');
      buffer.writeln();
    }

    buffer.writeln('''
Fournis une ANALYSE STRUCTURÉE :
1. 📈 ÉVOLUTION GLOBALE (amélioration, stable, dégradation)
2. ⚠️ ANOMALIES DÉTECTÉES (variations anormales)
3. 🎯 INDICATEURS CLÉS (SpO2, FC, température)
4. 💡 RECOMMANDATIONS (actions à prendre)
5. 🚨 NIVEAU D'URGENCE (faible, modéré, élevé)

Maximum 250 mots. Sois précis et actionnable.
''');

    return buffer.toString();
  }

  /// 📋 FORMATER LES TESTS POUR PRÉDICTION
  String _formatTestsForPrediction(List<TestResultModel> tests) {
    final buffer = StringBuffer();
    
    for (var i = 0; i < tests.length; i++) {
      final test = tests[i];
      final daysAgo = DateTime.now().difference(test.testDate).inDays;
      
      buffer.writeln('Test ${i + 1} (il y a $daysAgo jours) :');
      buffer.writeln('  - SpO2: ${test.spo2}%');
      buffer.writeln('  - Fréquence cardiaque: ${test.heartRate} bpm');
      buffer.writeln('  - Température: ${test.temperature}°C');
      buffer.writeln('  - Niveau de risque: ${test.riskLevel.toString().split('.').last}');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// 🧠 DIAGNOSTIC INTELLIGENT D'UN TEST
  /// Analyse un test spécifique et fournit une interprétation détaillée
  Future<String> interpretTestResult(TestResultModel test) async {
    try {
      final interpretationPrompt = '''
Tu es un médecin spécialiste en pneumologie. Analyse ce résultat de test respiratoire :

📊 RÉSULTATS DU TEST :
- Date : ${test.testDate.toString().split(' ')[0]}
- SpO2 (Saturation en oxygène) : ${test.spo2}%
- Fréquence cardiaque : ${test.heartRate} bpm
- Température corporelle : ${test.temperature}°C
- Score de risque : ${test.riskScore}/100
- Niveau de risque : ${test.riskLevel.toString().split('.').last}

Fournis une INTERPRÉTATION MÉDICALE complète :

1. 🩺 ÉVALUATION CLINIQUE
   - Chaque paramètre est-il dans la norme ?
   - Signification clinique de chaque valeur

2. ⚠️ SIGNAUX D'ALERTE
   - Y a-t-il des valeurs préoccupantes ?
   - Niveau d'urgence (aucun, faible, modéré, élevé)

3. 💊 RECOMMANDATIONS
   - Actions immédiates si nécessaires
   - Suivi recommandé
   - Quand consulter un médecin

4. 📚 ÉDUCATION PATIENT
   - Qu'est-ce que signifie SpO2 ?
   - Pourquoi ces mesures sont importantes ?

Utilise un langage clair, accessible, et rassurant. Maximum 300 mots.
''';

      return await _callCohereAPI(interpretationPrompt);
    } catch (e) {
      print('❌ Erreur interprétation test: $e');
      return 'Impossible d\'interpréter ce test pour le moment.';
    }
  }

  /// 🔬 COMPARER DEUX TESTS
  /// Compare le dernier test avec un précédent pour identifier l'évolution
  Future<String> compareTests(TestResultModel oldTest, TestResultModel newTest) async {
    try {
      final daysBetween = newTest.testDate.difference(oldTest.testDate).inDays;
      
      final comparisonPrompt = '''
Tu es un médecin analysant l'évolution de la santé respiratoire d'un patient.

📊 COMPARAISON DE TESTS (${daysBetween} jours d'écart) :

TEST PRÉCÉDENT (${oldTest.testDate.toString().split(' ')[0]}) :
- SpO2 : ${oldTest.spo2}%
- FC : ${oldTest.heartRate} bpm
- Température : ${oldTest.temperature}°C
- Risque : ${oldTest.riskLevel.toString().split('.').last}

TEST RÉCENT (${newTest.testDate.toString().split(' ')[0]}) :
- SpO2 : ${newTest.spo2}%
- FC : ${newTest.heartRate} bpm
- Température : ${newTest.temperature}°C
- Risque : ${newTest.riskLevel.toString().split('.').last}

Analyse l'ÉVOLUTION :

1. 📈 CHANGEMENTS OBSERVÉS
   - Amélioration, stabilité ou dégradation ?
   - Variations significatives de chaque paramètre

2. 🎯 SIGNIFICATION CLINIQUE
   - Ces changements sont-ils normaux ?
   - Niveau de préoccupation

3. 💡 INTERPRÉTATION
   - Qu'est-ce que cela indique sur l'état de santé ?
   - Tendance générale

4. 🚀 PROCHAINES ÉTAPES
   - Continuer le suivi actuel ou intensifier ?
   - Recommandations spécifiques

Sois précis et actionnable. Maximum 200 mots.
''';

      return await _callCohereAPI(comparisonPrompt);
    } catch (e) {
      print('❌ Erreur comparaison tests: $e');
      return 'Impossible de comparer ces tests pour le moment.';
    }
  }
}
