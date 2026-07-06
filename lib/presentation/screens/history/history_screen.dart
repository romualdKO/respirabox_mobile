import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/test_result_model.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/trend_chart_widget.dart';

/// 📜 ÉCRAN D'HISTORIQUE DES TESTS
/// Affiche tous les tests effectués avec filtres et recherche
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedFilter = 'Tous';
  final List<String> _filters = ['Tous', 'Faible', 'Moyen', 'Élevé'];

  @override
  Widget build(BuildContext context) {
    // Récupérer l'utilisateur courant
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: const Center(child: Text('Utilisateur non connecté')),
          );
        }

        final testsAsync = ref.watch(userTestsProvider(user.id));

        return testsAsync.when(
          data: (allTests) {
            // Filtrer les tests selon le filtre sélectionné
            final filteredTests = _selectedFilter == 'Tous'
                ? allTests
                : allTests.where((test) {
                    final riskText = test.riskLevel == RiskLevel.low
                        ? 'Faible'
                        : test.riskLevel == RiskLevel.medium
                            ? 'Moyen'
                            : 'Élevé';
                    return riskText == _selectedFilter;
                  }).toList();

            return _buildHistoryContent(filteredTests, allTests);
          },
          loading: () => Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Center(child: Text('Erreur: $error')),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildHistoryContent(List tests, List<TestResultModel> allTests) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête avec titre
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Historique', style: AppTextStyles.h2),
                      const SizedBox(height: 4),
                      Text(
                        '${tests.length} test${tests.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => _showFilterBottomSheet(),
                  ),
                ],
              ),
            ),

            // Filtres rapides
            _buildQuickFilters(),
            const SizedBox(height: 10),

            // Statistiques résumées
            _buildStatsSummary(tests)
                .animate()
                .fadeIn(delay: 100.ms, duration: 350.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: 16),

            // Graphique de tendances
            if (allTests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TrendChartWidget(tests: allTests),
              ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
            const SizedBox(height: 16),

            // Liste des tests
            Expanded(
              child: tests.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: tests.length,
                      itemBuilder: (context, index) {
                        final test = tests[index];
                        return _buildTestCardFromModel(test)
                            .animate()
                            .fadeIn(delay: (40 * index).ms, duration: 300.ms)
                            .slideY(begin: 0.06, end: 0);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.divider,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSummary(List tests) {
    if (tests.isEmpty) {
      return const SizedBox.shrink();
    }

    final avgSpo2 = (tests.fold<double>(
              0.0,
              (sum, test) => sum + (test.spo2 ?? 0.0),
            ) /
            tests.length)
        .round();

    final avgHeartRate = (tests.fold<double>(
              0.0,
              (sum, test) => sum + ((test.heartRate ?? 0).toDouble()),
            ) /
            tests.length)
        .round();

    final lowRiskCount =
        tests.where((t) => t.riskLevel == RiskLevel.low).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.water_drop,
              label: 'SpO2 moyen',
              value: '$avgSpo2%',
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              icon: Icons.favorite,
              label: 'FC moyenne',
              value: '$avgHeartRate',
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle,
              label: 'Risque faible',
              value: '$lowRiskCount',
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showTestDetailsFromModel(
    dynamic test,
    String dateStr,
    String timeStr,
    String riskText,
    Color riskColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Détails du test', style: AppTextStyles.h2),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: riskColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        riskText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Score: ${test.riskScore ?? 0}/100',
                        style: TextStyle(fontSize: 16, color: riskColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow(Icons.calendar_today, 'Date', '$dateStr à $timeStr'),
                const Divider(height: 30),
                Text('Mesures', style: AppTextStyles.h3),
                const SizedBox(height: 15),
                _buildDetailRow(Icons.water_drop, 'Saturation en oxygène (SpO2)', '${(test.spo2 ?? 0).round()}%'),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.favorite, 'Fréquence cardiaque', '${test.heartRate ?? 0} bpm'),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.thermostat, 'Température corporelle', '${test.temperature?.toStringAsFixed(1) ?? '--'}°C'),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _shareTestResultFromModel(test, dateStr, timeStr, riskText);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Partager les résultats'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareTestResultFromModel(
    dynamic test,
    String dateStr,
    String timeStr,
    String riskText,
  ) {
    final message = '''
🫁 RespiraBox - Résultats du test

📅 Date: $dateStr à $timeStr

📊 Niveau de risque: $riskText (Score: ${test.riskScore ?? 0}/100)

📈 Mesures:
• SpO2: ${(test.spo2 ?? 0).round()}%
• Fréquence cardiaque: ${test.heartRate ?? 0} bpm
• Température: ${test.temperature?.toStringAsFixed(1) ?? '--'}°C

---
Application RespiraBox
Dépistage des maladies respiratoires
''';

    Share.share(message, subject: 'Résultats de mon test RespiraBox');
  }

  Widget _buildTestCardFromModel(dynamic test) {
    final riskColor = test.riskLevel == RiskLevel.low
        ? AppColors.success
        : test.riskLevel == RiskLevel.medium
            ? AppColors.warning
            : AppColors.error;

    final riskText = test.riskLevel == RiskLevel.low
        ? 'Faible'
        : test.riskLevel == RiskLevel.medium
            ? 'Moyen'
            : 'Élevé';

    final date = test.testDate;
    final dateStr = '${date.day} ${_getMonthName(date.month)} ${date.year}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTestDetailsFromModel(test, dateStr, timeStr, riskText, riskColor),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.favorite, color: riskColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      riskText,
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    icon: Icons.water_drop,
                    label: 'SpO2',
                    value: '${(test.spo2 ?? 0).round()}%',
                  ),
                  _buildMetric(
                    icon: Icons.favorite,
                    label: 'FC',
                    value: '${test.heartRate ?? 0}',
                  ),
                  _buildMetric(
                    icon: Icons.thermostat,
                    label: 'Temp',
                    value: '${test.temperature?.toStringAsFixed(1) ?? '--'}°C',
                  ),
                  _buildMetric(
                    icon: Icons.score,
                    label: 'Score',
                    value: '${test.riskScore ?? 0}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return months[month - 1];
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.textLight),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            size: 100,
            color: AppColors.primary.withOpacity(0.3),
          ).animate().fadeIn(duration: 400.ms).scale(
              begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack, duration: 500.ms),
          const SizedBox(height: 20),
          Text(
            _selectedFilter == 'Tous'
                ? 'Aucun test effectué'
                : 'Aucun test trouvé',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _selectedFilter == 'Tous'
                  ? 'Connectez le prototype ESP32 RespiraBox\npour effectuer votre premier test respiratoire.'
                  : 'Les tests avec le filtre "$_selectedFilter" apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
            ),
          ),
          if (_selectedFilter == 'Tous') ...[
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Naviguer vers l'écran de connexion ESP32
                Navigator.pushNamed(context, AppRoutes.deviceScan);
              },
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Connecter ESP32'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtrer par niveau de risque', style: AppTextStyles.h3),
            const SizedBox(height: 20),
            ..._filters.map((filter) {
              return ListTile(
                title: Text(filter),
                trailing: _selectedFilter == filter
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textLight),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
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

}

