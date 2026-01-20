# 🔥 GUIDE DÉBOGAGE FIREBASE - HISTORIQUE DES TESTS

## ⚠️ PROBLÈME IDENTIFIÉ
Les tests ne s'enregistrent pas dans l'historique Firebase.

## 📋 VÉRIFICATIONS À FAIRE

### 1️⃣ VÉRIFIER QUE VOUS ÊTES CONNECTÉ
Après avoir installé le nouvel APK (v9), lancer l'application:

**Scénario A - Vous voyez l'écran de connexion:**
- ✅ Connectez-vous avec votre compte
- ✅ Ou créez un nouveau compte si vous n'en avez pas

**Scénario B - Vous êtes déjà dans l'app:**
- Allez dans le menu profil/paramètres
- Vérifiez que votre email est affiché
- Si "Utilisateur non connecté" → Déconnectez-vous et reconnectez-vous

### 2️⃣ TESTER LA SAUVEGARDE
1. Connectez l'ESP32
2. Lancez un test de 30 secondes
3. **IMPORTANT:** À la fin du test, regardez les notifications en bas de l'écran:
   
   - ✅ **Message vert:** "✅ Test sauvegardé dans l'historique" → **Ça marche!**
   - ⚠️ **Message orange:** "⚠️ Utilisateur non connecté - Test non sauvegardé" → **Vous devez vous connecter**
   - ❌ **Message rouge:** "❌ Erreur de sauvegarde: ..." → **Problème Firebase**

### 3️⃣ SI LE MESSAGE EST VERT MAIS HISTORIQUE VIDE
Le problème vient de l'écran historique, pas de la sauvegarde.

**Solution:** Vérifier que l'écran historique lit depuis la bonne collection.
Chemin Firebase: `users/{userId}/tests` ou `tests/`?

### 4️⃣ SI VOUS VOYEZ LE MESSAGE ORANGE (PAS CONNECTÉ)
**Solution:** Se connecter ou créer un compte

1. Dans l'app, aller à l'écran de connexion
2. Créer un compte avec:
   - Email: votre@email.com
   - Mot de passe: au moins 6 caractères
   - Nom, prénom, téléphone
3. Après création, vous êtes automatiquement connecté
4. Refaire un test → devrait afficher le message vert

### 5️⃣ SI VOUS VOYEZ LE MESSAGE ROUGE (ERREUR)
**Causes possibles:**
- Pas de connexion Internet
- Règles Firestore bloquent l'écriture
- Service Firebase mal configuré

**Solution:** 
1. Vérifier que le téléphone a Internet (WiFi ou données mobiles)
2. Vérifier les règles Firestore (console Firebase)

## 🔧 RÈGLES FIRESTORE À VÉRIFIER

Aller sur: https://console.firebase.google.com
→ Votre projet → Firestore Database → Rules

Les règles doivent permettre l'écriture pour les utilisateurs connectés:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Collection des tests
    match /tests/{testId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Collection des utilisateurs
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

**Si les règles sont différentes:** Copiez ces règles et publiez-les.

## 📱 APK V9 - CHANGEMENTS
- Ajout de notifications visuelles (snackbar) après chaque test
- Message vert si sauvegarde réussie
- Message orange si utilisateur non connecté
- Message rouge si erreur de sauvegarde
- Les logs console affichent toujours les détails techniques

## 🐛 LOGS CONSOLE (SI BESOIN)
Si vous voulez voir les logs détaillés:

```bash
flutter run --release -d 112177046S009285
```

Cherchez dans les logs:
- `🔍 Récupération de l'utilisateur...`
- `❌ Aucun utilisateur connecté!` → Vous devez vous connecter
- `✅ Utilisateur trouvé: [ID]` → Authentification OK
- `💾 Tentative de sauvegarde dans Firebase...`
- `✅ Test sauvegardé dans Firebase!` → Sauvegarde réussie
- `❌ Erreur sauvegarde Firebase:` → Voir le message d'erreur

## ✅ TEST RAPIDE
1. Installer APK v9
2. **SE CONNECTER** (si pas déjà fait)
3. Connecter ESP32
4. Lancer test 30 secondes
5. **REGARDER LA NOTIFICATION EN BAS** à la fin du test
6. Si vert ✅ → Aller dans l'historique, le test doit apparaître
7. Si orange ⚠️ → Se connecter d'abord
8. Si rouge ❌ → Vérifier Internet + règles Firestore

## 📞 PROCHAINES ÉTAPES SI ÇA NE MARCHE PAS
1. Faire un screenshot de la notification qui apparaît
2. Si pas de notification → Problème dans le code
3. Si notification orange → Créer/connecter un compte
4. Si notification rouge → Partager le message d'erreur complet
