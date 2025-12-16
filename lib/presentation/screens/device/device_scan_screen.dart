import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../data/models/device_model.dart';

/// 📶 ÉCRAN DE SCAN DES BOÎTIERS BLUETOOTH
/// Recherche et affiche les boîtiers RespiraBox disponibles
class DeviceScanScreen extends StatefulWidget {
  const DeviceScanScreen({Key? key}) : super(key: key);

  @override
  State<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends State<DeviceScanScreen> {
  bool _isScanning = false;
  final List<DeviceModel> _devices = [];

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    // TODO: Implémenter le scan Bluetooth avec flutter_blue_plus
    // Simulation de découverte de boîtiers
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _devices.addAll([
        DeviceModel(
          id: 'CI-1138',
          name: 'RespiraBox-1138',
          signalStrength: -45,
          batteryLevel: 87,
          status: DeviceConnectionStatus.disconnected,
        ),
        DeviceModel(
          id: 'CI-097B',
          name: 'RespiraBox-097B',
          signalStrength: -72,
          batteryLevel: 65,
          status: DeviceConnectionStatus.disconnected,
        ),
        DeviceModel(
          id: 'OTHER-BT',
          name: 'Autre appareil BT',
          signalStrength: -88,
          batteryLevel: 0,
          status: DeviceConnectionStatus.disconnected,
        ),
      ]);
      _isScanning = false;
    });
  }

  Future<void> _connectToDevice(DeviceModel device) async {
    // Simuler une connexion
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    Navigator.pop(context); // Fermer le dialog

    // Naviguer vers la préparation du test
    Navigator.pushNamed(context, AppRoutes.testPreparation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Connexion au boîtier',
          style: AppTextStyles.headline2.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textPrimary),
            onPressed: () {
              // TODO: Afficher l'aide
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Animation de scan
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isScanning)
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.bluetooth_searching,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isScanning ? 'Recherche en cours...' : 'Recherche terminée',
              style: AppTextStyles.headline2.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Assurez-vous que votre boîtier est allumé et à proximité.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Liste des appareils détectés
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appareils détectés',
                      style: AppTextStyles.headline3,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _devices.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bluetooth_disabled,
                                    size: 64,
                                    color: AppColors.textSecondary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucun appareil détecté',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _devices.length,
                              itemBuilder: (context, index) {
                                final device = _devices[index];
                                return _DeviceCard(
                                  device: device,
                                  onConnect: () => _connectToDevice(device),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            // Bouton relancer la recherche
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _isScanning ? null : _startScan,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    'Relancer la recherche',
                    style: AppTextStyles.button,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📦 CARTE D'UN BOÎTIER DÉTECTÉ
class _DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onConnect;

  const _DeviceCard({
    required this.device,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          // Icône Bluetooth
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              device.name.contains('RespiraBox')
                  ? Icons.bluetooth
                  : Icons.bluetooth_audio,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: AppTextStyles.headline3,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.signal_cellular_alt,
                      size: 16,
                      color: _getSignalColor(device.signalQuality),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      device.signalQualityText,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _getSignalColor(device.signalQuality),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bouton Connecter
          ElevatedButton(
            onPressed: onConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Connecter',
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSignalColor(String quality) {
    switch (quality) {
      case 'excellent':
        return AppColors.success;
      case 'good':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'weak':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
