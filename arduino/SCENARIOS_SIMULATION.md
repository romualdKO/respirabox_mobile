# 🎭 Scénarios de simulation RespiraBox

Le code simule maintenant des données réalistes. Voici comment tester différents cas cliniques :

## 📊 Profils de santé simulés

### 1️⃣ **PERSONNE NORMALE** (Défaut - Code actuel)
```cpp
// Dans simulateBPM():
float baseValue = 72.0;  // BPM de repos normal
// Résultat: 60-90 bpm

// Dans simulateSpO2():
float baseValue = 97.0;  // SpO2 excellent
// Résultat: 94-100%
```
**Interprétation chatbot:**
- ✅ Santé respiratoire excellente
- ✅ Aucun signe d'alerte
- ✅ Continuer surveillance régulière

---

### 2️⃣ **PERSONNE SPORTIVE** (Meilleure santé)
Modifiez les lignes :
```cpp
// simulateBPM():
float baseValue = 58.0;  // BPM repos sportif
// Résultat: 50-75 bpm

// simulateSpO2():
float baseValue = 99.0;  // SpO2 optimal
// Résultat: 97-100%
```
**Interprétation chatbot:**
- ✅ Excellent niveau cardiovasculaire
- ✅ SpO2 optimal
- ✅ Profil athlétique

---

### 3️⃣ **PERSONNE STRESSÉE** (Légère augmentation)
```cpp
// simulateBPM():
float baseValue = 88.0;  // BPM élevé (stress/anxiété)
float timeVariation = sin(...) * 12.0;  // Plus de variation
// Résultat: 75-105 bpm

// simulateSpO2():
float baseValue = 96.0;  // SpO2 légèrement bas
// Résultat: 93-99%
```
**Interprétation chatbot:**
- ⚠️ Fréquence cardiaque élevée
- ⚠️ Possibles signes de stress/anxiété
- 💡 Recommande exercices de respiration

---

### 4️⃣ **PROBLÈME RESPIRATOIRE LÉGER** (Alerte modérée)
```cpp
// simulateBPM():
float baseValue = 82.0;  // BPM compensatoire
// Résultat: 70-95 bpm

// simulateSpO2():
float baseValue = 93.0;  // SpO2 limite basse
// Résultat: 90-96%
```
**Interprétation chatbot:**
- ⚠️ SpO2 en limite basse
- ⚠️ Surveillance recommandée
- 🏥 Consulter si symptômes persistent

---

### 5️⃣ **PROBLÈME RESPIRATOIRE SÉRIEUX** (Alerte forte)
```cpp
// simulateBPM():
float baseValue = 95.0;  // BPM compensatoire élevé
// Résultat: 85-110 bpm

// simulateSpO2():
float baseValue = 89.0;  // SpO2 critique
// Résultat: 85-93%
```
**Interprétation chatbot:**
- 🚨 SpO2 en dessous de 90% (critique!)
- 🚨 Fréquence cardiaque compensatoire
- 🏥 CONSULTER IMMÉDIATEMENT un médecin

---

## 🔄 Comment changer de scénario

1. **Ouvrez** `RespiraBox_ESP32.ino`
2. **Trouvez** les fonctions `simulateBPM()` et `simulateSpO2()`
3. **Modifiez** la valeur `baseValue`
4. **Upload** le nouveau code
5. **Testez** dans l'application

---

## 📈 Évolution dans le temps

Pour simuler une **dégradation progressive** (ex: crise d'asthme):

```cpp
// Dans simulateBPM():
float timeProgression = (millis() / 60000.0); // +1 par minute
float baseValue = 72.0 + (timeProgression * 3.0); // +3 bpm/min
if (baseValue > 110) baseValue = 110;

// Dans simulateSpO2():
float timeProgression = (millis() / 60000.0);
float baseValue = 97.0 - (timeProgression * 0.5); // -0.5% par minute
if (baseValue < 85) baseValue = 85;
```

**Résultat:**
- Minute 0: BPM=72, SpO2=97%
- Minute 5: BPM=87, SpO2=94.5%
- Minute 10: BPM=102, SpO2=92%
- Minute 15: BPM=110, SpO2=89.5%

**Chatbot détectera:** Détérioration progressive nécessitant intervention!

---

## 🧪 Test de prédiction du chatbot

Pour tester les **prédictions** basées sur l'historique:

1. **Faites 5 tests** avec valeurs normales:
   - Test 1-5: BPM=72, SpO2=97%

2. **Changez le scénario** vers "Problème léger":
   - Test 6: BPM=82, SpO2=93%

3. **Demandez au chatbot:**
   > "Analyse mes derniers tests"

**Le chatbot dira:**
- 📊 Tendance: Dégradation détectée
- ⚠️ SpO2 en baisse de 4% en 24h
- ⚠️ Fréquence cardiaque +10 bpm
- 💡 Recommandation: Consulter médecin si continue

---

## 🎯 Scénarios d'usage réel

### Test 1: Suivi quotidien normal
```
Jour 1-7: Profil NORMAL
→ Chatbot: "Santé stable, continuez!"
```

### Test 2: Début de grippe
```
Jour 1-3: Profil NORMAL
Jour 4-6: Profil STRESSÉ
Jour 7-9: Problème LÉGER
→ Chatbot: "Dégradation détectée, repos recommandé"
```

### Test 3: Crise d'asthme
```
Minute 0-5: Profil NORMAL
Minute 5-10: Profil STRESSÉ
Minute 10-15: Problème SÉRIEUX
→ Chatbot: "URGENCE! SpO2 critique, appeler urgences!"
```

---

## 💾 Données Firebase

Toutes les simulations sont **sauvegardées dans Firebase**:

```json
{
  "tests": [
    {
      "testDate": "2026-01-20T10:00:00Z",
      "heartRate": 72,
      "spo2": 97,
      "temperature": 28.5,
      "riskLevel": "low",
      "riskScore": 15
    },
    {
      "testDate": "2026-01-20T10:01:00Z",
      "heartRate": 82,
      "spo2": 93,
      "temperature": 28.5,
      "riskLevel": "moderate",
      "riskScore": 45
    }
  ]
}
```

Le **chatbot analyse** ces données pour:
- 📈 Détecter les tendances
- 🔮 Prédire les risques futurs
- 💊 Recommander actions préventives

---

✅ **Code actuel = Personne normale**
🔄 **Modifiez baseValue pour tester d'autres profils**
🧪 **Créez des historiques variés pour tester les prédictions**
