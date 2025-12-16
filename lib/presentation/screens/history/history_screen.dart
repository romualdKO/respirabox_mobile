import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

/// 📜 ÉCRAN D'HISTORIQUE DES TESTS
/// Affiche tous les tests effectués avec filtres et recherche
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Tous';
  final List<String> _filters = ['Tous', 'Faible', 'Moyen', 'Élevé'];

  // Données simulées
  final List<Map<String, dynamic>> _testHistory = [
    {
      'date': '16 Déc 2025',
      'time': '14:30',
      'spo2': 98,
      'heartRate': 75,
      'temperature': 36.8,
      'riskLevel': 'Faible',
      'riskScore': 92,
    },
    {
      'date': '14 Déc 2025',
      'time': '09:15',
      'spo2': 94,
      'heartRate': 82,
      'temperature': 37.1,
      'riskLevel': 'Moyen',
      'riskScore': 65,
    },
    {
      'date': '10 Déc 2025',
      'time': '16:45',
      'spo2': 97,
      'heartRate': 72,
      'temperature': 36.6,
      'riskLevel': 'Faible',
      'riskScore': 88,
    },
    {
      'date': '08 Déc 2025',
      'time': '11:20',
      'spo2': 96,
      'heartRate': 78,
      'temperature': 36.9,
      'riskLevel': 'Faible',
      'riskScore': 90,
    },
    {
      'date': '05 Déc 2025',
      'time': '15:30',
      'spo2': 92,
      'heartRate': 88,
      'temperature': 37.3,
      'riskLevel': 'Moyen',
      'riskScore': 58,
    },
    {
      'date': '01 Déc 2025',
      'time': '10:00',
      'spo2': 98,
      'heartRate': 70,
      'temperature': 36.7,
      'riskLevel': 'Faible',
      'riskScore': 95,
    },
  ];

  List<Map<String, dynamic>> get _filteredTests {
    if (_selectedFilter == 'Tous') {
      return _testHistory;
    }
    return _testHistory
        .where((test) => test['riskLevel'] == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
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
                        '${_filteredTests.length} test${_filteredTests.length > 1 ? 's' : ''}',
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
            _buildStatsSummary(),
            const SizedBox(height: 20),

            // Liste des tests
            Expanded(
              child: _filteredTests.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredTests.length,
                      itemBuilder: (context, index) {
                        final test = _filteredTests[index];
                        return _buildTestCard(test);
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

  Widget _buildStatsSummary() {
    final avgSpo2 = (_testHistory.fold<int>(
              0,
              (sum, test) => sum + (test['spo2'] as int),
            ) /
            _testHistory.length)
        .round();

    final avgHeartRate = (_testHistory.fold<int>(
              0,
              (sum, test) => sum + (test['heartRate'] as int),
            ) /
            _testHistory.length)
        .round();

    final lowRiskCount =
        _testHistory.where((t) => t['riskLevel'] == 'Faible').length;

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
                        // TODO: Export PDF
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fonctionnalité à venir')),
                        );
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
}
