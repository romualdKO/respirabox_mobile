import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/providers/app_providers.dart';
import '../../../routes/app_routes.dart';

/// 🫁 ÉCRAN D'EXÉCUTION DU TEST RESPIRATOIRE
/// Affiche les données en temps réel depuis l'ESP32
class TestExecutionScreen extends ConsumerStatefulWidget {
  const TestExecutionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TestExecutionScreen> createState() =>
      _TestExecutionScreenState();
}

class _TestExecutionScreenState extends ConsumerState<TestExecutionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _timer;
  int _secondsRemaining = 30;
  double _progress = 0.0;

  // Données ESP32 en temps réel
  double _spo2 = 0.0;
  double _heartRate = 0.0;
  double _temperature = 0.0;
  bool _isRecording = false;

  // Accumulation des données pour la moyenne finale
  List<double> _spo2Values = [];
  List<double> _hrValues = [];
  List<double> _tempValues = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _startTest();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    _stopTest();
    super.dispose();
  }

  Future<void> _startTest() async {
    setState(() => _isRecording = true);

    try {
      // Envoyer START à l'ESP32
      final deviceService = ref.read(respiraBoxServiceProvider);
      await deviceService.startTest();
      print('✅ Test démarré sur ESP32');

      // Timer pour le compte à rebours
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
            _progress = 1 - (_secondsRemaining / 30);
          });
        } else {
          _timer?.cancel();
          setState(() => _isRecording = false);
          _finishTest();
        }
      });
    } catch (e) {
      print('❌ Erreur démarrage test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _stopTest() async {
    try {
      final deviceService = ref.read(respiraBoxServiceProvider);
      await deviceService.stopTest();
      print('⏹️ Test arrêté sur ESP32');
    } catch (e) {
      print('❌ Erreur arrêt test: $e');
    }
  }

  Future<void> _finishTest() async {
    await _stopTest();

    // Calculer les moyennes
    final avgSpo2 = _spo2Values.isEmpty
        ? 0.0
        : _spo2Values.reduce((a, b) => a + b) / _spo2Values.length;
    final avgHR = _hrValues.isEmpty
        ? 0.0
        : _hrValues.reduce((a, b) => a + b) / _hrValues.length;
    final avgTemp = _tempValues.isEmpty
        ? 0.0
        : _tempValues.reduce((a, b) => a + b) / _tempValues.length;

    print('📊 Valeurs moyennes calculées:');
    print('   SpO2: $avgSpo2 (${_spo2Values.length} valeurs)');
    print('   HR: $avgHR (${_hrValues.length} valeurs)');
    print('   Temp: $avgTemp (${_tempValues.length} valeurs)');

    // Sauvegarder dans Firebase
    try {
      print('🔍 Récupération de l\'utilisateur...');
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.value;

      if (user == null) {
        print('❌ Aucun utilisateur connecté!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('⚠️ Utilisateur non connecté - Test non sauvegardé'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        print('✅ Utilisateur trouvé: ${user.id}');
        print('💾 Tentative de sauvegarde dans Firebase...');

        final deviceService = ref.read(respiraBoxServiceProvider);
        final savedTest = await deviceService.saveTestResult(
          userId: user.id,
          testData: {
            'SPO2': avgSpo2,
            'HR': avgHR,
            'TEMP': avgTemp,
          },
          notes: 'Test de 30 secondes avec ESP32',
        );

        print('✅ Test sauvegardé dans Firebase!');
        print('   ID du test: ${savedTest.id}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Test sauvegardé dans l\'historique'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Erreur sauvegarde Firebase: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur de sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Naviguer vers les résultats
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.testResults,
        arguments: {
          'spo2': avgSpo2.round(),
          'heartRate': avgHR.round(),
          'temperature': avgTemp,
          'riskLevel':
              avgSpo2 >= 95 ? 'Faible' : (avgSpo2 >= 90 ? 'Moyen' : 'Élevé'),
          'riskScore': avgSpo2 >= 95 ? 85 : (avgSpo2 >= 90 ? 60 : 35),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écouter le stream de données ESP32
    final deviceDataAsync = ref.watch(deviceDataStreamProvider);

    deviceDataAsync.whenData((data) {
      if (mounted && _isRecording) {
        setState(() {
          _spo2 = data['SPO2'] ?? _spo2;
          _heartRate = data['HR'] ?? _heartRate;
          _temperature = data['TEMP'] ?? _temperature;

          // Accumuler pour la moyenne
          if (_spo2 > 0) _spo2Values.add(_spo2);
          if (_heartRate > 0) _hrValues.add(_heartRate);
          if (_temperature > 0) _tempValues.add(_temperature);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => _showCancelDialog(),
        ),
        title: Text('Test en cours', style: AppTextStyles.h3),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Animation circulaire avec progression
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Cercle de progression
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularProgressIndicator(
                          value: _progress,
                          strokeWidth: 12,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),

                      // Animation de respiration
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          final scale =
                              1.0 + (_animationController.value * 0.2);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.1),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                size: 80,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        },
                      ),

                      // Temps restant
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 120),
                          Text(
                            '$_secondsRemaining',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text(
                            'secondes',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Instruction
              Text(
                'Restez immobile et respirez normalement',
                style: AppTextStyles.h3.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Données en temps réel depuis ESP32
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMetricCard(
                    icon: Icons.water_drop,
                    label: 'SpO2',
                    value: _spo2.round().toString(),
                    unit: '%',
                    color: AppColors.info,
                  ),
                  _buildMetricCard(
                    icon: Icons.favorite,
                    label: 'Fréquence',
                    value: _heartRate.round().toString(),
                    unit: 'bpm',
                    color: AppColors.error,
                  ),
                  _buildMetricCard(
                    icon: Icons.thermostat,
                    label: 'Température',
                    value: _temperature.toStringAsFixed(1),
                    unit: '°C',
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le test ?'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler le test en cours ? Les données ne seront pas enregistrées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () {
              _timer?.cancel();
              Navigator.pop(context); // Fermer le dialog
              Navigator.pop(context); // Retour à l'écran précédent
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Annuler le test'),
          ),
        ],
      ),
    );
  }
}
