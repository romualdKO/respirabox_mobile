# 🔥 CONFIGURATION FIREBASE RESPIRABOX

## ✅ ÉTAPE 1: BASE DE DONNÉES CONNECTÉE

Firebase est maintenant connecté à l'application RespiraBox!

**Services créés:**
- ✅ `TestService` - Gestion des tests respiratoires
- ✅ `NotificationService` - Gestion des notifications + FCM
- ✅ `StorageService` - Upload/download fichiers
- ✅ `AuthService` - Authentification (remplace MockAuthService)

---

## 📊 ÉTAPE 2: RÈGLES FIRESTORE À CONFIGURER

### 🔐 Aller sur Firebase Console
1. Ouvrir: https://console.firebase.google.com
2. Sélectionner le projet: **respirabox-production**
3. Aller dans **Firestore Database** > **Règles**

### 📝 Copier-coller ces règles:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ===== FONCTIONS HELPER =====
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // ===== USERS: Profils utilisateurs =====
    match /users/{userId} {
      // Lecture: seulement son propre profil
      allow read: if isOwner(userId);
      
      // Création: n'importe quel utilisateur authentifié peut créer son profil
      allow create: if isAuthenticated() && request.auth.uid == userId;
      
      // Mise à jour: seulement son propre profil
      allow update: if isOwner(userId);
      
      // Suppression: interdite (désactivation via admin uniquement)
      allow delete: if false;
    }
    
    // ===== TESTS: Résultats tests respiratoires =====
    match /tests/{testId} {
      // Lecture: seulement ses propres tests
      allow read: if isAuthenticated() && 
                     resource.data.userId == request.auth.uid;
      
      // Création: test doit appartenir à l'utilisateur
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
      
      // Mise à jour: seulement ses propres tests
      allow update: if isAuthenticated() && 
                       resource.data.userId == request.auth.uid;
      
      // Suppression: seulement ses propres tests
      allow delete: if isAuthenticated() && 
                       resource.data.userId == request.auth.uid;
    }
    
    // ===== NOTIFICATIONS: Notifications utilisateur =====
    match /notifications/{notificationId} {
      // Lecture: seulement ses propres notifications
      allow read: if isAuthenticated() && 
                     resource.data.userId == request.auth.uid;
      
      // Création: backend uniquement (Cloud Functions)
      allow create: if false;
      
      // Mise à jour: seulement pour marquer comme lu
      allow update: if isAuthenticated() && 
                       resource.data.userId == request.auth.uid &&
                       request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead']);
      
      // Suppression: ses propres notifications
      allow delete: if isAuthenticated() && 
                       resource.data.userId == request.auth.uid;
    }
    
    // ===== DEVICES: Appareils RespiraBox =====
    match /devices/{deviceId} {
      // Lecture: tous les utilisateurs authentifiés
      allow read: if isAuthenticated();
      
      // Écriture: backend uniquement
      allow write: if false;
    }
    
    // ===== CHAT_SESSIONS: Historique chatbot =====
    match /chat_sessions/{sessionId} {
      // Lecture: seulement ses propres sessions
      allow read: if isAuthenticated() && 
                     resource.data.userId == request.auth.uid;
      
      // Création: session doit appartenir à l'utilisateur
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
      
      // Mise à jour: seulement ses propres sessions
      allow update: if isAuthenticated() && 
                       resource.data.userId == request.auth.uid;
      
      // Suppression: seulement ses propres sessions
      allow delete: if isAuthenticated() && 
                       resource.data.userId == request.auth.uid;
    }
    
    // ===== APP_CONFIG: Configuration application =====
    match /app_config/{configId} {
      // Lecture: tous (pour version minimale, maintenance mode)
      allow read: if true;
      
      // Écriture: backend uniquement
      allow write: if false;
    }
  }
}
```

### ⚠️ IMPORTANT
Après avoir collé les règles, cliquer sur **Publier** pour les activer.

---

## 🗄️ ÉTAPE 3: RÈGLES FIREBASE STORAGE

### 📂 Aller dans Storage
1. Firebase Console > **Storage** > **Règles**

### 📝 Copier-coller ces règles:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // ===== PHOTOS DE PROFIL =====
    match /users/{userId}/profile/{fileName} {
      // Lecture: publique (pour afficher les photos)
      allow read: if true;
      
      // Écriture: seulement son propre dossier
      allow write: if request.auth != null && 
                      request.auth.uid == userId &&
                      request.resource.size < 5 * 1024 * 1024 && // Max 5MB
                      request.resource.contentType.matches('image/.*');
    }
    
    // ===== FICHIERS DE TESTS (PDF, Audio) =====
    match /tests/{userId}/{testId}/{fileName} {
      // Lecture: seulement ses propres fichiers
      allow read: if request.auth != null && 
                     request.auth.uid == userId;
      
      // Écriture: seulement dans son propre dossier
      allow write: if request.auth != null && 
                      request.auth.uid == userId &&
                      request.resource.size < 20 * 1024 * 1024; // Max 20MB
    }
  }
}
```

Cliquer sur **Publier**.

---

## 🔑 ÉTAPE 4: ACTIVER AUTHENTICATION

### 📧 Email/Password
1. Firebase Console > **Authentication** > **Sign-in method**
2. Cliquer sur **Email/Password**
3. **Activer** le fournisseur
4. Cliquer sur **Enregistrer**

### 🔵 Google Sign-In
1. Dans **Sign-in method**, cliquer sur **Google**
2. **Activer** le fournisseur
3. Choisir un email d'assistance: `contact@respirabox.ci`
4. Cliquer sur **Enregistrer**

---

## 📱 ÉTAPE 5: CRÉER LES COLLECTIONS FIRESTORE

### 🏗️ Structure à créer dans Firestore:

Aller dans **Firestore Database** > **Données**

#### 1️⃣ Collection `users`
- Cliquer sur **Démarrer la collection**
- ID de collection: `users`
- Créer un document de test (sera remplacé lors de la première inscription):
  ```
  ID du document: test_user
  Champs:
  - email: "test@respirabox.ci" (string)
  - firstName: "Test" (string)
  - lastName: "User" (string)
  - role: "patient" (string)
  - isActive: true (boolean)
  - createdAt: [timestamp actuel]
  ```

#### 2️⃣ Collection `tests`
- Créer la collection: `tests`
- Créer un document de test:
  ```
  ID du document: test_test
  Champs:
  - userId: "test_user" (string)
  - testDate: [timestamp actuel]
  - score: 75 (number)
  - riskLevel: "low" (string)
  ```

#### 3️⃣ Collection `notifications`
- Créer la collection: `notifications`
- Document de test:
  ```
  ID: test_notif
  Champs:
  - userId: "test_user" (string)
  - type: "info" (string)
  - title: "Bienvenue!" (string)
  - message: "Bienvenue sur RespiraBox" (string)
  - isRead: false (boolean)
  - createdAt: [timestamp actuel]
  ```

#### 4️⃣ Collection `devices`
- Créer la collection: `devices`
- Document de test:
  ```
  ID: device001
  Champs:
  - serialNumber: "RB-2024-001" (string)
  - model: "RespiraBox Pro" (string)
  - status: "active" (string)
  ```

---

## 🔔 ÉTAPE 6: ACTIVER CLOUD MESSAGING (FCM)

### 📲 Configuration Android
1. Firebase Console > **Cloud Messaging**
2. Vérifier que le fichier `google-services.json` est dans `android/app/`
3. Server Key sera utilisé pour envoyer des notifications push

### 🍎 Configuration iOS (À faire plus tard)
1. Télécharger `GoogleService-Info.plist`
2. Placer dans `ios/Runner/`
3. Configurer les certificats APN

---

## ✅ ÉTAPE 7: INDEX FIRESTORE COMPOSITES

Certaines requêtes nécessitent des index. Firebase vous alertera automatiquement.

### 📊 Index à créer manuellement:

1. **Index pour tests par utilisateur et date:**
   - Collection: `tests`
   - Champs: `userId` (Croissant) + `testDate` (Décroissant)

2. **Index pour notifications non lues:**
   - Collection: `notifications`
   - Champs: `userId` (Croissant) + `isRead` (Croissant) + `createdAt` (Décroissant)

---

## 🚀 ÉTAPE 8: TESTER L'APPLICATION

### ✅ Vérifications:
1. ✅ Firebase initialisé dans `main.dart`
2. ✅ Packages Firebase installés
3. ✅ Services créés (TestService, NotificationService, StorageService, AuthService)
4. ✅ MockAuthService remplacé par AuthService
5. ⏳ Règles Firestore configurées
6. ⏳ Règles Storage configurées
7. ⏳ Authentication activée (Email + Google)
8. ⏳ Collections créées

### 🧪 Test de connexion:
```bash
flutter run
```

Essayer de créer un compte utilisateur. Si tout est configuré, les données apparaîtront dans Firestore!

---

## 🔮 ÉTAPES SUIVANTES (Optionnel)

### 📈 Analytics
1. Firebase Console > **Analytics**
2. Activer Google Analytics
3. Ajouter `firebase_analytics` dans pubspec.yaml

### 📊 Crashlytics
1. Firebase Console > **Crashlytics**
2. Ajouter `firebase_crashlytics` dans pubspec.yaml
3. Capturer les erreurs automatiquement

### ⚡ Performance Monitoring
1. Firebase Console > **Performance**
2. Ajouter `firebase_performance` dans pubspec.yaml
3. Monitorer les performances de l'app

---

## 📞 SUPPORT

En cas de problème:
1. Vérifier les logs Flutter: `flutter logs`
2. Vérifier la console Firebase
3. Vérifier que les règles sont bien publiées
4. Vérifier que Authentication est activé

**Projet Firebase:** respirabox-production  
**Project ID:** respirabox-production

---

## ✨ RÉCAPITULATIF

**Backend connecté:** ✅  
**Services créés:** ✅  
**MockAuth remplacé:** ✅  
**Règles Firestore:** ⏳ À configurer  
**Règles Storage:** ⏳ À configurer  
**Authentication:** ⏳ À activer  
**Collections:** ⏳ À créer

**Prochaine étape:** Configurer les règles dans Firebase Console puis tester l'inscription!
