import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

/// SERVICE MÉTÉO — OpenWeatherMap
/// Récupère les données météo environnementales pour Abidjan.
/// Clé API : définir OPENWEATHER_API_KEY via --dart-define ou .env
class WeatherService {
  static const String _baseUrl = AppConstants.openWeatherBaseUrl;
  static const double _lat     = AppConstants.defaultLatitude;
  static const double _lon     = AppConstants.defaultLongitude;

  // Cache pour éviter les requêtes trop fréquentes
  static Map<String, dynamic>? _cachedData;
  static DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 10);

  /// Récupère les données météo actuelles
  /// Retourne les données de l'API ou des valeurs par défaut si indisponible
  static Future<Map<String, dynamic>> getWeatherInfo() async {
    // Retourner le cache si récent
    if (_cachedData != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      return _cachedData!;
    }

    final apiKey = AppConstants.openWeatherApiKey;

    if (apiKey.isEmpty) {
      print('[WeatherService] Clé API non configurée — données météo indisponibles');
      return _defaultWeatherData();
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl/weather?lat=$_lat&lon=$_lon&appid=$apiKey&units=metric&lang=fr',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body) as Map<String, dynamic>;

        final mainData = raw['main'] as Map<String, dynamic>? ?? {};
        final windData = raw['wind'] as Map<String, dynamic>? ?? {};
        final sysData  = raw['sys']  as Map<String, dynamic>? ?? {};
        final weatherList = raw['weather'] as List? ?? [];

        final data = {
          'temperature': (mainData['temp'] as num?)?.toDouble() ?? 27.5,
          'humidity':    (mainData['humidity'] as num?)?.toInt() ?? 80,
          'pressure':    (mainData['pressure'] as num?)?.toInt() ?? 1013,
          'description': weatherList.isNotEmpty
              ? ((weatherList.first as Map)['description'] as String? ?? 'N/A')
              : 'N/A',
          'city':        raw['name'] as String? ?? 'Abidjan',
          'country':     sysData['country'] as String? ?? 'CI',
          'windSpeed':   (windData['speed'] as num?)?.toDouble() ?? 0.0,
          'feelsLike':   (mainData['feels_like'] as num?)?.toDouble() ?? 27.5,
          'source':      'openweathermap',
          'isDefault':   false,
        };

        _cachedData = data;
        _lastFetch  = DateTime.now();
        return data;
      } else {
        print('[WeatherService] Erreur API: ${response.statusCode}');
        return _defaultWeatherData();
      }
    } catch (e) {
      print('[WeatherService] Erreur réseau: $e');
      return _defaultWeatherData();
    }
  }

  /// Température ambiante uniquement (version allégée)
  static Future<double> getAmbientTemperature() async {
    final info = await getWeatherInfo();
    return (info['temperature'] as num).toDouble();
  }

  /// Données météo par défaut quand l'API est indisponible
  static Map<String, dynamic> _defaultWeatherData() {
    return {
      'temperature': 27.5,
      'humidity':    80,
      'pressure':    1013,
      'description': 'Données indisponibles',
      'city':        'Abidjan',
      'country':     'CI',
      'windSpeed':   0.0,
      'feelsLike':   27.5,
      'source':      'default',
    };
  }

  /// Efface le cache (forcer une nouvelle requête)
  static void clearCache() {
    _cachedData = null;
    _lastFetch  = null;
  }
}
