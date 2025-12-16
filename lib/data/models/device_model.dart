/// 📱 MODÈLE BOÎTIER RESPIRABOX
/// Représente un appareil RespiraBox détecté via Bluetooth
class DeviceModel {
  final String id; // ID Bluetooth du boîtier
  final String name; // Nom du boîtier (ex: RespiraBox-1138)
  final int signalStrength; // Force du signal (-100 à 0 dBm)
  final int batteryLevel; // Niveau de batterie (0-100%)
  final DeviceConnectionStatus status;
  final String? serialNumber;
  final String? firmwareVersion;
  final DateTime? lastConnected;

  DeviceModel({
    required this.id,
    required this.name,
    required this.signalStrength,
    this.batteryLevel = 0,
    this.status = DeviceConnectionStatus.disconnected,
    this.serialNumber,
    this.firmwareVersion,
    this.lastConnected,
  });

  /// Qualité du signal (excellent, good, medium, weak)
  String get signalQuality {
    if (signalStrength >= -50) return 'excellent';
    if (signalStrength >= -70) return 'good';
    if (signalStrength >= -85) return 'medium';
    return 'weak';
  }

  /// Texte localisé de la qualité du signal
  String get signalQualityText {
    switch (signalQuality) {
      case 'excellent':
        return 'Signal excellent';
      case 'good':
        return 'Signal bon';
      case 'medium':
        return 'Signal moyen';
      case 'weak':
        return 'Signal faible';
      default:
        return 'Signal inconnu';
    }
  }

  /// Copie avec modification
  DeviceModel copyWith({
    String? id,
    String? name,
    int? signalStrength,
    int? batteryLevel,
    DeviceConnectionStatus? status,
    String? serialNumber,
    String? firmwareVersion,
    DateTime? lastConnected,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      signalStrength: signalStrength ?? this.signalStrength,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      status: status ?? this.status,
      serialNumber: serialNumber ?? this.serialNumber,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      lastConnected: lastConnected ?? this.lastConnected,
    );
  }

  /// Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'signalStrength': signalStrength,
      'batteryLevel': batteryLevel,
      'status': status.toString().split('.').last,
      'serialNumber': serialNumber,
      'firmwareVersion': firmwareVersion,
      'lastConnected': lastConnected?.toIso8601String(),
    };
  }

  /// Conversion depuis Map
  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    return DeviceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      signalStrength: map['signalStrength'] ?? -100,
      batteryLevel: map['batteryLevel'] ?? 0,
      status: DeviceConnectionStatus.values.firstWhere(
        (e) => e.toString() == 'DeviceConnectionStatus.${map['status']}',
        orElse: () => DeviceConnectionStatus.disconnected,
      ),
      serialNumber: map['serialNumber'],
      firmwareVersion: map['firmwareVersion'],
      lastConnected: map['lastConnected'] != null
          ? DateTime.parse(map['lastConnected'])
          : null,
    );
  }
}

/// 📶 STATUT DE CONNEXION DU BOÎTIER
enum DeviceConnectionStatus {
  disconnected, // Déconnecté
  connecting, // Connexion en cours
  connected, // Connecté
  scanning, // Recherche en cours
  error, // Erreur de connexion
}
