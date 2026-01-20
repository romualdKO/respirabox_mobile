/*
 * ========================================
 * 🔍 DIAGNOSTIC COMPLET MAX30100
 * ========================================
 * Ce code teste TOUTES les fonctions du MAX30100
 * pour identifier le problème exact
 */

#include <Wire.h>
#include "MAX30100_PulseOximeter.h"

PulseOximeter pox;
uint32_t lastPrint = 0;

void onBeatDetected() {
    Serial.println("💓💓💓 BATTEMENT DÉTECTÉ! 💓💓💓");
}

void setup() {
    Serial.begin(115200);
    delay(2000);
    
    Serial.println("\n\n");
    Serial.println("╔════════════════════════════════════════╗");
    Serial.println("║  🔍 DIAGNOSTIC MAX30100 - RESPIRABOX  ║");
    Serial.println("╚════════════════════════════════════════╝");
    Serial.println();
    
    // TEST 1: I2C
    Serial.println("📋 TEST 1: Scanner I2C");
    Serial.println("─────────────────────────────────────────");
    Wire.begin(21, 22);
    delay(100);
    
    bool max30100Found = false;
    byte deviceCount = 0;
    
    for (byte addr = 1; addr < 127; addr++) {
        Wire.beginTransmission(addr);
        if (Wire.endTransmission() == 0) {
            Serial.print("✅ Device trouvé: 0x");
            if (addr < 16) Serial.print("0");
            Serial.print(addr, HEX);
            
            if (addr == 0x57) {
                Serial.println(" ← MAX30100!");
                max30100Found = true;
            } else {
                Serial.println();
            }
            deviceCount++;
        }
        delay(10);
    }
    
    Serial.println();
    if (!max30100Found) {
        Serial.println("❌ MAX30100 NON DÉTECTÉ (0x57 absent)!");
        Serial.println();
        Serial.println("🔧 SOLUTIONS:");
        Serial.println("   1. Vérifiez le câblage:");
        Serial.println("      • SDA → GPIO 21");
        Serial.println("      • SCL → GPIO 22");
        Serial.println("      • VCC → 3.3V (PAS 5V!)");
        Serial.println("      • GND → GND");
        Serial.println();
        Serial.println("   2. Ajoutez résistances pull-up 4.7kΩ:");
        Serial.println("      • SDA ────[4.7kΩ]──── 3.3V");
        Serial.println("      • SCL ────[4.7kΩ]──── 3.3V");
        Serial.println();
        Serial.println("   3. Vérifiez soudures du MAX30100");
        Serial.println();
        Serial.println("⏸️ ARRÊT DU DIAGNOSTIC");
        while(1) { delay(1000); }
    }
    
    Serial.println("✅ MAX30100 détecté sur I2C!");
    Serial.println();
    
    // TEST 2: Initialisation
    Serial.println("📋 TEST 2: Initialisation MAX30100");
    Serial.println("─────────────────────────────────────────");
    
    if (!pox.begin()) {
        Serial.println("❌ ÉCHEC initialisation!");
        Serial.println();
        Serial.println("🔧 SOLUTIONS:");
        Serial.println("   1. Redémarrez l'ESP32");
        Serial.println("   2. Vérifiez l'alimentation 3.3V stable");
        Serial.println("   3. Essayez un autre MAX30100");
        while(1) { delay(1000); }
    }
    
    Serial.println("✅ Initialisation réussie!");
    
    // Configuration
    pox.setOnBeatDetectedCallback(onBeatDetected);
    pox.setIRLedCurrent(MAX30100_LED_CURR_7_6MA);
    
    Serial.println("✅ Configuration appliquée");
    Serial.println();
    
    // TEST 3: Stabilisation
    Serial.println("📋 TEST 3: Stabilisation (5 secondes)");
    Serial.println("─────────────────────────────────────────");
    
    for (int i = 0; i < 50; i++) {
        pox.update();
        delay(100);
        if (i % 10 == 0) {
            Serial.print(".");
        }
    }
    Serial.println(" OK");
    Serial.println("✅ Capteur stabilisé");
    Serial.println();
    
    // Instructions
    Serial.println("╔════════════════════════════════════════╗");
    Serial.println("║          👆 PLACEZ VOTRE DOIGT         ║");
    Serial.println("╚════════════════════════════════════════╝");
    Serial.println();
    Serial.println("📋 INSTRUCTIONS:");
    Serial.println("   1. Placez votre INDEX ou MAJEUR sur le capteur");
    Serial.println("   2. Couvrez COMPLÈTEMENT le capteur optique");
    Serial.println("   3. Appuyez FERMEMENT mais sans écraser");
    Serial.println("   4. Attendez 10 secondes SANS BOUGER");
    Serial.println();
    Serial.println("🔴 La LED rouge du capteur DOIT s'allumer!");
    Serial.println();
    Serial.println("📊 Début des mesures en temps réel...");
    Serial.println("─────────────────────────────────────────");
    Serial.println();
}

void loop() {
    pox.update();
    
    if (millis() - lastPrint >= 1000) {
        lastPrint = millis();
        
        float bpm = pox.getHeartRate();
        float spo2 = pox.getSpO2();
        
        // Affichage détaillé
        Serial.println("┌─────────────────────────────────────┐");
        Serial.print("│ BPM:  ");
        if (bpm > 0) {
            Serial.print(bpm, 1);
            Serial.print(" bpm ");
            
            if (bpm >= 40 && bpm <= 180) {
                Serial.println("✅ VALIDE     │");
            } else {
                Serial.println("⚠️  Suspect   │");
            }
        } else {
            Serial.println("0.0 bpm ❌ PAS DE DOIGT! │");
        }
        
        Serial.print("│ SpO2: ");
        if (spo2 > 0) {
            Serial.print((int)spo2);
            Serial.print(" %   ");
            
            if (spo2 >= 80 && spo2 <= 100) {
                Serial.println("✅ VALIDE     │");
            } else {
                Serial.println("⚠️  Suspect   │");
            }
        } else {
            Serial.println("0 %    ❌ PAS DE DOIGT! │");
        }
        Serial.println("└─────────────────────────────────────┘");
        
        // Diagnostics supplémentaires
        if (bpm == 0 && spo2 == 0) {
            Serial.println("❌ PROBLÈME: Aucune lecture");
            Serial.println("   → Doigt bien placé sur le capteur?");
            Serial.println("   → LED rouge allumée?");
            Serial.println("   → Pression suffisante?");
        } else if (bpm == 0 && spo2 > 0) {
            Serial.println("⚠️  SpO2 OK mais BPM=0");
            Serial.println("   → Maintenez le doigt plus stable");
        } else if (bpm > 0 && spo2 == 0) {
            Serial.println("⚠️  BPM OK mais SpO2=0");
            Serial.println("   → Problème capteur IR, continuez...");
        } else {
            Serial.println("✅ CAPTEUR FONCTIONNE!");
        }
        
        Serial.println();
    }
}
