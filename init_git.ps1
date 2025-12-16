# Script d'initialisation Git pour RespiraBox Mobile

Write-Host "🔧 Initialisation du dépôt Git..." -ForegroundColor Cyan

# Initialiser Git
git init

# Configurer Git (si pas déjà fait)
Write-Host "👤 Configuration Git..." -ForegroundColor Cyan
git config user.name "RespiraBox Team" 2>$null
git config user.email "respirabox@example.com" 2>$null

# Ajouter tous les fichiers
Write-Host "📦 Ajout des fichiers..." -ForegroundColor Cyan
git add .

# Afficher le statut
Write-Host "`n📊 Statut Git:" -ForegroundColor Green
git status

Write-Host "`n✅ Git initialisé avec succès!" -ForegroundColor Green
Write-Host "`n📝 Prochaines étapes:" -ForegroundColor Yellow
Write-Host "   1. Vérifiez les fichiers ci-dessus" -ForegroundColor White
Write-Host "   2. Créez un commit: git commit -m 'Initial commit: Frontend Flutter complet'" -ForegroundColor White
Write-Host "   3. Créez un dépôt sur GitHub.com" -ForegroundColor White
Write-Host "   4. Ajoutez le remote: git remote add origin https://github.com/VOTRE_USERNAME/respirabox_mobile.git" -ForegroundColor White
Write-Host "   5. Poussez le code: git push -u origin main" -ForegroundColor White
