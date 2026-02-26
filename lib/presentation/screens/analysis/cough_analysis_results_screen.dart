import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../widgets/disease_risk_comparison_chart.dart';

/// 🩺 ÉCRAN RÉSULTATS ANALYSE TOUX
///
/// Affiche:
/// - Graphique comparaison TB vs Pneumonie
/// - Caractéristiques de la toux (type, intensité)
/// - Features acoustiques (fréquence, énergie, ZCR)
/// - Recommandations personnalisées avec urgence
/// - Actions suggérées
class CoughAnalysisResultsScreen extends StatelessWidget {
  const CoughAnalysisResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Récupérer les résultats d'analyse
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};

    if (args.isEmpty || args['hasCough'] == null) {
      return _buildErrorScreen(context, 'Aucune donnée d\'analyse disponible');
    }

    final hasCough = args['hasCough'] as bool? ?? false;

    if (!hasCough) {
      return _buildNoCoughScreen(context);
    }

    final coughType = args['type'] as String? ?? 'non défini';
    final intensity = args['intensity'] as String? ?? 'non défini';
    final tbRisk = args['tbRisk'] as int? ?? 0;
    final pneumoniaRisk = args['pneumoniaRisk'] as int? ?? 0;
    final urgencyLevel = args['urgencyLevel'] as String? ?? 'low';
    final recommendation = args['recommendation'] as String? ?? '';
    final actions = (args['actions'] as List?)?.cast<String>() ?? [];
    final wetnessProbability = args['wetnessProbability'] as double? ?? 0.0;

    final urgencyColor = _getUrgencyColor(urgencyLevel);
    final urgencyLabel = _getUrgencyLabel(urgencyLevel);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analyse de Toux',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textDark),
            onPressed: () => _shareResults(context, args),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🚨 NIVEAU D'URGENCE
              _buildUrgencyBanner(urgencyLabel, urgencyColor),
              const SizedBox(height: 24),

              // 📊 GRAPHIQUE COMPARAISON MALADIES
              DiseaseRiskComparisonChart(
                coughAnalysis: args,
                height: 280,
              ),
              const SizedBox(height: 24),

              // 🎯 CARACTÉRISTIQUES TOUX
              Text('Caractéristiques de la Toux', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              _buildCoughCharacteristics(
                  coughType, intensity, wetnessProbability),
              const SizedBox(height: 24),

              // 🎵 FEATURES ACOUSTIQUES (si disponibles)
              if (args['acousticFeatures'] != null) ...[
                Text('Analyse Acoustique', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                _buildAcousticFeatures(
                    args['acousticFeatures'] as Map<String, dynamic>),
                const SizedBox(height: 24),
              ],

              // 💡 RECOMMANDATIONS
              Text('Recommandations', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              _buildRecommendationCard(recommendation, urgencyColor),
              const SizedBox(height: 16),

              // ✅ ACTIONS SUGGÉRÉES
              if (actions.isNotEmpty) ...[
                Text('Actions à Entreprendre', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                _buildActionsList(actions, urgencyLevel),
                const SizedBox(height: 24),
              ],

              // 🚨 AVERTISSEMENT MÉDICAL
              _buildMedicalDisclaimer(),
              const SizedBox(height: 30),

              // 🔘 BOUTONS ACTIONS
              _buildActionButtons(context, urgencyLevel),
            ],
          ),
        ),
      ),
    );
  }

  /// 🚨 BANNIÈRE URGENCE
  Widget _buildUrgencyBanner(String label, Color color) {
    IconData icon;
    switch (label.toLowerCase()) {
      case 'urgent':
        icon = Icons.emergency;
        break;
      case 'élevé':
        icon = Icons.warning;
        break;
      case 'moyen':
        icon = Icons.info;
        break;
      default:
        icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Niveau d\'Urgence: $label',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label == 'URGENT'
                      ? 'Consultation médicale immédiate recommandée'
                      : label == 'Élevé'
                          ? 'Consulter un médecin dans les 24-48h'
                          : label == 'Moyen'
                              ? 'Surveillance et consultation si aggravation'
                              : 'Continuer surveillance, repos et hydratation',
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 CARACTÉRISTIQUES TOUX
  Widget _buildCoughCharacteristics(
      String type, String intensity, double wetness) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCharacteristicRow('Type', type, _getCoughTypeIcon(type)),
            const Divider(height: 24),
            _buildCharacteristicRow('Intensité', intensity, Icons.volume_up),
            const Divider(height: 24),
            _buildCharacteristicRow(
              'Mucosité',
              '${(wetness * 100).toInt()}%',
              wetness > 0.6 ? Icons.water_drop : Icons.air,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristicRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _getCoughTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'sèche':
        return Icons.air;
      case 'grasse':
        return Icons.water_drop;
      case 'productive':
        return Icons.bubble_chart;
      default:
        return Icons.healing;
    }
  }

  /// 🎵 FEATURES ACOUSTIQUES
  Widget _buildAcousticFeatures(Map<String, dynamic> features) {
    final frequency = features['frequency'] as double? ?? 0.0;
    final energy = features['energy'] as double? ?? 0.0;
    final zcr = features['zeroCrossingRate'] as double? ?? 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFeatureRow('Fréquence', '${frequency.toStringAsFixed(0)} Hz',
                Icons.graphic_eq),
            const SizedBox(height: 12),
            _buildFeatureRow(
                'Énergie', '${(energy * 100).toStringAsFixed(0)}%', Icons.bolt),
            const SizedBox(height: 12),
            _buildFeatureRow('ZCR', zcr.toStringAsFixed(3), Icons.waves),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 💡 CARTE RECOMMANDATION
  Widget _buildRecommendationCard(String recommendation, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.05), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                recommendation,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ LISTE ACTIONS
  Widget _buildActionsList(List<String> actions, String urgency) {
    final color = _getUrgencyColor(urgency);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: actions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      action,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// ⚠️ DISCLAIMER MÉDICAL
  Widget _buildMedicalDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Cette analyse est un outil d\'aide à la décision. '
              'Elle ne remplace pas l\'avis d\'un professionnel de santé.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔘 BOUTONS ACTIONS
  Widget _buildActionButtons(BuildContext context, String urgency) {
    return Column(
      children: [
        if (urgency == 'urgent' || urgency == 'high')
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Naviguer vers prise de rendez-vous ou appel urgence
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Fonction à implémenter: Appel urgence')),
              );
            },
            icon: const Icon(Icons.phone),
            label: Text(
              urgency == 'urgent'
                  ? 'Appeler SAMU (185)'
                  : 'Prendre Rendez-vous',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: urgency == 'urgent' ? Colors.red : Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.home),
          label: const Text('Retour à l\'accueil'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  /// ❌ ÉCRAN ERREUR
  Widget _buildErrorScreen(BuildContext context, String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erreur'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🚫 ÉCRAN PAS DE TOUX
  Widget _buildNoCoughScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 80, color: Colors.green.shade400),
              const SizedBox(height: 20),
              const Text(
                'Aucune toux détectée',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'L\'analyse audio n\'a pas détecté de toux significative.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 COULEURS URGENCE
  Color _getUrgencyColor(String level) {
    switch (level.toLowerCase()) {
      case 'urgent':
        return Colors.red.shade700;
      case 'high':
        return Colors.deepOrange.shade600;
      case 'medium':
        return Colors.orange.shade600;
      default:
        return Colors.green.shade600;
    }
  }

  String _getUrgencyLabel(String level) {
    switch (level.toLowerCase()) {
      case 'urgent':
        return 'URGENT';
      case 'high':
        return 'Élevé';
      case 'medium':
        return 'Moyen';
      default:
        return 'Faible';
    }
  }

  /// 📤 PARTAGE RÉSULTATS
  void _shareResults(BuildContext context, Map<String, dynamic> analysis) {
    final tbRisk = analysis['tbRisk'] ?? 0;
    final pneumoniaRisk = analysis['pneumoniaRisk'] ?? 0;
    final type = analysis['type'] ?? 'non défini';
    final urgency = analysis['urgencyLevel'] ?? 'low';

    final text = '''
📊 Résultats Analyse Toux - RespiraBox

Type de toux: $type
Risque Tuberculose: $tbRisk/100
Risque Pneumonie: $pneumoniaRisk/100
Niveau urgence: ${_getUrgencyLabel(urgency)}

⚠️ Cette analyse ne remplace pas un diagnostic médical professionnel.

Généré par RespiraBox Mobile
''';

    Share.share(text, subject: 'Résultats Analyse Toux');
  }
}
