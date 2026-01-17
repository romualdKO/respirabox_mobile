## 🎯 ARCHITECTURE DES SERVICES IA - RESPIRABOX

### 🧠 1. COHERE AI (Chat & Analyse)
**Clé API:** `zFG0EfXmnaaOxAkC98GMiJWjue3u8n4J1It1biFj`  
**Endpoint:** `https://api.cohere.ai/v1/chat`  
**Modèle:** `command-light`

#### Fonctionnalités :
✅ **Chat conversationnel** - Comprend le langage naturel
✅ **Analyse des données Firebase** - Profil utilisateur + Historique des tests
✅ **Prédictions médicales** - Basées sur les données personnelles
✅ **Recommandations personnalisées** - Selon le profil et les tests
✅ **Détection d'intention** - Analyse automatique des questions
✅ **Analyse de tendances** - Évolution des tests SpO2, fréquence cardiaque, température

#### Données Firebase analysées par Cohere :
```
👤 PROFIL PATIENT :
  - Nom, Email, Téléphone
  - Âge (calculé depuis dateOfBirth)
  - Sexe, Groupe sanguin
  - Taille, Poids
  - Conditions médicales
  - Allergies
  - Médicaments
  - Contact d'urgence

📊 HISTORIQUE TESTS (5 derniers) :
  - SpO2
  - Fréquence cardiaque
  - Température
  - Niveau de risque
  - Date du test
```

---

### 🎤 2. ASSEMBLYAI (Vocal & Audio)
**Clé API:** `a4daf92b53b84a198633a77a2c4b8616`  
**Endpoints:**
- Upload: `https://api.assemblyai.com/v2/upload`
- Transcription: `https://api.assemblyai.com/v2/transcript`

#### Fonctionnalités :
✅ **Transcription vocale** - Speech-to-Text en français
✅ **Analyse de toux** - Détection automatique des événements
✅ **Comptage de toux** - Nombre d'occurrences
✅ **Durée audio** - Mesure du temps d'enregistrement
✅ **Détection d'événements audio** - Toux, éternuements, respiration sifflante

#### Flux de travail :
```
1. 🎤 Utilisateur enregistre un audio
   ↓
2. 📤 Upload vers AssemblyAI
   ↓
3. 🔄 Transcription ou Analyse de toux
   ↓
4. 📝 Texte transcrit ou Résultats d'analyse
   ↓
5. 🧠 Envoi à Cohere AI pour analyse médicale
   ↓
6. 💬 Réponse personnalisée avec recommandations
```

---

### 🔄 3. INTÉGRATION DES DEUX SERVICES

#### Scénario 1 : Message texte simple
```
Utilisateur → "Mon SpO2 est à 92%, c'est normal ?"
           ↓
      COHERE AI
           ↓
   Analyse profil + tests + question
           ↓
   Réponse personnalisée
```

#### Scénario 2 : Message vocal (transcription)
```
Utilisateur → 🎤 Enregistre "Comment vont mes poumons ?"
           ↓
      ASSEMBLYAI (Transcription)
           ↓
   "Comment vont mes poumons ?"
           ↓
      COHERE AI
           ↓
   Analyse profil + tests + question
           ↓
   Réponse personnalisée
```

#### Scénario 3 : Analyse de toux
```
Utilisateur → 🎤 Enregistre une toux
           ↓
      ASSEMBLYAI (Analyse audio)
           ↓
   Résultats : {
     hasCough: true,
     coughCount: 3,
     duration: 5.2s,
     events: [...]
   }
           ↓
      COHERE AI
           ↓
   Analyse : "3 toux détectées en 5.2s"
   + Profil patient
   + Historique tests
           ↓
   Recommandations médicales personnalisées
```

---

### 📱 4. INTERFACE UTILISATEUR

#### Chatbot avec 3 modes d'interaction :

1. **💬 Mode Texte**
   - Champ de saisie normal
   - Bouton "Envoyer" ➤ Cohere AI

2. **🎤 Mode Vocal (Transcription)**
   - Bouton micro (orange)
   - Enregistrement → AssemblyAI → Cohere AI
   - Dialogue : "Transcrire en texte"

3. **🩺 Mode Analyse Toux**
   - Bouton micro (orange)
   - Enregistrement → AssemblyAI (analyse) → Cohere AI
   - Dialogue : "Analyser la toux"

---

### 📊 5. HISTORIQUE DES CONVERSATIONS

✅ **Sauvegarde Firebase** - Collection `conversations`
✅ **Chargement automatique** - Dernière conversation active
✅ **Nouvelle conversation** - Bouton "+"
✅ **Reprendre conversation** - Drawer avec liste complète
✅ **Suppression** - Bouton poubelle par conversation
✅ **Horodatage** - "Il y a X min/h/j"

#### Structure Firebase :
```javascript
conversations/{conversationId} {
  userId: string,
  title: string,
  createdAt: timestamp,
  updatedAt: timestamp,
  messages: [
    {
      text: string,
      isUser: boolean,
      timestamp: timestamp
    }
  ],
  isActive: boolean
}
```

---

### 🔑 6. CLÉS API CONFIGURÉES

| Service | Clé API | Statut |
|---------|---------|--------|
| **Cohere AI** | `zFG0EfXmnaaOxAkC98GMiJWjue3u8n4J1It1biFj` | ✅ Actif |
| **AssemblyAI** | `a4daf92b53b84a198633a77a2c4b8616` | ✅ Actif |
| **Firebase** | Configuration dans `google-services.json` | ✅ Actif |

---

### 🚀 7. FLUX COMPLET D'UNE INTERACTION

```
┌─────────────────────┐
│   UTILISATEUR       │
│  (Interface Mobile) │
└──────────┬──────────┘
           │
     ┌─────┴─────┐
     │           │
  Texte       Audio
     │           │
     │     ┌─────┴──────────┐
     │     │  ASSEMBLYAI    │
     │     │  - Transcription│
     │     │  - Analyse toux│
     │     └─────┬──────────┘
     │           │
     └─────┬─────┘
           │
    ┌──────▼──────────┐
    │   COHERE AI     │
    │  (command-light)│
    └──────┬──────────┘
           │
    ┌──────▼──────────┐
    │  FIREBASE       │
    │  - Profil user  │
    │  - Tests (5)    │
    │  - Conversations│
    └──────┬──────────┘
           │
    ┌──────▼──────────────┐
    │  ANALYSE COMPLÈTE   │
    │  - Contexte patient │
    │  - Historique      │
    │  - Audio (si toux) │
    └──────┬──────────────┘
           │
    ┌──────▼──────────────┐
    │  RÉPONSE IA        │
    │  Personnalisée     │
    │  + Recommandations │
    └──────┬──────────────┘
           │
    ┌──────▼──────────────┐
    │  SAUVEGARDE        │
    │  conversation      │
    │  dans Firebase     │
    └────────────────────┘
```

---

### ✨ 8. CAPACITÉS AVANCÉES

#### L'IA peut maintenant :
1. ✅ **Comprendre la parole** (AssemblyAI)
2. ✅ **Analyser la toux** (AssemblyAI + Cohere)
3. ✅ **Voir l'âge** calculé depuis la date de naissance
4. ✅ **Accéder au profil complet** (sexe, taille, poids, groupe sanguin)
5. ✅ **Lire les conditions médicales** (asthme, diabète, etc.)
6. ✅ **Connaître les allergies** (pénicilline, etc.)
7. ✅ **Voir les médicaments actuels**
8. ✅ **Analyser les 5 derniers tests**
9. ✅ **Détecter les tendances** (amélioration/détérioration)
10. ✅ **Faire des prédictions** basées sur l'historique
11. ✅ **Donner des recommandations personnalisées**
12. ✅ **Mémoriser les conversations** (historique complet)

---

### 🎯 RÉSUMÉ

**2 APIs actives en parallèle :**
- 🧠 **Cohere AI** = Cerveau (analyse, prédictions, recommandations)
- 🎤 **AssemblyAI** = Oreilles (écoute, transcription, détection toux)

**Données Firebase complètes :**
- 👤 Profil patient (11 champs dont âge calculé)
- 📊 Tests médicaux (historique)
- 💬 Conversations sauvegardées

**Résultat :** Une IA médicale complète qui :
1. Comprend votre voix
2. Analyse votre toux
3. Connaît TOUT votre profil
4. Se souvient de toutes vos conversations
5. Fait des prédictions personnalisées
6. Donne des recommandations adaptées

🎉 **TOUT FONCTIONNE ENSEMBLE !**
