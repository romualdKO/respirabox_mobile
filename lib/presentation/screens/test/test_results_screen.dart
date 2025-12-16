import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../routes/app_routes.dart';

/// 📊 ÉCRAN DES RÉSULTATS DU TEST
/// Affiche les résultats détaillés et les recommandations
class TestResultsScreen extends StatelessWidget {
  const TestResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Récupérer les arguments (données du test)
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final spo2 = args['spo2'] ?? 96;
    final heartRate = args['heartRate'] ?? 75;
    final temperature = args['temperature'] ?? 36.8;
    final riskLevel = args['riskLevel'] ?? 'Faible';
    final riskScore = args['riskScore'] ?? 85;

    final Color riskColor = _getRiskColor(riskLevel);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          ),
        ),
        title: Text('Résultats du test', style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textDark),
            onPressed: () {
              // TODO: Partager les résultats
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score de risque
              _buildRiskScoreCard(riskLevel, riskScore, riskColor),
              const SizedBox(height: 25),

              // Métriques principales
              Text('Vos mesures', style: AppTextStyles.h3),
              const SizedBox(height: 15),
              _buildMetricsGrid(spo2, heartRate, temperature),
              const SizedBox(height: 30),

              // Interprétation
              Text('Interprétation', style: AppTextStyles.h3),
              const SizedBox(height: 15),
              _buildInterpretationCard(riskLevel, spo2, riskColor),
              const SizedBox(height: 30),

              // Recommandations
              Text('Recommandations', style: AppTextStyles.h3),
              const SizedBox(height: 15),
              _buildRecommendations(riskLevel),
              const SizedBox(height: 30),

              // Actions
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskScoreCard(String riskLevel, int score, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Niveau de risque',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            riskLevel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          // Score circulaire
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                '$score/100',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _getRiskDescription(riskLevel),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(int spo2, int heartRate, double temperature) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.water_drop,
            label: 'Saturation O2',
            value: '$spo2%',
            status: spo2 >= 95 ? 'Normal' : 'Bas',
            statusColor: spo2 >= 95 ? AppColors.success : AppColors.warning,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.favorite,
            label: 'Fréquence cardiaque',
            value: '$heartRate bpm',
            status: heartRate <= 90 ? 'Normal' : 'Élevé',
            statusColor: heartRate <= 90 ? AppColors.success : AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Icon(icon, color: statusColor, size: 32),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterpretationCard(String riskLevel, int spo2, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: color),
              const SizedBox(width: 10),
              const Text(
                'Analyse',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getInterpretation(riskLevel, spo2),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(String riskLevel) {
    final recommendations = _getRecommendations(riskLevel);
    
    return Column(
      children: recommendations.map((rec) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(rec['icon'] as IconData, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  rec['text'] as String,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
            },
            icon: const Icon(Icons.home),
            label: const Text('Retour à l\'accueil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Nouveau test
              Navigator.pushNamed(context, AppRoutes.testPreparation);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refaire un test'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'faible':
        return AppColors.success;
      case 'moyen':
        return AppColors.warning;
      case 'élevé':
      case 'eleve':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  String _getRiskDescription(String level) {
    switch (level.toLowerCase()) {
      case 'faible':
        return 'Vos mesures sont dans les normes';
      case 'moyen':
        return 'Certaines valeurs nécessitent attention';
      case 'élevé':
      case 'eleve':
        return 'Consultez un professionnel de santé';
      default:
        return 'Résultats en cours d\'analyse';
    }
  }

  String _getInterpretation(String riskLevel, int spo2) {
    if (riskLevel.toLowerCase() == 'faible') {
      return 'Vos paramètres respiratoires sont normaux. Votre saturation en oxygène ($spo2%) est dans la plage normale (>95%). Continuez à surveiller régulièrement votre santé respiratoire.';
    } else if (riskLevel.toLowerCase() == 'moyen') {
      return 'Votre saturation en oxygène est légèrement en dessous de la normale. Il est recommandé de consulter un professionnel de santé si les symptômes persistent ou s\'aggravent.';
    } else {
      return 'Vos mesures indiquent un risque potentiel. Il est fortement recommandé de consulter rapidement un professionnel de santé pour une évaluation complète.';
    }
  }

  List<Map<String, dynamic>> _getRecommendations(String riskLevel) {
    if (riskLevel.toLowerCase() == 'faible') {
      return [
        {'icon': Icons.check_circle_outline, 'text': 'Continuez à surveiller votre santé régulièrement'},
        {'icon': Icons.sports_outlined, 'text': 'Maintenez une activité physique régulière'},
        {'icon': Icons.healing_outlined, 'text': 'Consultez un médecin en cas de symptômes'},
      ];
    } else if (riskLevel.toLowerCase() == 'moyen') {
      return [
        {'icon': Icons.medical_services_outlined, 'text': 'Consultez un professionnel de santé'},
        {'icon': Icons.calendar_today_outlined, 'text': 'Surveillez vos symptômes quotidiennement'},
        {'icon': Icons.phone_outlined, 'text': 'Contactez votre médecin si aggravation'},
      ];
    } else {
      return [
        {'icon': Icons.emergency_outlined, 'text': 'Consultez rapidement un professionnel de santé'},
        {'icon': Icons.warning_amber_outlined, 'text': 'Évitez les efforts physiques intenses'},
        {'icon': Icons.local_hospital_outlined, 'text': 'Rendez-vous aux urgences si difficultés respiratoires'},
      ];
    }
  }
}
