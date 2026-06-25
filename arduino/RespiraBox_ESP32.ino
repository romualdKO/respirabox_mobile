/*
 * ================================================================
 *  RESPIRABOX ESP32 — CODE FINAL PRODUCTION v4.0
 * ================================================================
 *
 *  Capteurs :
 *    • MAX30100  → SpO2 + Fréquence cardiaque
 *                  SDA=GPIO21 | SCL=GPIO22 | VCC=3.3V
 *                  Pull-up 4.7kΩ sur SDA et SCL
 *
 *    • LM35      → Température corporelle (analogique)
 *                  OUT=GPIO34 | VCC=3.3V | GND=GND
 *                  ⚠ ESP32 = 3.3V MAX — ne jamais mettre 5V !
 *
 *    • LCD 16×2  → Affichage local (I2C adresse 0x27 ou 0x3F)
 *                  SDA=GPIO21 | SCL=GPIO22
 *
 *  LED bleue GPIO2 :
 *    Clignotement rapide → En attente connexion BLE
 *    Fixe                → App connectée
 *    Clignotement lent   → Test BLE en cours
 *
 *  Protocole BLE (compatible app Flutter) :
 *    Nom BLE      : RespiraBox-ESP32
 *    Service UUID : 0000ffe0-0000-1000-8000-00805f9b34fb
 *    Char UUID    : 0000ffe1-0000-1000-8000-00805f9b34fb
 *
 *  Messages envoyés vers l'app :
 *    Données     → "HR:75,SPO2:98,TEMP:36.7"
 *    Doigt posé  → "STATUS:FINGER_ON"
 *    Doigt retiré→ "STATUS:FINGER_OFF"
 *    Prêt        → "STATUS:READY"
 *    Erreur      → "ERROR:SENSOR_NOT_READY"
 *
 *  Commandes reçues depuis l'app :
 *    "START" → démarre l'envoi de données
 *    "STOP"  → arrête l'envoi de données
 *
 *  Bibliothèques (Arduino Library Manager) :
 *    • MAX30100lib          (OXullo Intersecans)
 *    • LiquidCrystal I2C   (Frank de Brabander)
 *    • ESP32 BLE Arduino   (inclus avec board ESP32)
 *
 *  Board Arduino IDE : "ESP32 Dev Module"
 *  Partition         : "Default" ou "Huge APP"
 * ================================================================
 */

#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "MAX30100_PulseOximeter.h"

// ── BROCHAGE ────────────────────────────────────────────────────
#define PIN_SDA            21
#define PIN_SCL            22
#define PIN_LM35           34   // ADC1_6 — entrée analogique uniquement
#define PIN_LED             2   // LED bleue intégrée

// ── BLE ─────────────────────────────────────────────────────────
#define BLE_NAME   "RespiraBox-ESP32"
#define SVC_UUID   "0000ffe0-0000-1000-8000-00805f9b34fb"
#define CHAR_UUID  "0000ffe1-0000-1000-8000-00805f9b34fb"

// ── TIMING ──────────────────────────────────────────────────────
#define T_MEASURE_MS       500   // Cycle de mesure LCD (ms)
#define T_BLE_SEND_MS     1000   // Envoi BLE (ms) — 1 fois/seconde
#define T_TEMP_MS         2000   // Lecture LM35 (ms)
#define T_LED_BLINK_MS     400   // Clignotement LED attente
#define T_STABILISATION   5000   // Délai avant mesure stable (ms)
#define T_MERCI           5000   // Durée affichage mesures avant "Merci"
#define AVG_SIZE              5  // Moyenne glissante BPM/SpO2
#define TEMP_SAMPLES         20  // Lissage LM35

// ── ADC ESP32 ───────────────────────────────────────────────────
#define ADC_MAX    4095.0f
#define ADC_VREF      3.3f

// ── SEUILS MÉDICAUX ─────────────────────────────────────────────
#define SPO2_ALERTE   90.0f
#define TEMP_FIEVRE   38.5f
#define BPM_MIN       30.0f
#define BPM_MAX      200.0f
#define SPO2_SEUIL    50.0f   // En dessous = pas de doigt
#define TEMP_MIN      15.0f
#define TEMP_MAX      45.0f

// ════════════════════════════════════════════════════════════════
//  OBJETS MATÉRIELS
// ════════════════════════════════════════════════════════════════
LiquidCrystal_I2C lcd(0x27, 16, 2);  // Essayer 0x3F si LCD noir
PulseOximeter     pox;
BLEServer*         pServer         = nullptr;
BLECharacteristic* pCharacteristic = nullptr;

// ════════════════════════════════════════════════════════════════
//  FLAGS VOLATILES — seule façon thread-safe de communiquer
//  entre les callbacks BLE (tâche FreeRTOS) et le loop() principal
// ════════════════════════════════════════════════════════════════
volatile bool ble_connected        = false;
volatile bool ble_justConnected    = false;   // Événement one-shot
volatile bool ble_justDisconnected = false;   // Événement one-shot
volatile bool cmd_start            = false;
volatile bool cmd_stop             = false;

// ── ÉTAT APPLICATION ────────────────────────────────────────────
bool testActif       = false;   // Test BLE en cours
bool doigtDetecte    = false;
bool mesureStable    = false;
bool merciAffiche    = false;
bool sensorPret      = false;

// ── DONNÉES MESURÉES ────────────────────────────────────────────
float valBPM    = 0.0f;
float valSpO2   = 0.0f;
float valTemp   = 25.0f;

float bpmBuf[AVG_SIZE];
float spo2Buf[AVG_SIZE];
int   bufIdx  = 0;
bool  bufFull = false;

float tempHisto[TEMP_SAMPLES];
int   tempIdx  = 0;
int   tempN    = 0;
float tempDerniere = 25.0f;

// ── TIMERS ──────────────────────────────────────────────────────
uint32_t tMesure      = 0;
uint32_t tBLESend     = 0;
uint32_t tTempRead    = 0;
uint32_t tLed         = 0;
uint32_t tDoigtPose   = 0;
bool     ledEtat      = false;

// ════════════════════════════════════════════════════════════════
//  CALLBACKS BLE — N'appellent JAMAIS lcd ni Wire directement !
//  Uniquement des flags volatile → traitement dans loop()
// ════════════════════════════════════════════════════════════════
class ConnCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer*) override {
    ble_connected     = true;
    ble_justConnected = true;
  }
  void onDisconnect(BLEServer*) override {
    ble_connected        = false;
    ble_justDisconnected = true;
    cmd_start            = false;
    cmd_stop             = false;
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

// ════════════════════════════════════════════════════════════════
//  CALLBACK BATTEMENT MAX30100
// ════════════════════════════════════════════════════════════════
void onBeat() { /* optionnel : Serial.println("Beat"); */ }

// ════════════════════════════════════════════════════════════════
//  ENVOI BLE — thread-safe car appelé uniquement depuis loop()
// ════════════════════════════════════════════════════════════════
void bleSend(const String& msg) {
  if (!ble_connected || pCharacteristic == nullptr) return;
  pCharacteristic->setValue(msg.c_str());
  pCharacteristic->notify();
}

// ════════════════════════════════════════════════════════════════
//  LCD — appelé uniquement depuis loop() (même thread que Wire)
// ════════════════════════════════════════════════════════════════
void lcdShow(const char* l0, const char* l1) {
  lcd.clear();
  lcd.setCursor(0, 0); lcd.print(l0);
  lcd.setCursor(0, 1); lcd.print(l1);
}

void lcdMesures(float spo2, float bpm, float temp) {
  lcd.clear();

  // Ligne 0 : SpO2
  lcd.setCursor(0, 0);
  lcd.print("SpO2:");
  lcd.print((int)spo2);
  lcd.print("%");
  if (spo2 > 0 && spo2 < 95.0f) { lcd.setCursor(12, 0); lcd.print(" !!"); }

  // Ligne 1 : FC + Temp
  lcd.setCursor(0, 1);
  lcd.print("FC:");
  lcd.print((int)bpm);
  lcd.print(" T:");
  lcd.print(temp, 1);
  lcd.print((char)223);   // °
  lcd.print("C");
  if (bpm > 0 && (bpm < 50.0f || bpm > 120.0f)) {
    lcd.setCursor(14, 1); lcd.print("!");
  }
}

void lcdCompteur(int s) {
  lcd.clear();
  lcd.setCursor(0, 0); lcd.print("Analyse...");
  lcd.setCursor(0, 1); lcd.print("Patientez "); lcd.print(s); lcd.print("s");
}

// ════════════════════════════════════════════════════════════════
//  LECTURE LM35 — Non bloquante (appelée par timer, pas delay)
// ════════════════════════════════════════════════════════════════
void lireTemperature() {
  // 20 lectures rapides sans delay → utilisation d'analogRead direct
  // ESP32 ADC est assez stable sans délai inter-lecture
  long somme = 0;
  for (int i = 0; i < TEMP_SAMPLES; i++) somme += analogRead(PIN_LM35);
  float lecture = somme / (float)TEMP_SAMPLES;
  float tension = lecture * (ADC_VREF / ADC_MAX);
  float t = tension * 100.0f;   // LM35 : 10mV/°C

  if (t < TEMP_MIN || t > TEMP_MAX) return;   // Valeur aberrante ignorée

  // Moyenne glissante
  tempHisto[tempIdx] = t;
  tempIdx = (tempIdx + 1) % TEMP_SAMPLES;
  if (tempN < TEMP_SAMPLES) tempN++;

  float total = 0;
  for (int i = 0; i < tempN; i++) total += tempHisto[i];
  valTemp        = total / tempN;
  tempDerniere   = valTemp;
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

  Wire.begin(PIN_SDA, PIN_SCL);

  // LCD
  lcd.init();
  lcd.backlight();
  lcdShow("  RespiraBox  ", " Initialisation");
  delay(1500);
  lcd.clear();

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

  // BLE
  initBLE();

  Serial.println();
  Serial.println("==============================================");
  Serial.println("  RespiraBox v4.0 — Pret");
  Serial.println("  MAX30100 : SDA=21 SCL=22");
  Serial.println("  LM35     : GPIO34 (3.3V)");
  Serial.println("  LCD 16x2 : I2C 0x27");
  Serial.println("  BLE      : " BLE_NAME);
  Serial.println("  Format   : HR:xx,SPO2:xx,TEMP:xx.x");
  Serial.println("  Cmds     : START | STOP");
  Serial.println("==============================================\n");

  for (int i = 0; i < 3; i++) {
    digitalWrite(PIN_LED, HIGH); delay(120);
    digitalWrite(PIN_LED, LOW);  delay(120);
  }

  lcdShow("Posez le doigt", "sur le capteur");
}

// ════════════════════════════════════════════════════════════════
//  LOOP PRINCIPAL — tout le traitement ici, pas dans les callbacks
// ════════════════════════════════════════════════════════════════
void loop() {
  uint32_t now = millis();

  // ── 1. MAX30100 update (doit être appelé aussi souvent que possible) ──
  pox.update();

  // ── 2. Traitement des événements BLE (flags → actions LCD/BLE) ───────
  if (ble_justConnected) {
    ble_justConnected = false;
    testActif = false;
    bufIdx = 0; bufFull = false;
    digitalWrite(PIN_LED, HIGH);
    lcdShow("App connectee!", "Pret pour test");
    bleSend("STATUS:READY");
    Serial.println("[BLE] App connectee — STATUS:READY envoye");
  }

  if (ble_justDisconnected) {
    ble_justDisconnected = false;
    testActif   = false;
    doigtDetecte = false;
    mesureStable = false;
    merciAffiche = false;
    lcdShow("Posez le doigt", "sur le capteur");
    pServer->startAdvertising();
    Serial.println("[BLE] App deconnectee — Advertising relance");
  }

  if (cmd_start) {
    cmd_start = false;
    if (!sensorPret) {
      bleSend("ERROR:SENSOR_NOT_READY");
      Serial.println("[CMD] START refuse : capteur non pret");
    } else {
      testActif = true;
      bufIdx = 0; bufFull = false;
      Serial.println("[CMD] TEST DEMARRE");
      lcdShow("Test BLE actif", "Posez le doigt");
    }
  }

  if (cmd_stop) {
    cmd_stop  = false;
    testActif = false;
    Serial.println("[CMD] TEST ARRETE");
    if (ble_connected) lcdShow("Test termine", "Merci !");
    else               lcdShow("Posez le doigt", "sur le capteur");
  }

  // ── 3. LED clignotante en attente de connexion ──────────────────────
  if (!ble_connected && (now - tLed >= T_LED_BLINK_MS)) {
    tLed = now;
    ledEtat = !ledEtat;
    digitalWrite(PIN_LED, ledEtat);
  }

  // ── 4. Lecture température LM35 (toutes les 2s, non bloquant) ───────
  if (now - tTempRead >= T_TEMP_MS) {
    tTempRead = now;
    lireTemperature();
  }

  // ── 5. Cycle de mesure MAX30100 (toutes les 500ms) ──────────────────
  if (now - tMesure >= T_MEASURE_MS) {
    tMesure = now;

    float rawBPM  = pox.getHeartRate();
    float rawSpO2 = pox.getSpO2();

    if (rawBPM  >= BPM_MIN  && rawBPM  <= BPM_MAX)  valBPM  = rawBPM;
    if (rawSpO2 >= SPO2_SEUIL && rawSpO2 <= 100.0f) valSpO2 = rawSpO2;

    bool doigtPresent = (valSpO2 > SPO2_SEUIL && valBPM > BPM_MIN);

    // ── Gestion détection doigt ──────────────────────────────────────
    if (doigtPresent && !doigtDetecte) {
      doigtDetecte = true;
      mesureStable = false;
      merciAffiche = false;
      tDoigtPose   = now;
      Serial.println("Doigt detecte");
      if (ble_connected) bleSend("STATUS:FINGER_ON");
    }

    if (!doigtPresent && doigtDetecte) {
      doigtDetecte = false;
      mesureStable = false;
      merciAffiche = false;
      tDoigtPose   = 0;
      Serial.println("Doigt retire");
      if (ble_connected) bleSend("STATUS:FINGER_OFF");
      if (!testActif) lcdShow("Posez le doigt", "sur le capteur");
    }

    // ── Affichage LCD mode standalone (sans test BLE actif) ──────────
    if (!testActif && doigtDetecte) {
      uint32_t elapsed = now - tDoigtPose;
      if (elapsed >= T_STABILISATION) {
        uint32_t depuis = elapsed - T_STABILISATION;
        if (depuis < T_MERCI) {
          lcdMesures(valSpO2, valBPM, valTemp);
          if (!mesureStable) {
            mesureStable = true;
            Serial.println("Mesure stable (mode local)");
          }
        } else if (!merciAffiche) {
          merciAffiche = true;
          lcdShow("Merci pour", "votre interet !");
          Serial.println("Merci affiche");
        }
      } else {
        int reste = (T_STABILISATION - elapsed) / 1000 + 1;
        lcdCompteur(reste);
      }
    }
  }

  // ── 6. Envoi BLE données (toutes les 1s pendant un test actif) ──────
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

    // Format attendu par l'app Flutter
    String payload = "HR:"    + String((int)avgBPM)   +
                     ",SPO2:" + String((int)avgSpO2)  +
                     ",TEMP:" + String(valTemp, 1);

    bleSend(payload);
    Serial.print("[BLE] "); Serial.println(payload);

    // LCD pendant le test BLE
    lcdMesures(avgSpO2, avgBPM, valTemp);

    // Clignotement LED pendant le test
    digitalWrite(PIN_LED, !digitalRead(PIN_LED));

    // Alertes médicales Serial
    if (avgSpO2 > 0 && avgSpO2 < SPO2_ALERTE)
      Serial.println("  !! ALERTE SpO2 < 90% !!");
    if (valTemp > TEMP_FIEVRE)
      Serial.println("  !! ALERTE Fievre > 38.5C !!");
  }
}
