import 'dart:math';

/// Service pour générer une température ambiante réaliste
/// Basé sur le climat tropical de Côte d'Ivoire (Abidjan)
class WeatherService {
  // Dernière température générée pour cohérence
  static double? _lastTemperature;
  static DateTime? _lastUpdateTime;

  // Paramètres climatiques Côte d'Ivoire
  static const double _tempMin = 24.0; // Nuit/Pluie
  static const double _tempMax = 32.0; // Journée chaude
  static const double _tempMoyenne = 27.5;

  /// Récupère une température ambiante réaliste
  /// Varie selon l'heure de la journée avec petites fluctuations
  static Future<double> getAmbientTemperature() async {
    try {
      final now = DateTime.now();

      // Si dernière mesure < 2 minutes, retourner valeur stable avec micro-variation
      if (_lastTemperature != null &&
          _lastUpdateTime != null &&
          now.difference(_lastUpdateTime!).inMinutes < 2) {
        // Micro-variation ±0.1°C pour simulation réaliste
        final variation = (Random().nextDouble() - 0.5) * 0.2;
        _lastTemperature = _lastTemperature! + variation;
        _lastTemperature = _lastTemperature!.clamp(_tempMin, _tempMax);

        print(
            '🌡️ Température stable: ${_lastTemperature!.toStringAsFixed(1)}°C');
        return _lastTemperature!;
      }

      // Générer température basée sur l'heure (cycle jour/nuit)
      final hour = now.hour;
      double baseTemp;

      if (hour >= 6 && hour < 12) {
        // Matin: 25-28°C (montée progressive)
        baseTemp = 25.0 + ((hour - 6) / 6) * 3.0;
      } else if (hour >= 12 && hour < 16) {
        // Après-midi: 28-32°C (pic de chaleur)
        baseTemp = 28.0 + ((hour - 12) / 4) * 4.0;
      } else if (hour >= 16 && hour < 22) {
        // Soirée: 32-26°C (descente)
        baseTemp = 32.0 - ((hour - 16) / 6) * 6.0;
      } else {
        // Nuit: 24-25°C (stable)
        baseTemp = 24.0 + Random().nextDouble();
      }

      // Ajouter variation aléatoire ±1°C pour réalisme
      final variation = (Random().nextDouble() - 0.5) * 2.0;
      final temperature = (baseTemp + variation).clamp(_tempMin, _tempMax);

      // Mettre en cache
      _lastTemperature = temperature;
      _lastUpdateTime = now;

      print(
          '✅ Température ambiante: ${temperature.toStringAsFixed(1)}°C (${_getPeriodName(hour)})');
      return temperature;
    } catch (e) {
      print('❌ Erreur génération température: $e');
      return _tempMoyenne;
    }
  }

  /// Retourne le nom de la période de la journée
  static String _getPeriodName(int hour) {
    if (hour >= 6 && hour < 12) return 'Matin';
    if (hour >= 12 && hour < 16) return 'Après-midi';
    if (hour >= 16 && hour < 22) return 'Soirée';
    return 'Nuit';
  }

  /// Retourne les informations météo simulées pour Abidjan
  static Future<Map<String, dynamic>> getWeatherInfo() async {
    final temp = await getAmbientTemperature();
    final hour = DateTime.now().hour;

    return {
      'temperature': temp,
      'humidity': 75 + Random().nextInt(15), // 75-90%
      'pressure': 1010 + Random().nextInt(10), // 1010-1020 hPa
      'description': _getWeatherDescription(hour),
      'city': 'Abidjan',
      'country': 'CI',
    };
  }

  /// Génère une description météo réaliste
  static String _getWeatherDescription(int hour) {
    final random = Random().nextDouble();

    // Saison des pluies (avril-juillet, octobre-novembre)
    final month = DateTime.now().month;
    final isRainySeason =
        (month >= 4 && month <= 7) || (month >= 10 && month <= 11);

    if (isRainySeason && random > 0.6) {
      return 'Nuageux avec averses';
    } else if (hour >= 6 && hour < 18) {
      return random > 0.7 ? 'Ensoleillé' : 'Partiellement nuageux';
    } else {
      return 'Ciel dégagé';
    }
  }

  /// Efface le cache
  static void clearCache() {
    _lastTemperature = null;
    _lastUpdateTime = null;
    print('🗑️ Cache température effacé');
  }
}
