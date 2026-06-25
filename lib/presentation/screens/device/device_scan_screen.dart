import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
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
  List<ScanResult> _scanResults = [];
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

  /// 🔐 DEMANDER LES PERMISSIONS BLE + LOCALISATION
  Future<bool> _requestBlePermissions() async {
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];
    final statuses = await permissions.request();
    return statuses.values.every((s) => s.isGranted);
  }

  /// 🔍 DÉMARRER LE SCAN BLUETOOTH RÉEL
  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanResults.clear();
      _errorMessage = null;
    });

    try {
      // Demander les permissions BLE au runtime (obligatoire Android 6+)
      final permissionsGranted = await _requestBlePermissions();
      if (!permissionsGranted) {
        setState(() {
          _errorMessage =
              'Permissions Bluetooth refusées. Activez-les dans les paramètres de l\'application.';
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

      // Utiliser le service RespiraBox pour scanner TOUS les appareils
      final deviceService = ref.read(respiraBoxServiceProvider);
      final foundResults = await deviceService.scanForDevices(
        timeout: const Duration(seconds: 15),
      );

      if (!mounted) return;

      setState(() {
        _scanResults = foundResults;
        _isScanning = false;
        if (foundResults.isEmpty) {
          _errorMessage =
              'Aucun appareil Bluetooth détecté. Vérifiez que le boîtier est allumé.';
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
  Future<void> _connectToDevice(ScanResult result) async {
    final device = result.device;
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
      ref.read(connectedDeviceProvider.notifier).state =
          device.remoteId.toString();

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
                          'Appareils Bluetooth',
                          style: AppTextStyles.headline3,
                        ),
                        const Spacer(),
                        if (_scanResults.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_scanResults.length} trouvé${_scanResults.length > 1 ? 's' : ''}',
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isScanning ? null : _startScan,
                  icon:
                      Icon(_isScanning ? Icons.hourglass_empty : Icons.refresh),
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
            // Bouton Mode Démonstration (sans BLE)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton.icon(
                  onPressed: () {
                    ref.read(isDemoModeProvider.notifier).state = true;
                    Navigator.pushNamed(context, AppRoutes.testPreparation);
                  },
                  icon: const Icon(Icons.science_outlined, size: 18),
                  label: const Text('Mode démonstration (sans boîtier)'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textLight,
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

    if (_scanResults.isEmpty && !_isScanning) {
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
              'Aucun appareil détecté',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez que le Bluetooth est activé\nsur votre appareil',
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
      itemCount: _scanResults.length,
      itemBuilder: (context, index) {
        final result = _scanResults[index];
        return _DeviceCard(
          result: result,
          onConnect: () => _connectToDevice(result),
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
  final ScanResult result;
  final VoidCallback onConnect;

  const _DeviceCard({
    required this.result,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final device = result.device;
    final rssi = result.rssi;

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
          // Icône Bluetooth + indicateur RSSI
          Column(
            children: [
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
              const SizedBox(height: 4),
              _RssiIndicator(rssi: rssi),
            ],
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
                const SizedBox(height: 2),
                Text(
                  '${rssi} dBm',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _rssiColor(rssi),
                    fontSize: 11,
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

  Color _rssiColor(int rssi) {
    if (rssi >= -60) return AppColors.success;
    if (rssi >= -75) return Colors.orange;
    return AppColors.error;
  }
}

/// 📶 INDICATEUR DE SIGNAL RSSI (4 barres)
class _RssiIndicator extends StatelessWidget {
  final int rssi;

  const _RssiIndicator({required this.rssi});

  int get _bars {
    if (rssi >= -55) return 4;
    if (rssi >= -67) return 3;
    if (rssi >= -80) return 2;
    return 1;
  }

  Color get _color {
    if (rssi >= -60) return AppColors.success;
    if (rssi >= -75) return Colors.orange;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < _bars;
        final barHeight = 4.0 + i * 3.0;
        return Container(
          width: 4,
          height: barHeight,
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: active ? _color : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
