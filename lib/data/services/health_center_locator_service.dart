import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/health_center_model.dart';
import '../../core/constants/app_constants.dart';

/// 📍 LOCALISATION DES CENTRES DE SANTÉ À PROXIMITÉ
///
/// Utilise la position GPS de l'utilisateur + OpenStreetMap Overpass API
/// (gratuite, sans clé) pour trouver hôpitaux/cliniques/cabinets médicaux
/// proches. Recommandé après un résultat de test à risque élevé.
///
/// ⚠️ Limite connue : la couverture OpenStreetMap peut être incomplète en
/// zone rurale — en l'absence de résultat, orienter vers le SAMU (185) ou
/// le centre de santé habituel du patient plutôt que de supposer qu'aucun
/// centre n'existe à proximité.
class HealthCenterLocatorService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  /// Récupère la position actuelle. Retourne les coordonnées par défaut
  /// d'Abidjan si la permission est refusée ou le service désactivé
  /// (dégradation gracieuse plutôt que blocage total de la fonctionnalité).
  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('⚠️ Position GPS indisponible: $e');
      return null;
    }
  }

  /// Recherche les centres de santé dans un rayon de [radiusMeters] autour
  /// de ([lat], [lon]). Retourne les [limit] plus proches, triés par distance.
  static Future<List<HealthCenterModel>> findNearby({
    double? lat,
    double? lon,
    int radiusMeters = 15000,
    int limit = 8,
  }) async {
    final position = await getCurrentPosition();
    final searchLat = lat ?? position?.latitude ?? AppConstants.defaultLatitude;
    final searchLon = lon ?? position?.longitude ?? AppConstants.defaultLongitude;

    final query = '''
[out:json][timeout:15];
(
  node["amenity"="hospital"](around:$radiusMeters,$searchLat,$searchLon);
  node["amenity"="clinic"](around:$radiusMeters,$searchLat,$searchLon);
  node["amenity"="doctors"](around:$radiusMeters,$searchLat,$searchLon);
  way["amenity"="hospital"](around:$radiusMeters,$searchLat,$searchLon);
  way["amenity"="clinic"](around:$radiusMeters,$searchLat,$searchLon);
);
out center;
''';

    try {
      final response = await http
          .post(Uri.parse(_overpassUrl), body: {'data': query})
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        print('⚠️ Overpass API erreur: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final elements = data['elements'] as List? ?? [];

      final centers = <HealthCenterModel>[];
      for (final el in elements) {
        final tags = el['tags'] as Map<String, dynamic>? ?? {};
        final name = tags['name'] as String?;
        if (name == null || name.trim().isEmpty) continue; // ignore anonymes

        final elLat = (el['lat'] ?? el['center']?['lat']) as num?;
        final elLon = (el['lon'] ?? el['center']?['lon']) as num?;
        if (elLat == null || elLon == null) continue;

        final distanceMeters = Geolocator.distanceBetween(
          searchLat, searchLon, elLat.toDouble(), elLon.toDouble(),
        );

        centers.add(HealthCenterModel(
          name: name,
          type: tags['amenity'] as String? ?? 'clinic',
          latitude: elLat.toDouble(),
          longitude: elLon.toDouble(),
          distanceKm: distanceMeters / 1000,
        ));
      }

      centers.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return centers.take(limit).toList();
    } catch (e) {
      print('⚠️ Recherche centres de santé échouée: $e');
      return [];
    }
  }
}
