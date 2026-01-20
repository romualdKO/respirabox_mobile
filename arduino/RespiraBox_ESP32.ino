/*
 * RespiraBox ESP32 - Prototype
 * Contrôlé depuis l'application Flutter
 */

#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "MAX30100_PulseOximeter.h"

#define REPORTING_PERIOD_MS 1000
#define AVG_SIZE 5

#define SERVICE_UUID        "0000ffe0-0000-1000-8000-00805f9b34fb"
#define CHARACTERISTIC_UUID "0000ffe1-0000-1000-8000-00805f9b34fb"

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
uint32_t lastReport = 0;

// MAX30100 (pour allumer la LED seulement)
PulseOximeter pox;

// État du test (contrôlé par Flutter)
bool testRunning = false;

float currentBPM = 72.0;
float currentSpO2 = 97.0;
float bpmBuffer[AVG_SIZE];
float spo2Buffer[AVG_SIZE];
int bufferIndex = 0;
bool bufferFilled = false;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("📱 Connecté");
    };
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      testRunning = false;
      Serial.println("📱 Déconnecté");
    }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String command = String(pCharacteristic->getValue().c_str());
      command.trim();
      
      if (command == "START") {
        testRunning = true;
        bufferIndex = 0;
        bufferFilled = false;
        Serial.println("✅ TEST DÉMARRÉ");
      }
      else if (command == "STOP") {
        testRunning = false;
        Serial.println("⏹️  TEST ARRÊTÉ");
      }
    }
};

float readBPM() {
  float base = 72.0;
  float variation = sin(millis() / 3000.0) * 8.0;
  float noise = (random(-100, 100) / 100.0) * 2.0;
  currentBPM = base + variation + noise;
  if (currentBPM < 60) currentBPM = 60;
  if (currentBPM > 90) currentBPM = 90;
  return currentBPM;
}

float readSpO2() {
  float base = 97.0;
  float variation = sin(millis() / 4000.0) * 1.5;
  float noise = (random(-100, 100) / 100.0) * 0.5;
  currentSpO2 = base + variation + noise;
  if (currentSpO2 < 94) currentSpO2 = 94;
  if (currentSpO2 > 100) currentSpO2 = 100;
  return currentSpO2;
}

void setup() {
  Serial.begin(115200);
  randomSeed(analogRead(0));
  
  Serial.println("🔧 Initialisation I2C...");
  Wire.begin(21, 22);
  
  // Initialiser MAX30100 pour allumer la LED (mais on n'utilise pas ses données)
  Serial.println("🔧 Initialisation MAX30100 (LED seulement)...");
  if (pox.begin()) {
    Serial.println("✅ MAX30100 initialisé - LED allumée");
  } else {
    Serial.println("⚠️  MAX30100 non détecté - Simulation active");
  }
  
  for (int i = 0; i < AVG_SIZE; i++) {
    bpmBuffer[i] = 72.0;
    spo2Buffer[i] = 97.0;
  }
  
  Serial.println("🔧 Initialisation BLE...");
  BLEDevice::init("RespiraBox-ESP32");
  Serial.println("   ✅ Device BLE initialisé");
  
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  Serial.println("   ✅ Serveur BLE créé");
  
  Serial.print("   🔧 Création du service UUID: ");
  Serial.println(SERVICE_UUID);
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  Serial.print("   🔧 Création de la caractéristique UUID: ");
  Serial.println(CHARACTERISTIC_UUID);
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ |
                      BLECharacteristic::PROPERTY_WRITE |
                      BLECharacteristic::PROPERTY_NOTIFY);
  pCharacteristic->addDescriptor(new BLE2902());
  pCharacteristic->setCallbacks(new MyCallbacks());
  Serial.println("   ✅ Caractéristique configurée");
  
  Serial.println("   🚀 Démarrage du service...");
  pService->start();
  Serial.println("   ✅ Service démarré!");
  
  Serial.println("   📡 Configuration de l'advertising...");
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  Serial.println("   ✅ Advertising configuré");
  
  Serial.println("   📢 Démarrage de l'advertising...");
  BLEDevice::startAdvertising();
  Serial.println("   ✅ Advertising actif!");
  
  Serial.println("✅ Bluetooth OK");
  Serial.print("📱 Nom du device: RespiraBox-ESP32\n");
  Serial.print("🆔 Service UUID: ");
  Serial.println(SERVICE_UUID);
  Serial.print("🆔 Characteristic UUID: ");
  Serial.println(CHARACTERISTIC_UUID);
  Serial.println("⏸️  En attente du démarrage du test depuis l'appli...\n");
}

void loop() {
  // Mettre à jour MAX30100 pour garder la LED allumée
  pox.update();
  
  if (testRunning && millis() - lastReport >= REPORTING_PERIOD_MS) {
    lastReport = millis();

    float bpmRaw = readBPM();
    float spo2Raw = readSpO2();

    bpmBuffer[bufferIndex] = bpmRaw;
    spo2Buffer[bufferIndex] = spo2Raw;

    bufferIndex++;
    if (bufferIndex >= AVG_SIZE) {
      bufferIndex = 0;
      bufferFilled = true;
    }

    int count = bufferFilled ? AVG_SIZE : bufferIndex;
    float bpm = 0, spo2 = 0;

    for (int i = 0; i < count; i++) {
      bpm += bpmBuffer[i];
      spo2 += spo2Buffer[i];
    }

    bpm = bpm / count;
    spo2 = spo2 / count;

    Serial.print("💓 ");
    Serial.print(bpm, 1);
    Serial.print(" | 🩸 ");
    Serial.println(spo2, 1);

    if (deviceConnected) {
      String data = "HR:" + String((int)bpm) + ",SPO2:" + String((int)spo2);
      pCharacteristic->setValue(data.c_str());
      pCharacteristic->notify();
    }
  }
  
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}
