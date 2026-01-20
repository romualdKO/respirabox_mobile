/*
 * ========================================
 * 🔍 TEST I2C SCANNER
 * ========================================
 * Ce code scanne les adresses I2C pour détecter les périphériques
 * Le MAX30100 devrait apparaître à l'adresse 0x57
 * 
 * Connexions:
 *   SDA -> GPIO 21
 *   SCL -> GPIO 22
 *   VCC -> 3.3V
 *   GND -> GND
 * 
 * IMPORTANT: Ajoutez des résistances pull-up 4.7kΩ:
 *   - SDA vers 3.3V
 *   - SCL vers 3.3V
 */

#include <Wire.h>

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n🔍 I2C SCANNER - RespiraBox");
  Serial.println("================================");
  
  Wire.begin(21, 22); // SDA=21, SCL=22
  
  Serial.println("Scan en cours...\n");
  
  byte count = 0;
  
  for (byte i = 1; i < 127; i++) {
    Wire.beginTransmission(i);
    if (Wire.endTransmission() == 0) {
      Serial.print("✅ Device trouvé à l'adresse 0x");
      if (i < 16) Serial.print("0");
      Serial.print(i, HEX);
      
      // Identifier le device
      if (i == 0x57) {
        Serial.println(" (MAX30100 détecté!)");
      } else {
        Serial.println("");
      }
      
      count++;
      delay(10);
    }
  }
  
  Serial.println("\n================================");
  Serial.print("Scan terminé: ");
  Serial.print(count);
  Serial.println(" device(s) trouvé(s)");
  
  if (count == 0) {
    Serial.println("\n❌ AUCUN DEVICE DÉTECTÉ!");
    Serial.println("Vérifications:");
    Serial.println("  1. Câblage I2C correct?");
    Serial.println("  2. Alimentation 3.3V OK?");
    Serial.println("  3. Résistances pull-up 4.7kΩ présentes?");
    Serial.println("  4. MAX30100 bien soudé?");
  } else if (count > 0) {
    Serial.println("\n✅ Si MAX30100 détecté (0x57), le câblage est OK!");
    Serial.println("Uploadez maintenant RespiraBox_ESP32.ino");
  }
}

void loop() {
  // Rien à faire ici
}
