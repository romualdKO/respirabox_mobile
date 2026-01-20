# 📦 RESPIRABOX v9 - NOTIFICATIONS FIREBASE

## ✅ FICHIERS PRÊTS

### 1️⃣ APK v9 (Application Flutter)
**📍 Emplacement:** `C:\Users\HP\Downloads\RespiraBox_v9_Firebase_Notifications.apk`
**📏 Taille:** 54.6 MB

**🆕 Nouveautés v9:**
- ✅ Notifications visibles après chaque test (en bas de l'écran)
- ✅ Message vert si sauvegarde réussie: "✅ Test sauvegardé dans l'historique"
- ⚠️ Message orange si utilisateur non connecté: "⚠️ Utilisateur non connecté - Test non sauvegardé"
- ❌ Message rouge si erreur Firebase: "❌ Erreur de sauvegarde: [détails]"
- 📊 Conservation de toutes les fonctionnalités v8 (connexion auto-détection BLE)

### 2️⃣ Code Arduino ESP32
**📍 Emplacement:** `C:\dev\respirabox_mobile\arduino\RespiraBox_ESP32.ino`

**🆕 Modifications MAX30100:**
- ✅ Inclusion de la bibliothèque MAX30100_PulseOximeter
- ✅ Initialisation du capteur dans `setup()` avec `pox.begin()`
- ✅ Mise à jour continue dans `loop()` avec `pox.update()`
- 🔴 LED rouge s'allume pour feedback visuel
- 📊 Les données restent SIMULÉES (comme demandé)

## 🚀 ÉTAPES D'INSTALLATION

### ÉTAPE 1: Installer l'APK v9 sur le téléphone

1. **Transférer l'APK:**
   - Copier `RespiraBox_v9_Firebase_Notifications.apk` vers le téléphone
   - Ou utiliser: `adb install C:\Users\HP\Downloads\RespiraBox_v9_Firebase_Notifications.apk`

2. **Installer:**
   - Ouvrir le fichier APK sur le téléphone
   - Accepter l'installation
   - Si demandé, autoriser l'installation depuis cette source

3. **Désinstaller l'ancienne version (si besoin):**
   - Sinon, la nouvelle version écrasera l'ancienne

### ÉTAPE 2: Téléverser le code Arduino (MAX30100 LED)

1. **Installer la bibliothèque MAX30100:**
   - Arduino IDE → Sketch → Include Library → Manage Libraries
   - Chercher: `MAX30100lib`
   - Installer: **MAX30100lib by OXullo Intersecans**

2. **Connecter l'ESP32:**
   - Brancher l'ESP32 en USB
   - Tools → Board → ESP32 Dev Module
   - Tools → Port → Sélectionner le port COM de l'ESP32

3. **Ouvrir et téléverser:**
   - Ouvrir: `C:\dev\respirabox_mobile\arduino\RespiraBox_ESP32.ino`
   - Cliquer sur Upload (→)
   - Attendre "Done uploading."

4. **Vérifier dans Serial Monitor (115200 baud):**
   ```
   ✅ MAX30100 initialisé - LED allumée
   ✅ Bluetooth OK
   📱 Nom du device: RespiraBox-ESP32
   ```

5. **Vérifier visuellement:**
   - 🔴 La LED rouge du MAX30100 doit être allumée

## 🧪 TEST COMPLET

### Test 1: Vérifier l'authentification

1. Ouvrir l'application RespiraBox v9
2. **Vérifier si vous êtes connecté:**
   - Si écran de connexion → **Créer un compte ou se connecter**
   - Si écran principal → Aller dans Profil pour vérifier votre email

**⚠️ CRITIQUE:** Sans authentification, les tests ne seront PAS sauvegardés!

### Test 2: Tester la sauvegarde Firebase

1. **Se connecter** (si pas déjà fait)
2. Scanner et connecter l'ESP32 "RespiraBox-ESP32"
3. Lancer un test de 30 secondes
4. **REGARDER EN BAS DE L'ÉCRAN à la fin du test:**

**Vous devez voir UN de ces messages:**

✅ **Message VERT:** "✅ Test sauvegardé dans l'historique"
→ **PARFAIT!** Le test est dans Firebase

⚠️ **Message ORANGE:** "⚠️ Utilisateur non connecté - Test non sauvegardé"
→ **PROBLÈME:** Vous devez vous connecter d'abord

❌ **Message ROUGE:** "❌ Erreur de sauvegarde: [erreur]"
→ **PROBLÈME:** Firebase, réseau, ou règles Firestore

### Test 3: Vérifier l'historique

1. Après un test avec **message vert ✅**
2. Aller dans l'onglet **Historique**
3. Le test doit apparaître avec:
   - Date et heure
   - SpO2, BPM, Température
   - Score de risque

**Si l'historique est vide mais message vert:**
→ Problème avec la requête Firestore (rare)

### Test 4: Vérifier la LED MAX30100

1. Observer le capteur MAX30100 physique
2. Après avoir téléversé le nouveau code Arduino
3. 🔴 La LED rouge doit être **allumée en continu**
4. Pendant un test, elle reste allumée
5. Les données affichées sont toujours **simulées** (BPM 60-90, SpO2 94-100)

## 🐛 DIAGNOSTIC DES PROBLÈMES

### Problème A: Message orange "Utilisateur non connecté"

**Solution:**
1. Dans l'app, aller à l'écran de connexion
2. Créer un nouveau compte:
   - Email valide
   - Mot de passe (6+ caractères)
   - Nom, prénom, téléphone
3. Après création → Automatiquement connecté
4. Refaire un test → Devrait afficher message vert ✅

### Problème B: Message rouge "Erreur de sauvegarde"

**Causes possibles:**
1. **Pas d'Internet** → Activer WiFi ou données mobiles
2. **Règles Firestore** → Vérifier dans Firebase Console
3. **Service Firebase** → Vérifier google-services.json

**Vérifier les règles Firestore:**
1. Aller sur: https://console.firebase.google.com
2. Sélectionner votre projet
3. Firestore Database → Rules
4. Les règles doivent permettre l'écriture:
   ```javascript
   match /tests/{testId} {
     allow create: if request.auth != null;
     allow read: if request.auth != null;
   }
   ```

### Problème C: Pas de message du tout

**Cause:** Code pas correctement intégré (très rare, le build devrait avoir échoué)

**Solution:** Vérifier les logs console si possible

### Problème D: LED MAX30100 ne s'allume pas

**Causes:**
1. **Bibliothèque non installée** → Installer MAX30100lib dans Arduino IDE
2. **Câblage incorrect:**
   ```
   MAX30100 → ESP32
   VCC → 3.3V (PAS 5V!)
   GND → GND
   SCL → GPIO 22
   SDA → GPIO 21
   ```
3. **Capteur défectueux** → Tester avec un autre

**Vérification:**
- Ouvrir Serial Monitor (115200 baud)
- Si "✅ MAX30100 initialisé" → Câblage OK
- Si "⚠️ MAX30100 non détecté" → Vérifier câbles

## 📊 CODES D'ÉTAT

### États de connexion (v8 et v9)
- ✅ Connexion ESP32 réussie
- ✅ Envoi START/STOP fonctionnel
- ✅ Réception données temps réel (1 Hz)
- ✅ Test de 30 secondes avec countdown

### États de sauvegarde (NOUVEAU v9)
- 🟢 **VERT** = Sauvegarde réussie → Test dans Firebase
- 🟠 **ORANGE** = Pas connecté → Se connecter d'abord
- 🔴 **ROUGE** = Erreur technique → Vérifier Internet/Firebase

### États MAX30100 (NOUVEAU Arduino)
- 🔴 **LED allumée** = Capteur initialisé et actif
- ⚪ **LED éteinte** = Capteur non détecté (vérifier câblage)
- 📊 **Données** = Toujours simulées (indépendant de la LED)

## 📝 LOGS CONSOLE (MODE DEBUG)

Si vous voulez voir les logs détaillés en temps réel:

```bash
# Connecter le téléphone en USB avec ADB activé
adb devices

# Voir les logs Flutter
flutter run --release -d [DEVICE_ID]
```

**Logs à chercher:**
- `🔍 Récupération de l'utilisateur...`
- `❌ Aucun utilisateur connecté!` → Pas authentifié
- `✅ Utilisateur trouvé: [ID]` → Authentifié ✅
- `💾 Tentative de sauvegarde dans Firebase...`
- `✅ Test sauvegardé dans Firebase!` → Sauvegarde OK
- `   ID du test: [ID]` → ID du document Firestore

## ✅ CHECKLIST FINALE

**Avant de tester:**
- [ ] APK v9 installé sur le téléphone
- [ ] Code Arduino téléversé avec bibliothèque MAX30100
- [ ] ESP32 connecté et Serial Monitor affiche "✅ MAX30100 initialisé"
- [ ] LED MAX30100 allumée (rouge) 🔴
- [ ] Utilisateur **connecté** dans l'application

**Pendant le test:**
- [ ] Connexion ESP32 réussie
- [ ] Données temps réel affichées (BPM, SpO2)
- [ ] Countdown de 30 secondes fonctionne
- [ ] LED MAX30100 reste allumée pendant le test

**Après le test:**
- [ ] **MESSAGE AFFICHÉ** en bas de l'écran (vert/orange/rouge)
- [ ] Si vert ✅ → Test dans l'onglet Historique
- [ ] Si orange ⚠️ → Se connecter et refaire
- [ ] Si rouge ❌ → Vérifier Internet + Firebase

## 🎯 OBJECTIFS ATTEINTS

### ✅ Connexion BLE (v8)
- Auto-détection des caractéristiques
- Plus d'erreur "Service non trouvé"
- Connexion stable ESP32 ↔ Flutter

### ✅ LED MAX30100 (Nouveau)
- LED rouge allumée pendant les tests
- Feedback visuel que l'appareil est actif
- Données toujours simulées (comme demandé)

### 🔧 Sauvegarde Firebase (v9 - À tester)
- Notifications visibles pour diagnostic
- Détection si utilisateur non connecté
- Messages d'erreur clairs
- Tests enregistrés dans collection `tests/`

## 📞 PROCHAINES ÉTAPES

1. **Installer les 2 fichiers:**
   - APK v9 sur téléphone
   - Code Arduino sur ESP32

2. **Se connecter dans l'app** (si pas déjà fait)

3. **Faire un test complet:**
   - Connecter ESP32
   - Lancer test 30 secondes
   - **Noter le message affiché** (vert/orange/rouge)

4. **Vérifier l'historique:**
   - Si message vert → Test doit apparaître
   - Si historique vide → Partager le message exact

5. **Vérifier la LED:**
   - 🔴 LED MAX30100 allumée = OK
   - ⚪ LED éteinte = Vérifier câblage

6. **Reporter les résultats:**
   - Quel message s'affiche après le test?
   - Le test apparaît-il dans l'historique?
   - La LED est-elle allumée?

---

**Fichiers de référence:**
- 📄 Guide détaillé Firebase: `TESTS_FIREBASE_DEBUG.md`
- 📄 Guide détaillé MAX30100: `MAX30100_LED_GUIDE.md`
- 📦 APK v9: `C:\Users\HP\Downloads\RespiraBox_v9_Firebase_Notifications.apk`
- 🔧 Arduino: `C:\dev\respirabox_mobile\arduino\RespiraBox_ESP32.ino`
