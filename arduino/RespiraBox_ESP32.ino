/*
 * ================================================================
 *  RESPIRABOX ESP32 — CODE FINAL PRODUCTION v5.0
 * ================================================================
 *
 *  Capteurs :
 *    • MAX30100  → SpO2 + Fréquence cardiaque (I2C)
 *                  SDA=GPIO21 | SCL=GPIO22 | VCC=3.3V
 *                  Pull-up 4.7kΩ sur SDA et SCL
 *
 *    • LM35DZ    → Température corporelle (analogique)
 *                  OUT=GPIO34 | VCC=3.3V | GND=GND
 *                  ⚠ ESP32 = 3.3V MAX sur ADC
 *
 *    • MQ-135    → Qualité de l'air / CO2 / Fumée (analogique)
 *                  AOUT=GPIO35 | VCC=5V (via Vin) | GND=GND
 *                  ⚠ Diviseur de tension obligatoire si VCC=5V :
 *                    AOUT → R1(10kΩ) → GPIO35 → R2(20kΩ) → GND
 *                    (ou alimentation 3.3V du MQ-135, moins précis)
 *
 *    • LCD 16×2  → Optionnel — mettre HAS_LCD false si absent
 *                  SDA=GPIO21 | SCL=GPIO22 (partagé avec MAX30100)
 *
 *  Brochage résumé :
 *    GPIO21 → SDA (MAX30100 + LCD)
 *    GPIO22 → SCL (MAX30100 + LCD)
 *    GPIO34 → LM35DZ AOUT   (ADC1_6 — entrée uniquement)
 *    GPIO35 → MQ-135 AOUT   (ADC1_7 — entrée uniquement, ≤ 3.3V)
 *    GPIO2  → LED bleue intégrée
 *
 *  Protocole BLE (compatible app Flutter) :
 *    Nom BLE      : RespiraBox-ESP32
 *    Service UUID : 0000ffe0-0000-1000-8000-00805f9b34fb
 *    Char UUID    : 0000ffe1-0000-1000-8000-00805f9b34fb
 *
 *  Messages → app Flutter :
 *    Données      → "HR:75,SPO2:98,TEMP:36.7,AQ:320"
 *    Doigt posé   → "STATUS:FINGER_ON"
 *    Doigt retiré → "STATUS:FINGER_OFF"
 *    Prêt         → "STATUS:READY"
 *    Erreur       → "ERROR:SENSOR_NOT_READY"
 *
 *  Commandes ← app Flutter :
 *    "START" → démarre l'envoi de données
 *    "STOP"  → arrête l'envoi de données
 *
 *  Bibliothèques (Arduino Library Manager) :
 *    • MAX30100lib          (OXullo Intersecans)
 *    • LiquidCrystal I2C   (Frank de Brabander) — si HAS_LCD=true
 *    • ESP32 BLE Arduino   (inclus avec board ESP32)
 *
 *  Board : "ESP32 Dev Module" | Partition : "Default" ou "Huge APP"
 * ================================================================
 */

// ── OPTIONS MATÉRIELLES ─────────────────────────────────────────
#define HAS_LCD    true   // false si vous n'avez pas de LCD 16x2 I2C

// ── BROCHAGE ────────────────────────────────────────────────────
#define PIN_SDA    21
#define PIN_SCL    22
#define PIN_LM35   34   // LM35DZ — ADC1_6
#define PIN_MQ135  35   // MQ-135  — ADC1_7 (≤3.3V obligatoire)
#define PIN_LED     2   // LED bleue intégrée

// ── BLE ─────────────────────────────────────────────────────────
#define BLE_NAME  "RespiraBox-ESP32"
#define SVC_UUID  "0000ffe0-0000-1000-8000-00805f9b34fb"
#define CHAR_UUID "0000ffe1-0000-1000-8000-00805f9b34fb"

// ── TIMING (ms) ─────────────────────────────────────────────────
#define T_MEASURE_MS    500    // Cycle lecture MAX30100 + LCD
#define T_BLE_SEND_MS  1000    // Envoi BLE (1×/s)
#define T_TEMP_MS      2000    // Lecture LM35 (1×/2s)
#define T_AQ_MS        3000    // Lecture MQ-135 (1×/3s)
#define T_LED_BLINK    400     // Clignotement LED attente
#define T_STABILISE   5000     // Stabilisation MAX30100 avant mesure
#define T_MERCI       5000     // Durée affichage résultats en mode local

// ── BUFFERS MOYENNES ────────────────────────────────────────────
#define AVG_SIZE      5    // Moyenne glissante BPM/SpO2
#define TEMP_SAMPLES 20    // Lissage LM35
#define AQ_SAMPLES   10    // Lissage MQ-135

// ── ADC ─────────────────────────────────────────────────────────
#define ADC_MAX   4095.0f
#define ADC_VREF     3.3f

// ── SEUILS MÉDICAUX ─────────────────────────────────────────────
#define SPO2_ALERTE  90.0f
#define TEMP_FIEVRE  38.5f
#define BPM_MIN      30.0f
#define BPM_MAX     200.0f
#define SPO2_SEUIL   50.0f
#define TEMP_MIN     15.0f
#define TEMP_MAX     45.0f
#define AQ_ALERTE   400    // ppm — au-dessus = qualité air mauvaise

// ════════════════════════════════════════════════════════════════
//  INCLUDES
// ════════════════════════════════════════════════════════════════
#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "MAX30100_PulseOximeter.h"

#if HAS_LCD
#include <LiquidCrystal_I2C.h>
LiquidCrystal_I2C lcd(0x27, 16, 2);
#endif

// ════════════════════════════════════════════════════════════════
//  OBJETS GLOBAUX
// ════════════════════════════════════════════════════════════════
PulseOximeter      pox;
BLEServer*         pServer         = nullptr;
BLECharacteristic* pCharacteristic = nullptr;

// ════════════════════════════════════════════════════════════════
//  FLAGS VOLATILE (thread-safe entre callbacks BLE et loop)
// ════════════════════════════════════════════════════════════════
volatile bool ble_connected        = false;
volatile bool ble_justConnected    = false;
volatile bool ble_justDisconnected = false;
volatile bool cmd_start            = false;
volatile bool cmd_stop             = false;

// ── ÉTAT APPLICATION ────────────────────────────────────────────
bool testActif    = false;
bool doigtDetecte = false;
bool mesureStable = false;
bool merciAffiche = false;
bool sensorPret   = false;

// ── DONNÉES MESURÉES ────────────────────────────────────────────
float valBPM   = 0.0f;
float valSpO2  = 0.0f;
float valTemp  = 25.0f;
int   valAQ    = 0;        // MQ-135 — ppm approximatif

// Buffers moyennes BPM / SpO2
float bpmBuf[AVG_SIZE];
float spo2Buf[AVG_SIZE];
int   bufIdx  = 0;
bool  bufFull = false;

// Buffer lissage LM35
float tempHisto[TEMP_SAMPLES];
int   tempIdx = 0;
int   tempN   = 0;

// Buffer lissage MQ-135
int   aqHisto[AQ_SAMPLES];
int   aqIdx   = 0;
int   aqN     = 0;

// ── TIMERS ──────────────────────────────────────────────────────
uint32_t tMesure   = 0;
uint32_t tBLESend  = 0;
uint32_t tTempRead = 0;
uint32_t tAQRead   = 0;
uint32_t tLed      = 0;
uint32_t tDoigt    = 0;
bool     ledEtat   = false;

// ════════════════════════════════════════════════════════════════
//  CALLBACKS BLE — Uniquement flags, PAS d'I2C ni lcd ici
// ════════════════════════════════════════════════════════════════
class ConnCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer*) override {
    ble_connected     = true;
    ble_justConnected = true;
  }
  void onDisconnect(BLEServer*) override {
    ble_connected        = false;
    ble_justDisconnected = true;
    cmd_start = false;
    cmd_stop  = false;
  }
};

class CharCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pC) override {
    String s = String(pC->getValue().c_str());
    s.trim(); s.toUpperCase();
    if      (s == "START") cmd_start = true;
    else if (s == "STOP")  cmd_stop  = true;
  }
};

void onBeat() {}

// ════════════════════════════════════════════════════════════════
//  HELPERS BLE + LCD
// ════════════════════════════════════════════════════════════════
void bleSend(const String& msg) {
  if (!ble_connected || !pCharacteristic) return;
  pCharacteristic->setValue(msg.c_str());
  pCharacteristic->notify();
}

#if HAS_LCD
void lcdShow(const char* l0, const char* l1) {
  lcd.clear();
  lcd.setCursor(0, 0); lcd.print(l0);
  lcd.setCursor(0, 1); lcd.print(l1);
}

void lcdMesures(float spo2, float bpm, float temp, int aq) {
  lcd.clear();
  // Ligne 0 : SpO2 + AQ
  lcd.setCursor(0, 0);
  lcd.print("O2:");
  lcd.print((int)spo2);
  lcd.print("% AQ:");
  lcd.print(aq);
  // Ligne 1 : FC + Temp
  lcd.setCursor(0, 1);
  lcd.print("FC:");
  lcd.print((int)bpm);
  lcd.print(" T:");
  lcd.print(temp, 1);
  lcd.print((char)223);
  lcd.print("C");
}

void lcdCompteur(int s) {
  lcd.clear();
  lcd.setCursor(0, 0); lcd.print("Stabilisation...");
  lcd.setCursor(0, 1); lcd.print("Patientez "); lcd.print(s); lcd.print("s");
}
#else
// Stubs vides si pas de LCD
void lcdShow(const char*, const char*) {}
void lcdMesures(float, float, float, int) {}
void lcdCompteur(int) {}
#endif

// ════════════════════════════════════════════════════════════════
//  LECTURE LM35DZ — Non bloquante
// ════════════════════════════════════════════════════════════════
void lireTemperature() {
  long somme = 0;
  for (int i = 0; i < TEMP_SAMPLES; i++) somme += analogRead(PIN_LM35);
  float lecture = somme / (float)TEMP_SAMPLES;
  float tension = lecture * (ADC_VREF / ADC_MAX);
  float t = tension * 100.0f;   // LM35 : 10 mV/°C

  if (t < TEMP_MIN || t > TEMP_MAX) return;

  tempHisto[tempIdx] = t;
  tempIdx = (tempIdx + 1) % TEMP_SAMPLES;
  if (tempN < TEMP_SAMPLES) tempN++;

  float total = 0;
  for (int i = 0; i < tempN; i++) total += tempHisto[i];
  valTemp = total / tempN;
}

// ════════════════════════════════════════════════════════════════
//  LECTURE MQ-135 — Non bloquante
//  Retourne une valeur approximative en ppm (0–1000)
//  Le MQ-135 nécessite ~60s de chauffe au démarrage.
//  Valeurs typiques : air pur ~400, intérieur normal ~500-700
// ════════════════════════════════════════════════════════════════
void lireQualiteAir() {
  int raw = analogRead(PIN_MQ135);  // 0–4095
  // Normalisation vers 0–1000 ppm (valeur indicative)
  int ppm = map(raw, 0, 4095, 0, 1000);

  aqHisto[aqIdx] = ppm;
  aqIdx = (aqIdx + 1) % AQ_SAMPLES;
  if (aqN < AQ_SAMPLES) aqN++;

  long total = 0;
  for (int i = 0; i < aqN; i++) total += aqHisto[i];
  valAQ = (int)(total / aqN);
}

// ════════════════════════════════════════════════════════════════
//  INIT BLE
// ════════════════════════════════════════════════════════════════
void initBLE() {
  BLEDevice::init(BLE_NAME);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ConnCallbacks());

  BLEService* svc = pServer->createService(SVC_UUID);
  pCharacteristic = svc->createCharacteristic(
    CHAR_UUID,
    BLECharacteristic::PROPERTY_READ  |
    BLECharacteristic::PROPERTY_WRITE |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic->addDescriptor(new BLE2902());
  pCharacteristic->setCallbacks(new CharCallbacks());
  svc->start();

  BLEAdvertising* adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(SVC_UUID);
  adv->setScanResponse(true);
  adv->setMinPreferred(0x06);
  adv->setMaxPreferred(0x12);
  BLEDevice::startAdvertising();
}

// ════════════════════════════════════════════════════════════════
//  SETUP
// ════════════════════════════════════════════════════════════════
void setup() {
  Serial.begin(115200);
  delay(300);
  pinMode(PIN_LED, OUTPUT);
  digitalWrite(PIN_LED, LOW);

  for (int i = 0; i < TEMP_SAMPLES; i++) tempHisto[i] = 0;
  for (int i = 0; i < AQ_SAMPLES;   i++) aqHisto[i]   = 0;

  Wire.begin(PIN_SDA, PIN_SCL);

#if HAS_LCD
  lcd.init();
  lcd.backlight();
  lcdShow(" RespiraBox v5", " Demarrage...");
  delay(1500);
#endif

  // MAX30100
  Serial.print("[MAX30100] Init... ");
  if (!pox.begin()) {
    Serial.println("ECHEC — verif cablage");
    lcdShow("MAX30100 ECHEC!", "Verif cablage");
    while (1) delay(1000);
  }
  pox.setIRLedCurrent(MAX30100_LED_CURR_7_6MA);
  pox.setOnBeatDetectedCallback(onBeat);
  Serial.println("OK");
  sensorPret = true;

  // MQ-135 — laisser chauffer
  Serial.println("[MQ-135] Chauffe en cours (60s recommandé)...");
  lcdShow("MQ-135 chauffe", "Patientez 60s");

  // BLE
  initBLE();

  Serial.println();
  Serial.println("================================================");
  Serial.println("  RespiraBox v5.0 — Pret");
  Serial.println("  MAX30100 : SDA=21  SCL=22");
  Serial.println("  LM35DZ  : GPIO34 (3.3V)");
  Serial.println("  MQ-135  : GPIO35 (diviseur tension si 5V)");
  Serial.println("  BLE     : " BLE_NAME);
  Serial.println("  Format  : HR:xx,SPO2:xx,TEMP:xx.x,AQ:xxx");
  Serial.println("================================================\n");

  for (int i = 0; i < 3; i++) {
    digitalWrite(PIN_LED, HIGH); delay(120);
    digitalWrite(PIN_LED, LOW);  delay(120);
  }

  lcdShow("Posez le doigt", "sur le capteur");
}

// ════════════════════════════════════════════════════════════════
//  LOOP PRINCIPAL
// ════════════════════════════════════════════════════════════════
void loop() {
  uint32_t now = millis();

  // 1. Update MAX30100 (aussi souvent que possible)
  pox.update();

  // 2. Événements BLE
  if (ble_justConnected) {
    ble_justConnected = false;
    testActif = false;
    bufIdx = 0; bufFull = false;
    digitalWrite(PIN_LED, HIGH);
    lcdShow("App connectee!", "Pret pour test");
    bleSend("STATUS:READY");
    Serial.println("[BLE] Connecte — STATUS:READY");
  }

  if (ble_justDisconnected) {
    ble_justDisconnected = false;
    testActif    = false;
    doigtDetecte = false;
    mesureStable = false;
    merciAffiche = false;
    lcdShow("Posez le doigt", "sur le capteur");
    pServer->startAdvertising();
    Serial.println("[BLE] Deconnecte — Advertising relance");
  }

  if (cmd_start) {
    cmd_start = false;
    if (!sensorPret) {
      bleSend("ERROR:SENSOR_NOT_READY");
    } else {
      testActif = true;
      bufIdx = 0; bufFull = false;
      Serial.println("[CMD] TEST DEMARRE");
      lcdShow("Test en cours", "Posez le doigt");
    }
  }

  if (cmd_stop) {
    cmd_stop  = false;
    testActif = false;
    Serial.println("[CMD] TEST ARRETE");
    lcdShow(ble_connected ? "Test termine" : "Posez le doigt",
            ble_connected ? "Merci !"      : "sur le capteur");
  }

  // 3. LED clignotante en attente
  if (!ble_connected && (now - tLed >= T_LED_BLINK)) {
    tLed = now;
    ledEtat = !ledEtat;
    digitalWrite(PIN_LED, ledEtat);
  }

  // 4. Lecture LM35DZ (toutes les 2s)
  if (now - tTempRead >= T_TEMP_MS) {
    tTempRead = now;
    lireTemperature();
  }

  // 5. Lecture MQ-135 (toutes les 3s)
  if (now - tAQRead >= T_AQ_MS) {
    tAQRead = now;
    lireQualiteAir();
    if (valAQ > AQ_ALERTE) {
      Serial.print("[MQ-135] !! Qualité air mauvaise : ");
      Serial.print(valAQ);
      Serial.println(" ppm");
    }
  }

  // 6. Cycle de mesure MAX30100 (toutes les 500ms)
  if (now - tMesure >= T_MEASURE_MS) {
    tMesure = now;

    float rawBPM  = pox.getHeartRate();
    float rawSpO2 = pox.getSpO2();

    if (rawBPM  >= BPM_MIN && rawBPM  <= BPM_MAX)   valBPM  = rawBPM;
    if (rawSpO2 >= SPO2_SEUIL && rawSpO2 <= 100.0f) valSpO2 = rawSpO2;

    bool doigtPresent = (valSpO2 > SPO2_SEUIL && valBPM > BPM_MIN);

    if (doigtPresent && !doigtDetecte) {
      doigtDetecte = true;
      mesureStable = false;
      merciAffiche = false;
      tDoigt = now;
      if (ble_connected) bleSend("STATUS:FINGER_ON");
      Serial.println("[MAX30100] Doigt detecte");
    }

    if (!doigtPresent && doigtDetecte) {
      doigtDetecte = false;
      mesureStable = false;
      merciAffiche = false;
      tDoigt = 0;
      if (ble_connected) bleSend("STATUS:FINGER_OFF");
      if (!testActif) lcdShow("Posez le doigt", "sur le capteur");
      Serial.println("[MAX30100] Doigt retire");
    }

    // Affichage local (sans test BLE actif)
    if (!testActif && doigtDetecte) {
      uint32_t elapsed = now - tDoigt;
      if (elapsed >= T_STABILISE) {
        uint32_t depuis = elapsed - T_STABILISE;
        if (depuis < T_MERCI) {
          lcdMesures(valSpO2, valBPM, valTemp, valAQ);
          if (!mesureStable) {
            mesureStable = true;
            Serial.println("[Local] Mesure stable");
          }
        } else if (!merciAffiche) {
          merciAffiche = true;
          lcdShow("Merci pour", "votre interet !");
        }
      } else {
        lcdCompteur((int)((T_STABILISE - elapsed) / 1000) + 1);
      }
    }
  }

  // 7. Envoi BLE (toutes les 1s pendant test actif)
  if (testActif && ble_connected && (now - tBLESend >= T_BLE_SEND_MS)) {
    tBLESend = now;

    // Moyenne glissante BPM + SpO2
    bpmBuf[bufIdx]  = valBPM;
    spo2Buf[bufIdx] = valSpO2;
    bufIdx++;
    if (bufIdx >= AVG_SIZE) { bufIdx = 0; bufFull = true; }

    int   n = bufFull ? AVG_SIZE : bufIdx;
    float avgBPM = 0, avgSpO2 = 0;
    for (int i = 0; i < n; i++) { avgBPM += bpmBuf[i]; avgSpO2 += spo2Buf[i]; }
    if (n > 0) { avgBPM /= n; avgSpO2 /= n; }

    // Payload complet : HR, SpO2, Temp, Qualité Air
    String payload = "HR:"    + String((int)avgBPM)   +
                     ",SPO2:" + String((int)avgSpO2)  +
                     ",TEMP:" + String(valTemp, 1)    +
                     ",AQ:"   + String(valAQ);

    bleSend(payload);
    Serial.print("[BLE] "); Serial.println(payload);

    // LCD pendant le test
    lcdMesures(avgSpO2, avgBPM, valTemp, valAQ);

    // Clignotement LED test
    digitalWrite(PIN_LED, !digitalRead(PIN_LED));

    // Alertes Serial
    if (avgSpO2 > 0 && avgSpO2 < SPO2_ALERTE)
      Serial.println("  !! ALERTE SpO2 < 90% !!");
    if (valTemp > TEMP_FIEVRE)
      Serial.println("  !! ALERTE Fievre > 38.5C !!");
    if (valAQ > AQ_ALERTE)
      Serial.println("  !! ALERTE Qualite air mauvaise !!");
  }
}
