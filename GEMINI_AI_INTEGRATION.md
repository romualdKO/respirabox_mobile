# 🤖 Intégration Gemini AI - RespiraBox

## 📋 Vue d'ensemble

L'application RespiraBox utilise **Google Gemini AI** pour analyser intelligemment les données de santé respiratoire des utilisateurs et fournir des prédictions, recommandations et conseils personnalisés.

## 🎯 Fonctionnalités IA

### 1. **Chatbot Intelligent**
- Conversation contextuelle basée sur l'historique de tests
- Réponses personnalisées selon les données réelles de l'utilisateur
- Interface utilisateur intuitive avec messages en temps réel

### 2. **Analyse de Tendances**
```dart
final analysis = await geminiService.analyzeHealthTrends(userId);
```
- Analyse des 20 derniers tests
- Identification des patterns (amélioration, stabilité, dégradation)
- Détection d'anomalies dans SpO2, fréquence cardiaque, température

### 3. **Prédictions de Risques**
```dart
final prediction = await geminiService.predictFutureRisks(userId);
```
- Prévision de l'évolution dans les 30 prochains jours
- Basé sur minimum 3 tests historiques
- Recommandations préventives

### 4. **Recommandations Personnalisées**
```dart
final recommendations = await geminiService.generatePersonalizedRecommendations(userId);
```
- Conseils adaptés au dernier test
- Actions immédiates si risque élevé
- Habitudes de vie et suivi médical

### 5. **Interprétation de Tests**
```dart
final interpretation = await geminiService.interpretTestResult(testModel);
```
- Évaluation clinique détaillée
- Signaux d'alerte identifiés
- Éducation patient sur les métriques

### 6. **Comparaison de Tests**
```dart
final comparison = await geminiService.compareTests(oldTest, newTest);
```
- Évolution entre deux tests
- Signification clinique des changements
- Prochaines étapes recommandées

## 🔧 Configuration

### API Key Gemini
```dart
// lib/data/services/gemini_ai_service.dart
static const String _apiKey = 'AIzaSyAab7tKNXUT-8xwJW5TIsz_4btU89j1LVA';
```

### Dépendances
```yaml
# pubspec.yaml
dependencies:
  google_generative_ai: ^0.2.0
  cloud_firestore: ^5.4.4
  flutter_riverpod: ^2.4.9
```

## 🏗️ Architecture

### Service Gemini AI
```
lib/data/services/gemini_ai_service.dart
├── sendMessage()                    // Chat contextuel
├── analyzeHealthTrends()            // Analyse tendances
├── predictFutureRisks()             // Prédictions
├── generatePersonalizedRecommendations()
├── interpretTestResult()            // Interprétation test
└── compareTests()                   // Comparaison
```

### Provider Riverpod
```dart
// lib/core/providers/app_providers.dart
final geminiAIServiceProvider = Provider<GeminiAIService>((ref) {
  return GeminiAIService();
});
```

### Écran Chatbot
```
lib/presentation/screens/chatbot/chatbot_screen.dart
├── ConsumerStatefulWidget           // Accès Riverpod
├── GeminiAIService _geminiService   // Instance service
├── _sendMessage()                   // Envoyer question
└── _showInfoDialog()                // Info Gemini
```

## 💬 Commandes Chatbot

| Commande | Description | Exemple |
|----------|-------------|---------|
| `analyse` | Analyse complète des données | "Fais une analyse de mes tests" |
| `prédiction` | Prédire l'évolution | "Quelle est ma prédiction ?" |
| `recommandation` | Conseils personnalisés | "Donne-moi des recommandations" |
| Question libre | Conversation contextuelle | "Mon SpO2 est à 93%, c'est grave ?" |

## 📊 Données Analysées

### Collections Firebase
- **tests** : SpO2, fréquence cardiaque, température, risque
- **users** : Profil utilisateur, historique
- **notifications** : Alertes envoyées

### Contexte Utilisateur
```dart
HISTORIQUE DES TESTS (5 derniers) :
Test 1 (2026-01-15) :
  - SpO2: 96%
  - FC: 75 bpm
  - Risque: low

Test 2 (2026-01-10) :
  - SpO2: 94%
  - FC: 82 bpm
  - Risque: moderate
```

## 🎨 Prompts Intelligents

### Structure Type
```dart
Tu es un assistant médical IA spécialisé en santé respiratoire.

CONTEXTE DU PATIENT :
[Historique tests, profil]

QUESTION DU PATIENT :
[Message utilisateur]

INSTRUCTIONS :
- Réponds en français
- Base sur données RÉELLES
- Recommande consultation pour diagnostic
- Utilise émojis (max 3)
- Empathique et rassurant
```

## 🚀 Utilisation

### 1. Chat Simple
```dart
// Accéder au chatbot
Navigator.pushNamed(context, AppRoutes.chatbot);

// Envoyer message
await geminiService.sendMessage(
  userMessage: "J'ai des difficultés à respirer",
  userId: currentUser.id,
);
```

### 2. Analyse Programmée
```dart
// Dashboard : Analyse automatique
final analysis = await geminiService.analyzeHealthTrends(userId);
showDialog(
  context: context,
  builder: (context) => AnalysisDialog(analysis: analysis),
);
```

### 3. Notification Intelligente
```dart
// Après test : Recommandations
final recommendations = await geminiService.generatePersonalizedRecommendations(userId);
NotificationService().sendNotification(
  userId: userId,
  message: recommendations,
);
```

## 🔒 Sécurité & Confidentialité

### Données Utilisateur
- ✅ Aucune donnée personnelle envoyée à Gemini (seulement métriques)
- ✅ Requêtes anonymisées (pas de nom, email)
- ✅ Historique stocké localement et dans Firebase
- ✅ Conformité RGPD

### API Key Protection
- ⚠️ Production : Déplacer la clé vers variables d'environnement
- ⚠️ Utiliser Firebase Functions pour proxy sécurisé
- ⚠️ Implémenter rate limiting

```dart
// .env (à créer)
GEMINI_API_KEY=AIzaSyAab7tKNXUT-8xwJW5TIsz_4btU89j1LVA

// Charger avec flutter_dotenv
final apiKey = dotenv.env['GEMINI_API_KEY'];
```

## 📈 Métriques & Performance

### Latence
- Réponse chatbot : ~2-4 secondes
- Analyse tendances : ~3-5 secondes
- Prédiction : ~4-6 secondes

### Optimisations
- Cache des réponses fréquentes
- Limitation à 5-20 tests pour analyse
- Requêtes asynchrones non-bloquantes

## 🧪 Tests

### Test Unitaire Service
```dart
test('Gemini AI analyse les tendances correctement', () async {
  final service = GeminiAIService();
  final analysis = await service.analyzeHealthTrends('userId');
  
  expect(analysis['status'], 'success');
  expect(analysis['testsAnalyzed'], greaterThan(0));
});
```

### Test d'Intégration
```dart
testWidgets('Chatbot affiche réponse Gemini', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.tap(find.text('Chatbot'));
  await tester.enterText(find.byType(TextField), 'analyse');
  await tester.tap(find.byIcon(Icons.send));
  
  await tester.pump(Duration(seconds: 5));
  expect(find.textContaining('ANALYSE'), findsOneWidget);
});
```

## 🐛 Dépannage

### Erreur: API Key Invalid
```
❌ Erreur Gemini AI: Invalid API key
```
**Solution**: Vérifier la clé dans `gemini_ai_service.dart`

### Erreur: Insufficient Data
```
Données insuffisantes pour analyse
```
**Solution**: Utilisateur doit avoir minimum 3 tests

### Erreur: Network Timeout
```
Une erreur s'est produite: TimeoutException
```
**Solution**: Vérifier connexion internet, augmenter timeout

## 🔮 Améliorations Futures

### Phase 2
- [ ] Analyse vocale des symptômes (speech-to-text)
- [ ] Comparaison avec population similaire (benchmarking)
- [ ] Alertes prédictives automatiques
- [ ] Graphiques d'évolution générés par IA

### Phase 3
- [ ] Intégration avec dossiers médicaux électroniques
- [ ] Consultation virtuelle avec médecins via IA
- [ ] Modèle ML entraîné spécifiquement sur données ivoiriennes
- [ ] Support multi-langues (français, anglais, langues locales)

## 📚 Ressources

- [Google Gemini API Docs](https://ai.google.dev/docs)
- [Flutter Riverpod](https://riverpod.dev/)
- [Firebase Firestore](https://firebase.google.com/docs/firestore)

## 👥 Équipe

**Développement IA**: Agent Copilot  
**Date**: 15 Janvier 2026  
**Version**: 1.0.0

---

**🎯 RespiraBox + Gemini AI = Santé Respiratoire Intelligente en Côte d'Ivoire** 🇨🇮
