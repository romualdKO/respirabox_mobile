import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../data/models/test_result_model.dart';

/// Widget Score Santé — cercle animé 0-100 basé sur les derniers tests
class HealthScoreWidget extends StatefulWidget {
  final List<TestResultModel> tests;

  const HealthScoreWidget({Key? key, required this.tests}) : super(key: key);

  @override
  State<HealthScoreWidget> createState() => _HealthScoreWidgetState();
}

class _HealthScoreWidgetState extends State<HealthScoreWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final score = _computeScore(widget.tests);
    _animation = Tween<double>(begin: 0, end: score / 100).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(HealthScoreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tests != widget.tests) {
      final score = _computeScore(widget.tests);
      _animation = Tween<double>(
        begin: _animation.value,
        end: score / 100,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _computeScore(List<TestResultModel> tests) {
    if (tests.isEmpty) return 0;
    final recent = tests.take(3).toList();

    final avgSpo2 = recent.map((t) => t.spo2).reduce((a, b) => a + b) / recent.length;
    final avgHR = recent.map((t) => t.heartRate.toDouble()).reduce((a, b) => a + b) / recent.length;
    final avgTemp = recent.map((t) => t.temperature).reduce((a, b) => a + b) / recent.length;
    final avgRisk = recent.map((t) => t.riskScore.toDouble()).reduce((a, b) => a + b) / recent.length;

    // SpO2 40%, HR 20%, Temp 20%, riskScore inversé 20%
    final spo2Score = (((avgSpo2 - 85) / 15).clamp(0.0, 1.0) * 40).round();
    final hrScore = (avgHR >= 60 && avgHR <= 100) ? 20 : 10;
    final tempScore = avgTemp < 37.5 ? 20 : (avgTemp < 38.5 ? 10 : 0);
    final riskScore = ((1 - avgRisk / 100) * 20).round();

    return (spo2Score + hrScore + tempScore + riskScore).clamp(0, 100);
  }

  Color _getColor(int score) {
    if (score >= 70) return AppColors.success;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  String _getLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Bon';
    if (score >= 40) return 'Modéré';
    return 'À surveiller';
  }

  @override
  Widget build(BuildContext context) {
    final score = _computeScore(widget.tests);
    final color = _getColor(score);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final displayScore = (score * _animation.value).round();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: _animation.value,
                      strokeWidth: 10,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$displayScore',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                          height: 1,
                        ),
                      ),
                      Text(
                        '/100',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Score Santé',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _getLabel(score),
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
