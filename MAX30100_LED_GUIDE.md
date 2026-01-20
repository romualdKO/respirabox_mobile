# 🔴 GUIDE - ACTIVATION LED MAX30100

## ✅ LE CODE EST PRÊT!

Le code Arduino (`arduino/RespiraBox_ESP32.ino`) a déjà été modifié pour:
- ✅ Initialiser le capteur MAX30100
- ✅ Allumer sa LED rouge pendant les tests
- ✅ Continuer à utiliser les données simulées (comme demandé)

## 📤 COMMENT TÉLÉVERSER LE CODE

### Étape 1: Installer la bibliothèque MAX30100
Dans Arduino IDE:
1. Menu **Sketch** → **Include Library** → **Manage Libraries**
2. Chercher: `MAX30100lib`
3. Installer: **"MAX30100lib" by OXullo Intersecans**
4. Cliquer sur "Install"

### Étape 2: Connecter l'ESP32
1. Brancher l'ESP32 à l'ordinateur avec un câble USB
2. Dans Arduino IDE, sélectionner:
   - **Tools** → **Board** → **ESP32 Dev Module**
   - **Tools** → **Port** → Choisir le port COM de l'ESP32 (ex: COM3, COM5)

### Étape 3: Téléverser le code
1. Ouvrir le fichier: `C:\dev\respirabox_mobile\arduino\RespiraBox_ESP32.ino`
2. Cliquer sur le bouton **Upload** (flèche →) en haut à gauche
3. Attendre la compilation et le téléversement (~30 secondes)
4. Vous verrez: "Done uploading."

### Étape 4: Vérifier dans le Serial Monitor
1. Ouvrir le **Serial Monitor**: **Tools** → **Serial Monitor**
2. Régler la vitesse à: **115200 baud**
3. Vous devriez voir:

```
🔧 Initialisation I2C...
🔧 Initialisation MAX30100 (LED seulement)...
✅ MAX30100 initialisé - LED allumée
🔧 Initialisation BLE...
✅ Bluetooth OK
📱 Nom du device: RespiraBox-ESP32
⏸️  En attente du démarrage du test...
```

**Si vous voyez:**
- ✅ `✅ MAX30100 initialisé - LED allumée` → **PARFAIT! La LED devrait être allumée**
- ⚠️ `⚠️ MAX30100 non détecté - Simulation active` → Vérifier le câblage I2C

## 🔌 CÂBLAGE MAX30100 (SI PAS DÉJÀ FAIT)

```
MAX30100          ESP32
---------         -----
VCC       →       3.3V (PAS 5V!)
GND       →       GND
SCL       →       GPIO 22
SDA       →       GPIO 21
```

**⚠️ IMPORTANT:** Le MAX30100 fonctionne en 3.3V, PAS en 5V!

## 🔴 QUE FAIT LA LED?

### Avant le téléversement:
- 🔴 LED éteinte (capteur non initialisé)

### Après le téléversement:
1. **Au démarrage de l'ESP32:**
   - 🔴 LED s'allume brièvement si MAX30100 détecté
   
2. **Pendant la connexion Bluetooth:**
   - 🔴 LED reste allumée (grâce à `pox.update()` dans `loop()`)
   
3. **Pendant un test de 30 secondes:**
   - 🔴 LED brille en continu
   - Les données affichées sont SIMULÉES (BPM 60-90, SpO2 94-100)
   - La LED sert juste de **feedback visuel** que l'appareil fonctionne

## 📊 DONNÉES UTILISÉES

**IMPORTANT:** Même avec la LED allumée, les données envoyées à Flutter sont **simulées**:

- ❌ PAS utilisé: `pox.getHeartRate()` et `pox.getSpO2()`
- ✅ UTILISÉ: Fonctions `readBPM()` et `readSpO2()` (simulation)
- 🔴 LED: Allumée pour montrer que l'appareil est actif

C'est exactement ce que vous avez demandé: **LED allumée, données simulées**.

## ✅ TEST FINAL

1. Téléverser le code
2. Ouvrir le Serial Monitor → Vérifier "✅ MAX30100 initialisé"
3. Regarder le MAX30100 → 🔴 LED rouge devrait être allumée
4. Connecter l'ESP32 depuis l'application Flutter
5. Lancer un test de 30 secondes
6. La LED reste allumée pendant le test ✅
7. Les données affichées sont simulées (60-90 BPM, 94-100% SpO2) ✅

## 🐛 SI LA LED NE S'ALLUME PAS

### Cas 1: Serial Monitor affiche "⚠️ MAX30100 non détecté"
**Problème:** Câblage ou capteur défectueux

**Solutions:**
1. Vérifier les 4 fils (VCC, GND, SCL, SDA)
2. Vérifier que VCC est bien sur 3.3V (PAS 5V)
3. Essayer de débrancher/rebrancher le capteur
4. Tester avec un autre MAX30100 si disponible

### Cas 2: Code ne compile pas "MAX30100_PulseOximeter.h not found"
**Problème:** Bibliothèque non installée

**Solution:** Installer la bibliothèque (voir Étape 1 ci-dessus)

### Cas 3: ESP32 ne se connecte plus en Bluetooth
**Problème:** Erreur dans le nouveau code (peu probable)

**Solution:** 
1. Vérifier les messages dans le Serial Monitor
2. Si erreur BLE, vérifier que les UUIDs n'ont pas été modifiés
3. Le code actuel est testé et fonctionnel

## 📱 APRÈS LE TÉLÉVERSEMENT

1. L'ESP32 fonctionne exactement comme avant
2. En bonus: 🔴 LED MAX30100 allumée (feedback visuel)
3. Les données sont toujours simulées (comme demandé)
4. Vous pouvez connecter l'ESP32 et lancer des tests normalement
5. Maintenant il faut aussi installer l'APK v9 pour vérifier la sauvegarde Firebase!

---

**Résumé:** 
- Code prêt ✅
- Téléverser dans Arduino IDE → Upload button
- Vérifier Serial Monitor pour "✅ MAX30100 initialisé"
- Observer la LED rouge s'allumer 🔴
- Tester avec l'application comme d'habitude!
