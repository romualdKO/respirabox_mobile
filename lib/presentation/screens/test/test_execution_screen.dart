import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../routes/app_routes.dart';

/// 🫁 ÉCRAN D'EXÉCUTION DU TEST RESPIRATOIRE
/// Affiche les données en temps réel pendant le test
class TestExecutionScreen extends StatefulWidget {
  const TestExecutionScreen({Key? key}) : super(key: key);

  @override
  State<TestExecutionScreen> createState() => _TestExecutionScreenState();
}

class _TestExecutionScreenState extends State<TestExecutionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _timer;
  int _secondsRemaining = 30;
  double _progress = 0.0;

  // Données simulées en temps réel
  int _spo2 = 0;
  int _heartRate = 0;
  double _temperature = 0.0;
  bool _isRecording = false;

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
    super.dispose();
  }

  void _startTest() {
    setState(() => _isRecording = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
          _progress = 1 - (_secondsRemaining / 30);

          // Simuler des données réalistes
          final random = Random();
          _spo2 = 95 + random.nextInt(4); // 95-98%
          _heartRate = 70 + random.nextInt(20); // 70-90 bpm
          _temperature = 36.5 + (random.nextDouble() * 0.5); // 36.5-37.0°C
        });
      } else {
        _timer?.cancel();
        setState(() => _isRecording = false);
        _navigateToResults();
      }
    });
  }

  void _navigateToResults() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.testResults,
      arguments: {
        'spo2': _spo2,
        'heartRate': _heartRate,
        'temperature': _temperature,
        'riskLevel': 'Faible',
        'riskScore': 85,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          final scale = 1.0 + (_animationController.value * 0.2);
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

              // Données en temps réel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMetricCard(
                    icon: Icons.water_drop,
                    label: 'SpO2',
                    value: '$_spo2',
                    unit: '%',
                    color: AppColors.info,
                  ),
                  _buildMetricCard(
                    icon: Icons.favorite,
                    label: 'Fréquence',
                    value: '$_heartRate',
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
