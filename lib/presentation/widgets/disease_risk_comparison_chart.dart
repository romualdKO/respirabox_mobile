import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// 📊 GRAPHIQUE COMPARAISON RISQUES TB vs PNEUMONIE
///
/// Affiche un graphique en barres comparant les scores de risque
/// pour la tuberculose et la pneumonie après analyse de toux
///
/// USAGE:
/// ```dart
/// DiseaseRiskComparisonChart(
///   coughAnalysis: analysisResult,
/// )
/// ```
class DiseaseRiskComparisonChart extends StatelessWidget {
  final Map<String, dynamic> coughAnalysis;
  final double height;

  const DiseaseRiskComparisonChart({
    super.key,
    required this.coughAnalysis,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    final diseaseComparison =
        coughAnalysis['diseaseComparison'] as Map<String, dynamic>?;

    if (diseaseComparison == null) {
      return _buildErrorWidget('Données de comparaison non disponibles');
    }

    final tbData = diseaseComparison['tuberculosis'] as Map<String, dynamic>?;
    final pneumoniaData =
        diseaseComparison['pneumonia'] as Map<String, dynamic>?;

    if (tbData == null || pneumoniaData == null) {
      return _buildErrorWidget('Scores manquants');
    }

    final tbScore = (tbData['score'] as num?)?.toDouble() ?? 0.0;
    final pneumoniaScore = (pneumoniaData['score'] as num?)?.toDouble() ?? 0.0;
    final tbPercentage = (tbData['percentage'] as num?)?.toInt() ?? 0;
    final pneumoniaPercentage =
        (pneumoniaData['percentage'] as num?)?.toInt() ?? 0;

    // Hauteur minimale visible pour les barres même à score=0
    final tbBar = tbScore < 3 ? 3.0 : tbScore.clamp(0.0, 100.0);
    final pneumoniaBar = pneumoniaScore < 3 ? 3.0 : pneumoniaScore.clamp(0.0, 100.0);

    // Pas de Card — le parent (_buildDiseaseRiskPrediction) fournit déjà le Card
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 📊 GRAPHIQUE
        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              maxY: 100,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.black87,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final disease =
                        group.x == 0 ? 'Tuberculose' : 'Pneumonie';
                    final score = group.x == 0
                        ? tbScore.toInt()
                        : pneumoniaScore.toInt();
                    return BarTooltipItem(
                      '$disease\n$score/100',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 72,
                    getTitlesWidget: (value, meta) {
                      return _buildBottomTitle(
                        value.toInt(),
                        tbScore,
                        pneumoniaScore,
                        tbPercentage,
                        pneumoniaPercentage,
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 25,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade400, width: 1),
                  left: BorderSide(color: Colors.grey.shade400, width: 1),
                ),
              ),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: tbBar,
                      color: _getRiskColor(tbScore),
                      width: 55,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 100,
                        color: Colors.grey.shade100,
                      ),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: pneumoniaBar,
                      color: _getRiskColor(pneumoniaScore),
                      width: 55,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 100,
                        color: Colors.grey.shade100,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Légende + indicateurs
        _buildLegend(),
        if ((tbData['primaryIndicators'] as List?)?.isNotEmpty == true ||
            (pneumoniaData['primaryIndicators'] as List?)?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          _buildIndicatorsSections(tbData, pneumoniaData),
        ],
      ],
    );
  }

  /// 🏷️ TITRE BAS DU GRAPHIQUE
  Widget _buildBottomTitle(
    int index,
    double tbScore,
    double pneumoniaScore,
    int tbPercentage,
    int pneumoniaPercentage,
  ) {
    final isHighRisk = index == 0 ? tbScore > 50 : pneumoniaScore > 50;
    final score = index == 0 ? tbScore.toInt() : pneumoniaScore.toInt();
    final percentage = index == 0 ? tbPercentage : pneumoniaPercentage;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        // Icône maladie
        Icon(
          index == 0 ? Icons.sick : Icons.air,
          color: _getRiskColor(score.toDouble()),
          size: 24,
        ),
        const SizedBox(height: 4),
        // Nom maladie
        Text(
          index == 0 ? 'Tuberculose' : 'Pneumonie',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _getRiskColor(score.toDouble()),
          ),
          textAlign: TextAlign.center,
        ),
        // Score et pourcentage
        Text(
          '$score/100 ($percentage%)',
          style: TextStyle(
            fontSize: 11,
            color: isHighRisk ? Colors.red.shade700 : Colors.grey.shade600,
            fontWeight: isHighRisk ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 🎯 SECTIONS INDICATEURS
  Widget _buildIndicatorsSections(
    Map<String, dynamic> tbData,
    Map<String, dynamic> pneumoniaData,
  ) {
    final tbIndicators =
        (tbData['primaryIndicators'] as List?)?.cast<String>() ?? [];
    final pneumoniaIndicators =
        (pneumoniaData['primaryIndicators'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LÉGENDE COULEURS
        _buildLegend(),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),

        // INDICATEURS TB
        if (tbIndicators.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.sick,
                  color: _getRiskColor(tbData['score'].toDouble()), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Indicateurs Tuberculose',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tbIndicators.map((indicator) => _buildIndicatorItem(indicator)),
          const SizedBox(height: 16),
        ],

        // INDICATEURS PNEUMONIE
        if (pneumoniaIndicators.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.air,
                  color: _getRiskColor(pneumoniaData['score'].toDouble()),
                  size: 20),
              const SizedBox(width: 8),
              const Text(
                'Indicateurs Pneumonie',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...pneumoniaIndicators
              .map((indicator) => _buildIndicatorItem(indicator)),
        ],
      ],
    );
  }

  /// 🔹 ITEM INDICATEUR
  Widget _buildIndicatorItem(String indicator) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF4CAF50)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              indicator,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 LÉGENDE COULEURS
  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem('Faible', Colors.green.shade600),
        _buildLegendItem('Moyen', Colors.orange.shade600),
        _buildLegendItem('Élevé', Colors.deepOrange.shade700),
        _buildLegendItem('Urgent', Colors.red.shade700),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  /// 🎨 COULEUR SELON NIVEAU RISQUE
  Color _getRiskColor(double score) {
    if (score >= 70) return Colors.red.shade700; // Urgent
    if (score >= 50) return Colors.deepOrange.shade700; // Élevé
    if (score >= 30) return Colors.orange.shade600; // Moyen
    return Colors.green.shade600; // Faible
  }

  /// ❌ WIDGET ERREUR
  Widget _buildErrorWidget(String message) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📊 WIDGET MINI GRAPHIQUE (pour liste résultats)
class DiseaseRiskMiniChart extends StatelessWidget {
  final int tbRisk;
  final int pneumoniaRisk;
  final double height;

  const DiseaseRiskMiniChart({
    super.key,
    required this.tbRisk,
    required this.pneumoniaRisk,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          // TB
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 40,
                  height: height * (tbRisk / 100),
                  decoration: BoxDecoration(
                    color: _getRiskColor(tbRisk.toDouble()),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('TB',
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                Text('$tbRisk%', style: const TextStyle(fontSize: 9)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Pneumonie
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 40,
                  height: height * (pneumoniaRisk / 100),
                  decoration: BoxDecoration(
                    color: _getRiskColor(pneumoniaRisk.toDouble()),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Pneu',
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                Text('$pneumoniaRisk%', style: const TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(double score) {
    if (score >= 70) return Colors.red.shade700;
    if (score >= 50) return Colors.deepOrange.shade700;
    if (score >= 30) return Colors.orange.shade600;
    return Colors.green.shade600;
  }
}
