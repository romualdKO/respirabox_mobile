# Pipeline ML — Détecteur crackles/sibilants

Modèle CNN léger entraîné sur un vrai dataset clinique public pour remplacer
l'heuristique acoustique codée en dur (`>15% énergie 3000-8000Hz`) qui servait
jusqu'ici à détecter les crépitements dans `audio_features_extractor.dart`.

## Dataset : ICBHI 2017 Respiratory Sound Database

- Source officielle : `bhichallenge.med.auth.gr/ICBHI_2017_Challenge` (le certificat
  SSL du site est expiré — utiliser `curl -k` pour télécharger)
- 126 patients, 920 fichiers audio, 6898 cycles respiratoires annotés
  (crackle 0/1, wheeze 0/1 par cycle)
- Citation : Rocha B.M. et al. (2019) "An open access database for the
  evaluation of respiratory sound classification algorithms", Physiological
  Measurement 40 035001.

### ⚠️ Limites connues (à garder en tête avant d'interpréter les résultats)

1. **Décalage de domaine** : enregistré au stéthoscope numérique posé sur le
   thorax (positions Al/Ar/Pl/Pr/Tc, appareils Meditron/Littmann/AKG), pas au
   micro de smartphone sur une toux volontaire — le cas d'usage réel de
   RespiraBox. Le modèle peut moins bien généraliser sur les enregistrements
   de l'app que sur le jeu de test ICBHI.
2. **Seulement 6 patients sur 126 avec diagnostic "Pneumonia" confirmé** —
   c'est pourquoi on n'entraîne PAS un classifieur "pneumonie oui/non" par
   patient (ce fut la première approche envisagée, écartée). On entraîne à
   la place un détecteur crackles/sibilants au niveau du cycle respiratoire
   (4131 cycles train / 2756 test, prévalence crackles ~38%/29%), ce pour
   quoi le dataset a été conçu (tâche officielle du challenge ICBHI 2017).
3. **Aucun label TB** dans ce dataset (population européenne). Pour un vrai
   modèle TB, il faudrait le CODA TB DREAM Challenge (Sage Bionetworks /
   Synapse), qui nécessite un compte + signature d'un accord d'utilisation
   des données (DUA) — non fait ici, à la charge de l'utilisateur du projet.

### Performance mesurée (jeu de test ICBHI, split officiel par patient)

| Sortie | AUC |
|---|---|
| Crackles | 0.70 |
| Wheezes | 0.72 |

Un signal réel mais modeste — à utiliser comme UN indice parmi d'autres dans
le scoring clinique (`cough_analysis_extension.dart`), jamais comme verdict
autonome. Le seuil 0.5 n'est pas calibré (rappel très faible sur les
crackles) : l'app utilise donc la **probabilité continue**, pas un booléen
seuillé — voir `pneumoniaRisk += (crackleProbML * 20).round()`.

## Pipeline

```
prepare_icbhi_data.py   → segmente les cycles, extrait 4131+2756 log-mel-spectrogrammes (64×313)
train_crackle_wheeze_model.py → CNN 3 blocs conv, sorties sigmoïdes [crackle, wheeze], export TFLite float16
dart_validation/        → validation numérique du portage Dart du calcul mel (MSE ~1e-16 vs librosa)
```

### Ré-entraîner

```bash
python3 -m venv ml_env && source ml_env/bin/activate
pip install -r requirements.txt

# Copier ICBHI_challenge_train_test.txt dans le dossier extrait avant de lancer
python prepare_icbhi_data.py --raw-dir /path/to/ICBHI_final_database --out-dir data/
python train_crackle_wheeze_model.py --data-dir data/ --out ../assets/models/crackle_wheeze_model.tflite
```

Le modèle sortant est directement utilisé par
`lib/data/services/crackle_wheeze_ml_service.dart` (aucune autre étape
d'intégration nécessaire — l'asset est déjà déclaré dans `pubspec.yaml`).

### Paramètres audio (doivent rester synchronisés entre Python et Dart)

`sample_rate=4000, n_fft=256, hop_length=64, n_mels=64, durée fenêtre=5s`
→ voir `lib/data/services/mel_spectrogram.dart` (réimplémentation Dart
numériquement validée du calcul librosa `melspectrogram` + `power_to_db`,
htk=False, norm='slaney', pad_mode='constant').

## Intégration Flutter

- `lib/data/services/crackle_wheeze_ml_service.dart` : charge le `.tflite`,
  rééchantillonne 44100→4000Hz (filtre passe-bas anti-repliement + interp.
  linéaire), calcule le mel-spectrogramme, lance l'inférence par fenêtres de
  5s, agrège par max sur l'enregistrement complet.
- Dégrade gracieusement : si le modèle ne charge pas (`Interpreter.fromAsset`
  échoue), `predict()` retourne `null` et `cough_analysis_extension.dart`
  retombe sur l'ancienne heuristique énergie haute-fréquence.
- Problème de build résolu : `tflite_flutter` ne fixait pas son `jvmTarget`
  Kotlin (héritait du JDK 21 de Gradle, en conflit avec son propre Java
  target 11) → fix scopé à ce seul plugin dans `android/build.gradle.kts`.

## Prochaine étape (non faite ici)

Un vrai modèle TB nécessite le dataset CODA TB DREAM Challenge (toux avec
statut TB confirmé par Xpert/culture). Contrairement à ICBHI, il n'est pas
en accès libre : compte Synapse + DUA à faire accepter par un humain du
projet avant de pouvoir lancer le même pipeline pour la tuberculose.
