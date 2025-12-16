# 🚀 GUIDE: Mettre RespiraBox sur GitHub

## ✅ ÉTAPE 1: Initialiser Git (Local)

Ouvrez PowerShell dans le dossier du projet et exécutez:

```powershell
# 1. Initialiser Git
git init

# 2. Configurer Git (votre nom et email)
git config user.name "Votre Nom"
git config user.email "votre.email@example.com"

# 3. Ajouter tous les fichiers
git add .

# 4. Vérifier ce qui sera commité
git status

# 5. Créer le premier commit
git commit -m "Initial commit: Frontend Flutter complet avec 13 écrans"
```

## ✅ ÉTAPE 2: Créer le Dépôt sur GitHub

1. Allez sur [github.com](https://github.com) et connectez-vous
2. Cliquez sur le bouton **"+"** en haut à droite → **"New repository"**
3. Remplissez les informations:
   - **Repository name**: `respirabox_mobile`
   - **Description**: `Application mobile Flutter pour le dépistage des maladies respiratoires`
   - **Visibilité**: 
     - ✅ **Public** (si vous voulez que tout le monde puisse voir le code)
     - ✅ **Private** (si vous voulez limiter l'accès à vos collaborateurs)
   - ❌ **NE PAS** cocher "Add a README" (on en a déjà un)
   - ❌ **NE PAS** ajouter .gitignore (on en a déjà un)
4. Cliquez sur **"Create repository"**

## ✅ ÉTAPE 3: Connecter Local → GitHub

Après avoir créé le dépôt sur GitHub, copiez l'URL qui s'affiche (exemple: `https://github.com/VotreUsername/respirabox_mobile.git`)

Dans PowerShell, exécutez:

```powershell
# 1. Ajouter le remote GitHub
git remote add origin https://github.com/VOTRE_USERNAME/respirabox_mobile.git

# 2. Renommer la branche en 'main' (si nécessaire)
git branch -M main

# 3. Pousser le code vers GitHub
git push -u origin main
```

## ✅ ÉTAPE 4: Inviter les Collaborateurs

1. Sur GitHub, allez dans votre dépôt `respirabox_mobile`
2. Cliquez sur **"Settings"** (en haut)
3. Dans le menu de gauche, cliquez sur **"Collaborators"**
4. Cliquez sur **"Add people"**
5. Entrez le nom d'utilisateur GitHub ou l'email de vos collaborateurs
6. Cliquez sur **"Add [nom] to this repository"**

Vos collaborateurs recevront une invitation par email.

## 👥 POUR VOS COLLABORATEURS

Une fois invités, ils doivent:

```powershell
# 1. Cloner le projet
git clone https://github.com/VOTRE_USERNAME/respirabox_mobile.git

# 2. Entrer dans le dossier
cd respirabox_mobile

# 3. Installer les dépendances Flutter
flutter pub get

# 4. Lancer l'application
flutter run
```

## 🔄 WORKFLOW COLLABORATIF

### Pour récupérer les modifications des autres:
```powershell
git pull origin main
```

### Pour envoyer vos modifications:
```powershell
# 1. Voir les fichiers modifiés
git status

# 2. Ajouter les fichiers modifiés
git add .

# 3. Créer un commit avec un message descriptif
git commit -m "Ajout de la fonctionnalité X"

# 4. Pousser vers GitHub
git push origin main
```

### Bonnes Pratiques:
- 🔄 **Toujours** faire `git pull` avant de commencer à travailler
- 💾 **Commiter souvent** avec des messages clairs
- 🚀 **Pousser régulièrement** pour partager votre travail
- 📝 **Messages descriptifs**: Ex: "Fix: Correction du bouton chatbot" au lieu de "fix"

## 🌿 WORKFLOW AVANCÉ (Recommandé)

Pour éviter les conflits, utilisez des branches:

```powershell
# 1. Créer une nouvelle branche pour votre fonctionnalité
git checkout -b feature/nom-de-la-fonctionnalite

# 2. Travailler et commiter normalement
git add .
git commit -m "Description des changements"

# 3. Pousser la branche
git push origin feature/nom-de-la-fonctionnalite

# 4. Sur GitHub, créer une Pull Request
# 5. Après validation, merger dans main
```

## ⚠️ FICHIERS SENSIBLES (Déjà Exclus)

Ces fichiers **NE SERONT PAS** envoyés sur GitHub (dans .gitignore):
- ✅ `android/app/google-services.json` (Configuration Firebase)
- ✅ `android/local.properties` (Chemins locaux)
- ✅ `build/` (Fichiers de compilation)
- ✅ `.dart_tool/` (Outils Dart)

**Important**: Partagez ces fichiers sensibles avec vos collaborateurs par un canal sécurisé (email, Drive, etc.)

## 🆘 COMMANDES UTILES

```powershell
# Voir l'historique des commits
git log --oneline

# Voir les modifications non commitées
git diff

# Annuler les modifications locales d'un fichier
git checkout -- nom_du_fichier

# Voir les branches
git branch -a

# Changer de branche
git checkout nom_de_la_branche

# Voir les collaborateurs
git shortlog -sn
```

## 📱 RÉSUMÉ RAPIDE

```powershell
# PREMIÈRE FOIS (Vous)
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/VOTRE_USERNAME/respirabox_mobile.git
git push -u origin main

# PREMIÈRE FOIS (Collaborateurs)
git clone https://github.com/VOTRE_USERNAME/respirabox_mobile.git
cd respirabox_mobile
flutter pub get

# AU QUOTIDIEN
git pull                    # Récupérer les changements
# ... travaillez ...
git add .                   # Ajouter vos modifications
git commit -m "Message"     # Commiter
git push                    # Pousser
```

## ✅ CHECKLIST

Avant de pousser sur GitHub, vérifiez:
- [ ] `.gitignore` est configuré
- [ ] Fichiers sensibles exclus (google-services.json)
- [ ] README.md à jour
- [ ] Code compile sans erreurs (`flutter run`)
- [ ] Commits ont des messages clairs

---

🎉 **Votre équipe peut maintenant travailler ensemble sur RespiraBox!**
