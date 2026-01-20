/*
 * ========================================
 * 🧪 MODE SIMULATION - RESPIRABOX ESP32
 * ========================================
 * Ce code SIMULE des données réalistes pour tester
 * l'application Flutter pendant que vous réglez le capteur.
 * 
 * IMPORTANT: Utilisez RespiraBox_ESP32.ino avec le vrai capteur!
 */

#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// BLE UUIDs
#define SERVICE_UUID        "0000ffe0-0000-1000-8000-00805f9b34fb"
#define CHARACTERISTIC_UUID "0000ffe1-0000-1000-8000-00805f9b34fb"

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

uint32_t lastReport = 0;
float currentBPM = 72.0;
float currentSpO2 = 97.0;

// ========================================
// CALLBACKS BLUETOOTH
// ========================================
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("📱 Téléphone connecté!");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("📱 Téléphone déconnecté!");
    }
};

void setup() {
    Serial.begin(115200);
    Serial.println("\n\n");
    Serial.println("╔════════════════════════════════════════╗");
    Serial.println("║   🧪 MODE SIMULATION - RESPIRABOX     ║");
    Serial.println("╚════════════════════════════════════════╝");
    Serial.println();
    Serial.println("⚠️  ATTENTION: Données simulées!");
    Serial.println("    Utilisez RespiraBox_ESP32.ino avec le vrai capteur");
    Serial.println();
    
    // Initialiser Bluetooth BLE
    Serial.print("📶 Initialisation Bluetooth... ");
    BLEDevice::init("RespiraBox-SIMULATION");
    
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());
    
    BLEService *pService = pServer->createService(SERVICE_UUID);
    
    pCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID,
                        BLECharacteristic::PROPERTY_READ |
                        BLECharacteristic::PROPERTY_NOTIFY
                      );
    
    pCharacteristic->addDescriptor(new BLE2902());
    pService->start();
    
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();
    
    Serial.println("✅ OK");
    Serial.println();
    Serial.println("🚀 Simulation prête! En attente de connexion...");
    Serial.println("   Nom Bluetooth: RespiraBox-SIMULATION");
    Serial.println();
}

// Génère des valeurs réalistes avec variations
float getSimulatedBPM() {
    // BPM normal: 60-80 avec variations naturelles
    float baseValue = 72.0;
    float variation = (millis() / 1000) % 20 - 10; // ±10 bpm
    float noise = (random(0, 100) / 100.0) * 4 - 2; // ±2 bpm
    
    currentBPM = baseValue + variation * 0.3 + noise;
    
    // Limiter entre 60-85
    if (currentBPM < 60) currentBPM = 60;
    if (currentBPM > 85) currentBPM = 85;
    
    return currentBPM;
}

float getSimulatedSpO2() {
    // SpO2 normal: 95-99% avec légères variations
    float baseValue = 97.0;
    float variation = (millis() / 2000) % 4 - 2; // ±2%
    float noise = (random(0, 100) / 100.0) - 0.5; // ±0.5%
    
    currentSpO2 = baseValue + variation * 0.5 + noise;
    
    // Limiter entre 94-100
    if (currentSpO2 < 94) currentSpO2 = 94;
    if (currentSpO2 > 100) currentSpO2 = 100;
    
    return currentSpO2;
}

void sendDataBLE(float bpm, float spo2) {
    if (deviceConnected) {
        String data = "HR:" + String((int)bpm) + 
                     ",SPO2:" + String((int)spo2);
        
        pCharacteristic->setValue(data.c_str());
        pCharacteristic->notify();
        
        Serial.println("📤 Envoyé: " + data);
    }
}

void loop() {
    if (millis() - lastReport >= 1000) {
        lastReport = millis();

        float bpm = getSimulatedBPM();
        float spo2 = getSimulatedSpO2();

        // Affichage
        Serial.println("┌─────────────────────────────┐");
        Serial.println("│  🧪 SIMULATION RESPIRABOX  │");
        Serial.println("├─────────────────────────────┤");
        Serial.print("│  💓 BPM:  ");
        Serial.print((int)bpm);
        Serial.println(" bpm 🎲      │");
        Serial.print("│  🩸 SpO2: ");
        Serial.print((int)spo2);
        Serial.println(" % 🎲        │");
        Serial.println("└─────────────────────────────┘");

        sendDataBLE(bpm, spo2);
    }
    
    // Gérer reconnexion BLE
    if (!deviceConnected && oldDeviceConnected) {
        delay(500);
        pServer->startAdvertising();
        Serial.println("🔄 Redémarrage advertising BLE");
        oldDeviceConnected = deviceConnected;
    }
    
    if (deviceConnected && !oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
    }
}
