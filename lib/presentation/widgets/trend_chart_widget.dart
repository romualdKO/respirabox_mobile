import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/colors.dart';
import '../../data/models/test_result_model.dart';

/// Graphique de tendances SpO2/HR/Temp sur N jours
class TrendChartWidget extends StatefulWidget {
  final List<TestResultModel> tests;

  const TrendChartWidget({Key? key, required this.tests}) : super(key: key);

  @override
  State<TrendChartWidget> createState() => _TrendChartWidgetState();
}

class _TrendChartWidgetState extends State<TrendChartWidget> {
  int _selectedDays = 7;
  String _selectedMetric = 'spo2';

  static const _metrics = {
    'spo2':        ('SpO2 %',     AppColors.info),
    'heartRate':   ('Fréq. card.', AppColors.error),
    'temperature': ('Temp. °C',   AppColors.warning),
  };

  List<TestResultModel> _filterTests(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return widget.tests
        .where((t) => t.testDate.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.testDate.compareTo(b.testDate));
  }

  List<FlSpot> _buildSpots(List<TestResultModel> filtered) {
    if (filtered.isEmpty) return [];
    return filtered.asMap().entries.map((entry) {
      final t = entry.value;
      double y;
      switch (_selectedMetric) {
        case 'heartRate':
          y = t.heartRate.toDouble();
          break;
        case 'temperature':
          y = t.temperature;
          break;
        default:
          y = t.spo2.toDouble();
      }
      return FlSpot(entry.key.toDouble(), y);
    }).toList();
  }

  double _minY() {
    switch (_selectedMetric) {
      case 'heartRate':   return 40;
      case 'temperature': return 35;
      default:            return 85;
    }
  }

  double _maxY() {
    switch (_selectedMetric) {
      case 'heartRate':   return 130;
      case 'temperature': return 40;
      default:            return 100;
    }
  }

  String _formatDate(TestResultModel t) {
    return '${t.testDate.day}/${t.testDate.month}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterTests(_selectedDays);
    final spots = _buildSpots(filtered);
    final metricInfo = _metrics[_selectedMetric]!;
    final color = metricInfo.$2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Tendances',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              _DaySelector(
                selected: _selectedDays,
                onChanged: (d) => setState(() => _selectedDays = d),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Sélecteur de métrique
          Row(
            children: _metrics.entries.map((entry) {
              final selected = entry.key == _selectedMetric;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMetric = entry.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? entry.value.$2.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? entry.value.$2 : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      entry.value.$1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        color: selected ? entry.value.$2 : AppColors.textLight,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (spots.isEmpty)
            SizedBox(
              height: 140,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart, size: 40, color: AppColors.divider),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun test sur $_selectedDays jours',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: _minY(),
                  maxY: _maxY(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (_maxY() - _minY()) / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.divider,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: (_maxY() - _minY()) / 4,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textLight),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: filtered.length <= 10,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= filtered.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            _formatDate(filtered[idx]),
                            style: const TextStyle(
                                fontSize: 9, color: AppColors.textLight),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: color,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: spots.length <= 10,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: color,
                          strokeColor: Colors.white,
                          strokeWidth: 1.5,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _DaySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip('7j', 7),
        const SizedBox(width: 6),
        _chip('30j', 30),
      ],
    );
  }

  Widget _chip(String label, int days) {
    final active = selected == days;
    return GestureDetector(
      onTap: () => onChanged(days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : AppColors.textLight,
          ),
        ),
      ),
    );
  }
}
