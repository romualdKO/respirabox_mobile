/// 🏥 CENTRE DE SANTÉ À PROXIMITÉ
///
/// Résultat d'une recherche OpenStreetMap (Overpass API) autour de la
/// position de l'utilisateur.
class HealthCenterModel {
  final String name;
  final String type; // 'hospital', 'clinic', 'doctors'
  final double latitude;
  final double longitude;
  final double distanceKm;

  const HealthCenterModel({
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  String get typeLabel {
    switch (type) {
      case 'hospital':
        return 'Hôpital';
      case 'clinic':
        return 'Clinique';
      case 'doctors':
        return 'Cabinet médical';
      default:
        return 'Centre de santé';
    }
  }
}
