import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/providers/app_providers.dart';

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

        // Charger les tests de l'utilisateur
        final testsAsync = ref.watch(recentTestsProvider(user.id));

        return testsAsync.when(
          data: (allTests) {
            // Filtrer les tests selon le filtre sélectionné
            final filteredTests = _selectedFilter == 'Tous'
                ? allTests
                : allTests.where((test) {
                    final riskText = test.riskLevel == 'low'
                        ? 'Faible'
                        : test.riskLevel == 'moderate'
                            ? 'Moyen'
                            : 'Élevé';
                    return riskText == _selectedFilter;
                  }).toList();

            return _buildHistoryContent(filteredTests);
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

  Widget _buildHistoryContent(List tests) {
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
            _buildStatsSummary(tests),
            const SizedBox(height: 20),

            // Liste des tests
            Expanded(
              child: tests.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: tests.length,
                      itemBuilder: (context, index) {
                        final test = tests[index];
                        return _buildTestCardFromModel(test);
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
        tests.where((t) => t.riskLevel == 'low').length;

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

  Widget _buildTestCard(Map<String, dynamic> test) {
    final Color riskColor = _getRiskColor(test['riskLevel']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showTestDetails(test),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.favorite,
                            color: riskColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              test['date'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              test['time'],
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                        test['riskLevel'],
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
                      value: '${test['spo2']}%',
                    ),
                    _buildMetric(
                      icon: Icons.favorite,
                      label: 'FC',
                      value: '${test['heartRate']}',
                    ),
                    _buildMetric(
                      icon: Icons.thermostat,
                      label: 'Temp',
                      value: '${test['temperature']}°C',
                    ),
                    _buildMetric(
                      icon: Icons.score,
                      label: 'Score',
                      value: '${test['riskScore']}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestCardFromModel(dynamic test) {
    final riskColor = test.riskLevel == 'low'
        ? AppColors.success
        : test.riskLevel == 'moderate'
            ? AppColors.warning
            : AppColors.error;

    final riskText = test.riskLevel == 'low'
        ? 'Faible'
        : test.riskLevel == 'moderate'
            ? 'Moyen'
            : 'Élevé';

    final date = test.testDate;
    final dateStr = '${date.day} ${_getMonthName(date.month)} ${date.year}';
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigation vers les détails du test
        },
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
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
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
            Icons.history,
            size: 80,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun test trouvé',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Les tests avec ce filtre apparaîtront ici',
            style: TextStyle(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'faible':
        return AppColors.success;
      case 'moyen':
        return AppColors.warning;
      case 'élevé':
        return AppColors.error;
      default:
        return AppColors.info;
    }
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

  void _showTestDetails(Map<String, dynamic> test) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final riskColor = _getRiskColor(test['riskLevel']);
          return SingleChildScrollView(
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
                  
                  // Score de risque
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
                          test['riskLevel'],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Score: ${test['riskScore']}/100',
                          style: TextStyle(
                            fontSize: 16,
                            color: riskColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Date et heure
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Date',
                    '${test['date']} à ${test['time']}',
                  ),
                  const Divider(height: 30),
                  
                  // Métriques
                  Text('Mesures', style: AppTextStyles.h3),
                  const SizedBox(height: 15),
                  _buildDetailRow(
                    Icons.water_drop,
                    'Saturation en oxygène (SpO2)',
                    '${test['spo2']}%',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.favorite,
                    'Fréquence cardiaque',
                    '${test['heartRate']} bpm',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.thermostat,
                    'Température corporelle',
                    '${test['temperature']}°C',
                  ),
                  const SizedBox(height: 30),
                  
                  // Actions
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _shareTestResult(test);
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exporter en PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
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
          );
        },
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

  void _shareTestResult(Map<String, dynamic> test) {
    final message = '''
🫁 RespiraBox - Résultats du test

📅 Date: ${test['date']} ${test['time']}

📊 Score de risque: ${test['score']}/100 (${test['risk']})

📈 Mesures:
• SpO2: ${test['spo2']}
• Fréquence cardiaque: ${test['heartRate']}
• Température: ${test['temperature']}

---
Application RespiraBox
Dépistage des maladies respiratoires
    ''';

    Share.share(
      message,
      subject: 'Résultats de mon test RespiraBox',
    );
  }
}
