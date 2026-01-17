import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/providers/app_providers.dart';
import '../../../routes/app_routes.dart';

/// 📶 ÉCRAN DE SCAN BLUETOOTH RÉEL
/// Utilise RespiraBoxDeviceService pour scanner et connecter au prototype
class DeviceScanScreen extends ConsumerStatefulWidget {
  const DeviceScanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends ConsumerState<DeviceScanScreen> {
  bool _isScanning = false;
  List<BluetoothDevice> _devices = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  /// 🔍 DÉMARRER LE SCAN BLUETOOTH RÉEL
  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
      _errorMessage = null;
    });

    try {
      // Vérifier si Bluetooth est disponible
      final isAvailable = await FlutterBluePlus.isAvailable;
      if (!isAvailable) {
        setState(() {
          _errorMessage = 'Bluetooth non disponible sur cet appareil';
          _isScanning = false;
        });
        return;
      }

      // Vérifier si Bluetooth est activé
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        setState(() {
          _errorMessage = 'Veuillez activer le Bluetooth';
          _isScanning = false;
        });
        return;
      }

      // Utiliser le service RespiraBox pour scanner
      final deviceService = ref.read(respiraBoxServiceProvider);
      final foundDevices = await deviceService.scanForDevices(
        timeout: const Duration(seconds: 10),
      );

      if (!mounted) return;

      setState(() {
        _devices = foundDevices;
        _isScanning = false;
        if (foundDevices.isEmpty) {
          _errorMessage = 'Aucun RespiraBox détecté. Assurez-vous que le boîtier est allumé.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur lors du scan: $e';
        _isScanning = false;
      });
    }
  }

  /// 🔗 CONNECTER AU DEVICE SÉLECTIONNÉ
  Future<void> _connectToDevice(BluetoothDevice device) async {
    // Afficher le dialog de connexion
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Connexion à ${device.platformName}...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    try {
      // Utiliser le service pour se connecter
      final deviceService = ref.read(respiraBoxServiceProvider);
      await deviceService.connectToDevice(device);

      // Mettre à jour l'état de connexion
      ref.read(deviceConnectionProvider.notifier).state = true;
      ref.read(connectedDeviceProvider.notifier).state = device.remoteId.toString();

      if (!mounted) return;
      Navigator.pop(context); // Fermer le dialog

      // Succès: naviguer vers la préparation du test
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Connecté à ${device.platformName}'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pushNamed(context, AppRoutes.testPreparation);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Fermer le dialog

      // Erreur de connexion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
          'Scanner RespiraBox',
          style: AppTextStyles.headline2.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textPrimary),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Animation de scan
            _buildScanAnimation(),
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
                'Assurez-vous que votre RespiraBox est allumé et à proximité (moins de 10 mètres).',
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
                    Row(
                      children: [
                        Text(
                          'Appareils RespiraBox',
                          style: AppTextStyles.headline3,
                        ),
                        const Spacer(),
                        if (_devices.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_devices.length} trouvé${_devices.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildDeviceList(),
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
                  icon: Icon(_isScanning ? Icons.hourglass_empty : Icons.refresh),
                  label: Text(
                    _isScanning ? 'Scan en cours...' : 'Relancer la recherche',
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

  Widget _buildScanAnimation() {
    return Center(
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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.2),
              ),
              child: Icon(
                _isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                size: 60,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    if (_devices.isEmpty && !_isScanning) {
      return Center(
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
              'Aucun RespiraBox détecté',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez que le boîtier est allumé\net à proximité',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return _DeviceCard(
          device: device,
          onConnect: () => _connectToDevice(device),
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide - Connexion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem('1. Activez le Bluetooth sur votre téléphone'),
            _buildHelpItem('2. Allumez votre boîtier RespiraBox'),
            _buildHelpItem('3. Rapprochez-vous du boîtier (moins de 10m)'),
            _buildHelpItem('4. Attendez que le scan détecte le boîtier'),
            _buildHelpItem('5. Appuyez sur "Connecter"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// 📦 CARTE D'UN DEVICE BLUETOOTH DÉTECTÉ
class _DeviceCard extends StatelessWidget {
  final BluetoothDevice device;
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
            child: const Icon(
              Icons.bluetooth_connected,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.platformName.isNotEmpty 
                      ? device.platformName 
                      : 'RespiraBox ${device.remoteId.toString().substring(0, 8)}',
                  style: AppTextStyles.headline3,
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${device.remoteId.toString().substring(0, 17)}...',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          // Bouton Connecter
          ElevatedButton(
            onPressed: onConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Connecter'),
          ),
        ],
      ),
    );
  }
}