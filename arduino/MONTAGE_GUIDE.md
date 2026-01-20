# 🫁 RespiraBox - Guide de Montage ESP32

## 📦 **Composants nécessaires**

| Composant | Quantité | Prix estimé (CFA) |
|-----------|----------|-------------------|
| ESP32 DevKit | 1 | 3000-5000 |
| MAX30100 (SpO2/FC) | 1 | 2000-3000 |
| LM35DZ (Température) | 1 | 500-1000 |
| Résistances 4.7kΩ | 2 | 100 |
| Breadboard | 1 | 500 |
| Fils Dupont | 10-15 | 500 |
| Câble micro-USB | 1 | 300 |
| **TOTAL** | | **~7000 CFA** |

---

## 🔌 **Schéma de câblage**

```
ESP32 DevKit (30 pins)
┌─────────────────────────────────┐
│                                 │
│  3V3 ●────────┬─────────● VIN   │  MAX30100
│               │         ● GND   │  (Module I2C)
│  GND ●────────┼────────┬● SCL   │
│               │        │        │
│  D21 ●────────┼────────┘        │
│  (SDA)        │                 │
│               │                 │
│  D22 ●────────┘                 │
│  (SCL)                          │
│                                 │
│  D34 ●──────────────● OUT       │  LM35DZ
│  (ADC)              ● VCC───┐   │  (Température)
│                     ● GND   │   │
│  3V3 ●──────────────────────┘   │
│                                 │
│  GND ●──────────────────────────┤
│                                 │
└─────────────────────────────────┘

Résistances pull-up I2C:
  3.3V ────┬──── [4.7kΩ] ──── SDA (D21)
           │
           └──── [4.7kΩ] ──── SCL (D22)
```

---

## 🛠️ **Instructions de montage**

### **Étape 1: Connexions MAX30100**

| MAX30100 Pin | ESP32 Pin | Couleur fil suggérée |
|--------------|-----------|---------------------|
| VIN | 3.3V | Rouge |
| GND | GND | Noir |
| SCL | GPIO 22 | Jaune |
| SDA | GPIO 21 | Bleu |

⚠️ **IMPORTANT**: 
- Utiliser **3.3V** (PAS 5V, sinon destruction du MAX30100)
- Ajouter résistances pull-up 4.7kΩ sur SDA/SCL

### **Étape 2: Connexions LM35DZ**

| LM35DZ Pin | ESP32 Pin | Couleur fil |
|------------|-----------|-------------|
| VCC (gauche) | 3.3V | Rouge |
| OUT (milieu) | GPIO 34 | Orange |
| GND (droite) | GND | Noir |

📝 **Note**: Regarder le LM35 face plate, pins vers le bas:
```
   ┌─────┐
   │ ●●● │
   └─────┘
    │ │ │
    │ │ └─── GND
    │ └───── OUT (Signal)
    └─────── VCC (+)
```

### **Étape 3: Résistances pull-up I2C**

```
3.3V ──┬── [R1: 4.7kΩ] ──┬── SDA (D21)
       │                  │
       └── [R2: 4.7kΩ] ──┴── SCL (D22)
```

---

## 💻 **Installation du code**

### **1. Installer Arduino IDE**
- Télécharger: https://www.arduino.cc/en/software
- Version recommandée: 2.x

### **2. Configurer ESP32 dans Arduino IDE**

**a) Ajouter l'URL du gestionnaire de cartes:**
```
Fichier → Préférences → URLs de gestionnaire de cartes supplémentaires
```
Ajouter:
```
https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
```

**b) Installer la carte ESP32:**
```
Outils → Type de carte → Gestionnaire de cartes
Rechercher "ESP32" → Installer "esp32 by Espressif Systems"
```

**c) Sélectionner la carte:**
```
Outils → Type de carte → ESP32 Arduino → ESP32 Dev Module
```

### **3. Installer les bibliothèques**

```
Croquis → Inclure une bibliothèque → Gérer les bibliothèques
```

Installer:
- **MAX30100lib** by OXullo Intersecans (v1.2.1+)
- **Wire** (incluse par défaut)

### **4. Téléverser le code**

1. Connecter l'ESP32 via USB
2. Sélectionner le port: `Outils → Port → COM[X]`
3. Cliquer sur **Téléverser** (flèche →)

---

## 🧪 **Test du prototype**

### **1. Moniteur série**

```
Outils → Moniteur série (Ctrl+Maj+M)
Vitesse: 115200 baud
```

Vous devriez voir:
```
🫁 RespiraBox ESP32 - Démarrage...
🔍 Initialisation MAX30100... ✅ OK
✅ LM35 configuré
📶 Initialisation Bluetooth... ✅ OK
🚀 RespiraBox prêt! En attente de connexion...
```

### **2. Tester MAX30100**

- Placer votre doigt sur le capteur MAX30100
- LED rouge doit s'allumer
- Attendre 5-10 secondes pour stabilisation
- Voir les mesures:

```
┌─────────────────────────────┐
│  📊 MESURES RESPIRABOX     │
├─────────────────────────────┤
│  💓 FC:   75 bpm           │
│  🩸 SpO2: 98 %             │
│  🌡️  Temp: 36.8 °C         │
└─────────────────────────────┘
```

### **3. Connecter via Bluetooth**

**Sur l'application Flutter:**
1. Ouvrir RespiraBox Mobile
2. Aller dans **Scanner**
3. Chercher "RespiraBox-ESP32"
4. Connecter
5. Les données apparaissent en temps réel

---

## 🔧 **Dépannage**

### ❌ **MAX30100 non détecté**

**Symptôme:**
```
🔍 Initialisation MAX30100... ❌ ÉCHEC!
```

**Solutions:**
1. Vérifier câblage I2C (SDA=21, SCL=22)
2. Vérifier résistances pull-up 4.7kΩ
3. Vérifier alimentation 3.3V (PAS 5V!)
4. Tester avec i2c_scanner:

```cpp
#include <Wire.h>
void setup() {
  Wire.begin(21, 22);
  Serial.begin(115200);
  Serial.println("Scan I2C...");
  
  for(byte addr = 1; addr < 127; addr++) {
    Wire.beginTransmission(addr);
    if (Wire.endTransmission() == 0) {
      Serial.printf("Device trouvé: 0x%02X\n", addr);
    }
  }
}
void loop() {}
```

Adresse attendue: **0x57** (MAX30100)

---

### ❌ **Température incorrecte**

**Si température = 0°C ou 100°C:**
- Vérifier LM35 orientation (voir schéma pins)
- Vérifier alimentation 3.3V
- Remplacer LM35 si défectueux

**Calibration:**
Modifier dans le code:
```cpp
float temp = voltage * 100.0 + OFFSET; // Ajouter offset si besoin
```

---

### ❌ **Bluetooth ne se connecte pas**

1. Redémarrer ESP32 (bouton RESET)
2. Vérifier nom dans l'app: "RespiraBox-ESP32"
3. Vérifier UUID service: `0000ffe0-...`
4. Effacer cache Bluetooth téléphone:
   - Android: Paramètres → Apps → Bluetooth → Vider cache

---

## 📊 **Format des données BLE**

**Caractéristique UUID:** `0000ffe1-0000-1000-8000-00805f9b34fb`

**Format string:**
```
HR:75,SPO2:98,TEMP:36.8
```

**Parsing Flutter:**
```dart
final data = characteristic.value;
final values = String.fromCharCodes(data).split(',');
final hr = int.parse(values[0].split(':')[1]);
final spo2 = int.parse(values[1].split(':')[1]);
final temp = double.parse(values[2].split(':')[1]);
```

---

## 🎯 **Optimisations possibles**

### **1. Ajout batterie (portable)**
```
3.7V LiPo + TP4056 (chargeur) + Régulateur 3.3V
```

### **2. Boîtier 3D**
```stl
Imprimer boîtier avec découpe pour:
- Capteur MAX30100 (fenêtre doigt)
- LED d'état
- Bouton ON/OFF
```

### **3. Économie d'énergie**
```cpp
// Mode deep sleep après 5 min inactivité
esp_sleep_enable_timer_wakeup(300 * 1000000); // 5 min
esp_deep_sleep_start();
```

---

## 📚 **Ressources**

- **MAX30100 Datasheet**: https://www.maximintegrated.com/en/products/interface/sensor-interface/MAX30100.html
- **LM35 Datasheet**: https://www.ti.com/product/LM35
- **ESP32 Pinout**: https://randomnerdtutorials.com/esp32-pinout-reference-gpios/

---

## ✅ **Checklist finale**

- [ ] MAX30100 détecté (adresse 0x57)
- [ ] SpO2 et FC affichés (doigt sur capteur)
- [ ] Température entre 25-40°C
- [ ] Bluetooth "RespiraBox-ESP32" visible
- [ ] Connexion app Flutter réussie
- [ ] Données reçues en temps réel

**Coût total:** ~7000 CFA  
**Temps assemblage:** 30 minutes  
**Niveau:** Débutant/Intermédiaire  

Bon montage! 🚀
