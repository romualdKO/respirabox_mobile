# 🌡️ Configuration API Météo OpenWeatherMap

## 📋 Étape 1: Créer un compte gratuit

1. Visitez: https://openweathermap.org/api
2. Cliquez sur **"Sign Up"** (en haut à droite)
3. Remplissez le formulaire:
   - Nom d'utilisateur
   - Email
   - Mot de passe
4. Confirmez votre email

## 🔑 Étape 2: Obtenir votre clé API

1. Connectez-vous sur https://home.openweathermap.org/
2. Allez dans **"API keys"** (menu)
3. Copiez votre clé API (format: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`)

⚠️ **IMPORTANT**: La clé peut prendre 10-20 minutes pour être activée

## 📝 Étape 3: Configurer dans l'application

Ouvrez le fichier: `lib/data/services/weather_service.dart`

Ligne 11, remplacez:
```dart
static const String _apiKey = 'VOTRE_CLE_API_ICI';
```

Par:
```dart
static const String _apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
```

## 📦 Étape 4: Installer les dépendances

```bash
cd C:\dev\respirabox_mobile
flutter pub get
```

## ✅ Étape 5: Tester l'API

Créez un fichier de test `test_weather.dart`:

```dart
import 'package:respirabox_mobile/data/services/weather_service.dart';

void main() async {
  print('🌍 Test API météo...');
  
  final temp = await WeatherService.getAmbientTemperature();
  if (temp != null) {
    print('✅ Température: ${temp.toStringAsFixed(1)}°C');
  } else {
    print('❌ Erreur récupération température');
  }
  
  final weather = await WeatherService.getWeatherInfo();
  if (weather != null) {
    print('✅ Météo complète:');
    print('   Ville: ${weather['city']}');
    print('   Température: ${weather['temperature']}°C');
    print('   Humidité: ${weather['humidity']}%');
    print('   Description: ${weather['description']}');
  }
}
```

Exécutez:
```bash
dart test_weather.dart
```

## 💰 Plan gratuit OpenWeatherMap

- ✅ **1000 appels/jour** (gratuit)
- ✅ Température actuelle
- ✅ Humidité, pression
- ✅ Description météo
- ✅ Toutes les villes du monde

## 🔄 Cache intelligent

Le service met en cache la température pendant **10 minutes** pour économiser les appels API.

Si vous faites 10 tests par heure → **6 appels API/heure** = **144 appels/jour** ✅

## 📍 Position par défaut

Si GPS désactivé ou permission refusée:
- **Latitude**: 5.3600
- **Longitude**: -4.0083
- **Ville**: Abidjan, Côte d'Ivoire
- **Température par défaut**: 27°C

## 🚀 Intégration avec ESP32

Le code ESP32 envoie: `HR:75,SPO2:98`

Flutter ajoute automatiquement la température:
```dart
final temperature = await WeatherService.getAmbientTemperature();
parsedData['TEMP'] = temperature; // Ajouté automatiquement
```

Résultat final sauvegardé dans Firebase:
```json
{
  "HR": 75,
  "SPO2": 98,
  "TEMP": 28.5
}
```

## 🛠️ Dépannage

### Erreur 401 (Unauthorized)
- ❌ Clé API invalide ou non activée
- ✅ Attendez 10-20 minutes après création
- ✅ Vérifiez que vous avez copié la bonne clé

### Erreur de permission GPS
- ❌ Permission GPS refusée
- ✅ Autorisez dans Paramètres → Applications → RespiraBox → Autorisations
- ✅ L'app utilisera Abidjan par défaut

### Timeout
- ❌ Connexion internet lente
- ✅ Vérifiez votre connexion
- ✅ Augmentez le timeout (ligne 28): `Duration(seconds: 15)`

## 📊 Exemple d'utilisation

```dart
// Dans votre écran de test
final weatherService = WeatherService();
final temp = await weatherService.getAmbientTemperature();

print('Température ambiante: $temp°C');
// Température ambiante: 28.5°C
```

## 🌐 API Alternative (si OpenWeatherMap ne fonctionne pas)

**WeatherAPI.com**: https://www.weatherapi.com/
- Plan gratuit: 1 million appels/mois
- Inscription similaire
- Documentation: https://www.weatherapi.com/docs/

Pour changer d'API, modifiez `weather_service.dart`:
```dart
static const String _baseUrl = 'https://api.weatherapi.com/v1/current.json';
static const String _apiKey = 'VOTRE_CLE_WEATHERAPI';
```

---

✅ **Configuration terminée!** Votre RespiraBox peut maintenant récupérer la température ambiante automatiquement.
