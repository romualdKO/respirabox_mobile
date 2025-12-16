# 🫁 RespiraBox Mobile

Application mobile Flutter pour le dépistage des maladies respiratoires en Côte d'Ivoire.

## 📱 Description

RespiraBox est une solution innovante de télémédecine qui permet le dépistage précoce des maladies respiratoires via un boîtier connecté. L'application mobile permet aux utilisateurs de:

- 🔍 Effectuer des tests respiratoires avec le boîtier RespiraBox
- 📊 Visualiser leurs résultats et historique de tests
- 💬 Obtenir une assistance médicale via un chatbot IA
- 👤 Gérer leur profil et paramètres

## 🚀 Prérequis

- Flutter SDK 3.35.1 ou supérieur
- Dart 3.0 ou supérieur
- Android Studio / VS Code
- Android SDK (pour Android)
- Xcode (pour iOS, sur macOS uniquement)

## 📦 Installation

1. **Cloner le dépôt**
```bash
git clone https://github.com/VOTRE_USERNAME/respirabox_mobile.git
cd respirabox_mobile
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Configurer Firebase** (Quand vous serez prêts à activer le backend)
- Créer un projet Firebase sur [console.firebase.google.com](https://console.firebase.google.com)
- Télécharger `google-services.json` pour Android et le placer dans `android/app/`
- Télécharger `GoogleService-Info.plist` pour iOS et le placer dans `ios/Runner/`
- Décommenter les imports Firebase dans `lib/main.dart` et `pubspec.yaml`

4. **Lancer l'application**
```bash
flutter run
```

## 🏗️ Architecture

```
lib/
├── main.dart                 # Point d'entrée de l'application
├── core/                     # Configurations et constantes
│   ├── constants/
│   │   ├── colors.dart      # Palette de couleurs
│   │   └── text_styles.dart # Styles de texte
├── data/                     # Couche de données
│   ├── models/              # Modèles de données
│   └── services/            # Services (Auth, API, etc.)
│       └── mock_auth_service.dart
├── presentation/             # Interface utilisateur
│   └── screens/
│       ├── auth/            # Écrans d'authentification
│       ├── home/            # Écran d'accueil
│       ├── test/            # Écrans de test respiratoire
│       ├── history/         # Historique des tests
│       ├── profile/         # Profil utilisateur
│       ├── device/          # Connexion boîtier
│       └── chatbot/         # Assistance IA
└── routes/                   # Gestion de la navigation
    └── app_routes.dart
```

## 🎨 Fonctionnalités

### ✅ Complétées (Frontend Mock)
- Authentication (Inscription, Connexion, Mot de passe oublié)
- Écran d'accueil avec statistiques
- Scanner de dispositifs Bluetooth
- Test respiratoire complet (30 secondes avec animation)
- Résultats détaillés avec score de risque
- Historique avec filtres et statistiques
- Profil utilisateur avec paramètres
- Chatbot IA avec réponses médicales

### 🔄 En cours
- Intégration Firebase (Auth, Firestore, Storage)
- Intégration Gemini AI pour le chatbot
- Connexion Bluetooth réelle avec le boîtier
- Export PDF des résultats

### 📋 Prévues
- Notifications push
- Mode hors ligne
- Recherche de professionnels de santé
- Entrée vocale pour le chatbot
- Graphiques avancés avec fl_chart

## 🔧 Packages Utilisés

- `flutter_riverpod`: Gestion d'état
- `google_fonts`: Polices personnalisées
- `flutter_svg`: Images SVG
- `lottie`: Animations
- `fl_chart`: Graphiques
- `flutter_blue_plus`: Bluetooth
- `google_generative_ai`: IA Gemini
- `firebase_core`, `firebase_auth`, `cloud_firestore`: Backend Firebase

## 👥 Contribution

1. Forker le projet
2. Créer une branche pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`)
3. Commiter vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Pousser vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 🔐 Sécurité

⚠️ **Important**: Ne jamais commiter les fichiers suivants:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `android/local.properties`
- Clés API ou tokens d'accès

Ces fichiers sont déjà exclus dans `.gitignore`.

## 📝 État du Projet

**Version actuelle**: 1.0.0-dev
**Statut**: En développement actif (Frontend Mock complet)
**Prochaine étape**: Intégration Firebase Backend

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier LICENSE pour plus de détails.

## 📧 Contact

Pour toute question ou suggestion, contactez l'équipe RespiraBox.

---

Fait avec ❤️ pour la santé respiratoire en Côte d'Ivoire
