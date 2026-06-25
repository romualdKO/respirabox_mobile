import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/services/demo_data_service.dart';
import '../../../data/services/patient_context_service.dart';
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

  // Statut synchronisation Arduino
  bool _fingerOnSensor = false;
  String _statusMessage = 'En attente du capteur...';

  // Accumulation des données pour la moyenne finale
  List<double> _spo2Values = [];
  List<double> _hrValues = [];
  List<double> _tempValues = [];

  StreamSubscription<Map<String, dynamic>>? _demoSubscription;

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
    _demoSubscription?.cancel();
    _stopTest();
    super.dispose();
  }

  Future<void> _startTest() async {
    setState(() => _isRecording = true);

    final isDemoMode = ref.read(isDemoModeProvider);

    try {
      if (isDemoMode) {
        // Mode démo : écouter le stream simulé
        setState(() {
          _fingerOnSensor = true;
          _statusMessage = 'Mode démonstration actif';
        });
        _demoSubscription = DemoDataService.simulateData().listen((data) {
          if (mounted && _isRecording) {
            setState(() {
              _spo2 = (data['SPO2'] as double?) ?? _spo2;
              _heartRate = (data['HR'] as double?) ?? _heartRate;
              _temperature = (data['TEMP'] as double?) ?? _temperature;
              if (_spo2 > 0) _spo2Values.add(_spo2);
              if (_heartRate > 0) _hrValues.add(_heartRate);
              if (_temperature > 0) _tempValues.add(_temperature);
            });
          }
        });
      } else {
        // Mode réel : envoyer START à l'ESP32
        final deviceService = ref.read(respiraBoxServiceProvider);
        await deviceService.startTest();
        if (mounted) print('✅ Test démarré sur ESP32');
      }

      // Timer pour le compte à rebours — s'arrête si le doigt est retiré
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_fingerOnSensor && _spo2 == 0.0) return; // Pause si doigt absent
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
    _demoSubscription?.cancel();
    _demoSubscription = null;
    final isDemoMode = ref.read(isDemoModeProvider);
    if (isDemoMode) return;
    try {
      final deviceService = ref.read(respiraBoxServiceProvider);
      await deviceService.stopTest();
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

        // Mémoriser les vitales pour le chatbot IA
        await PatientContextService.saveLatestVitals(
          spo2: avgSpo2,
          temperature: avgTemp,
          heartRate: avgHR.round(),
        );

        print('Test sauvegardé: ${savedTest.id}');

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
    final isDemoMode = ref.watch(isDemoModeProvider);


    // Écouter les données ESP32 en temps réel (ref.listen = safe hors build)
    if (!isDemoMode) {
      ref.listen<AsyncValue<Map<String, dynamic>>>(deviceDataStreamProvider,
          (_, next) {
        next.whenData((data) {
          if (!mounted || !_isRecording) return;
          setState(() {
            _spo2 = data['SPO2'] ?? _spo2;
            _heartRate = data['HR'] ?? _heartRate;
            _temperature = data['TEMP'] ?? _temperature;
            if (_spo2 > 0) {
              _fingerOnSensor = true;
              _spo2Values.add(_spo2);
            }
            if (_heartRate > 0) _hrValues.add(_heartRate);
            if (_temperature > 0) _tempValues.add(_temperature);
          });
        });
      });

      ref.listen<AsyncValue<String>>(deviceStatusStreamProvider, (_, next) {
        next.whenData((status) {
          if (!mounted) return;
          setState(() {
            switch (status) {
              case 'STATUS:FINGER_ON':
                _fingerOnSensor = true;
  
                _statusMessage = 'Doigt détecté — mesure en cours';
                break;
              case 'STATUS:FINGER_OFF':
                _fingerOnSensor = false;
                _statusMessage = 'Replacez le doigt sur le capteur';
                break;
              case 'STATUS:READY':
  
                _statusMessage = 'Capteur prêt — posez le doigt';
                break;
              case 'ERROR:SENSOR_NOT_READY':
  
                _statusMessage = 'Capteur non prêt — vérifiez le montage';
                break;
              default:
                break;
            }
          });
        });
      });
    }

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
              const SizedBox(height: 8),

              // Bandeau statut synchronisation Arduino
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _fingerOnSensor
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _fingerOnSensor ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _fingerOnSensor ? Icons.sensors : Icons.sensors_off,
                      color: _fingerOnSensor ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: _fingerOnSensor ? Colors.green.shade700 : Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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

                      // Animation pulse médicale — 3 cercles concentriques
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          final pulseColor = _spo2 >= 95
                              ? AppColors.success
                              : _spo2 >= 90
                                  ? AppColors.warning
                                  : _spo2 > 0
                                      ? AppColors.error
                                      : AppColors.primary;

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Cercle externe (délai 0)
                              _buildPulseRing(
                                size: 180,
                                phase: _animationController.value,
                                color: pulseColor,
                                opacity: 0.08,
                              ),
                              // Cercle intermédiaire (délai 0.33)
                              _buildPulseRing(
                                size: 150,
                                phase: ((_animationController.value + 0.33) % 1.0),
                                color: pulseColor,
                                opacity: 0.14,
                              ),
                              // Cercle interne avec icône
                              Transform.scale(
                                scale: 0.92 + (_animationController.value * 0.08),
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: pulseColor.withOpacity(0.18),
                                  ),
                                  child: Icon(
                                    Icons.favorite,
                                    size: 54,
                                    color: pulseColor,
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildPulseRing({
    required double size,
    required double phase,
    required Color color,
    required double opacity,
  }) {
    final scale = 0.85 + phase * 0.15;
    final alpha = opacity * (1 - phase);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(alpha),
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
