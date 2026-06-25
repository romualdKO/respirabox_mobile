import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../data/models/test_result_model.dart';
import '../../../data/services/patient_context_service.dart';
import '../../../data/services/cough_analysis_extension.dart';
import '../../../data/services/pdf_export_service.dart';
import '../../widgets/disease_risk_comparison_chart.dart';

/// 📊 ÉCRAN DES RÉSULTATS DU TEST
/// Affiche les résultats détaillés et les recommandations
class TestResultsScreen extends StatelessWidget {
  const TestResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Récupérer les arguments (données du test)
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};
    final dynamic spo2Raw = args['spo2'] ?? 96;
    final dynamic heartRateRaw = args['heartRate'] ?? 75;
    final dynamic temperatureRaw = args['temperature'] ?? 36.8;
    final int spo2 = spo2Raw is double ? spo2Raw.toInt() : (spo2Raw as int);
    final int heartRate = heartRateRaw is double ? heartRateRaw.toInt() : (heartRateRaw as int);
    final double temperature = temperatureRaw is int ? temperatureRaw.toDouble() : (temperatureRaw as double);
    final riskLevel = args['riskLevel'] ?? 'Faible';
    final riskScore = args['riskScore'] ?? 85;

    // Sauvegarder automatiquement les mesures vitales pour analyse toux
    _saveVitalsForCoughAnalysis(
        spo2.toDouble(), heartRate, temperature.toDouble());

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
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.textDark),
            tooltip: 'Exporter PDF',
            onPressed: () => _exportPdf(context, spo2, heartRate, temperature, riskLevel, riskScore),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textDark),
            onPressed: () => _shareResults(
                context, riskLevel, riskScore, spo2, heartRate, temperature),
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

              // 🆕 PRÉDICTION AUTOMATIQUE TB/PNEUMONIE (basée sur mesures vitales)
              _buildDiseaseRiskPrediction(
                  context, spo2, heartRate, temperature),
              const SizedBox(height: 30),

              // 🆕 ANALYSE TOUX APPROFONDIE (optionnelle)
              _buildCoughAnalysisCard(context, spo2, heartRate, temperature),
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
            statusColor:
                heartRate <= 90 ? AppColors.success : AppColors.warning,
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
                child: Icon(rec['icon'] as IconData,
                    color: AppColors.primary, size: 20),
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

  /// 🩺 CARTE ANALYSE TOUX
  Widget _buildCoughAnalysisCard(
    BuildContext context,
    dynamic spo2,
    dynamic heartRate,
    dynamic temperature,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2196F3).withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Color(0xFF2196F3),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analyse de Toux Avancée',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Avec vos mesures vitales récentes',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Vos mesures seront utilisées pour:',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildVitalInfoRow('SpO2: ${spo2}%', Icons.water_drop),
                  _buildVitalInfoRow(
                      'Température: ${temperature}°C', Icons.thermostat),
                  _buildVitalInfoRow('FC: $heartRate bpm', Icons.favorite),
                  const SizedBox(height: 8),
                  const Text(
                    '→ Analyse acoustique (FFT, MFCC)\n→ Scoring TB vs Pneumonie personnalisé\n→ Graphique comparatif avec recommandations',
                    style: TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.chatbot);
                },
                icon: const Icon(Icons.mic),
                label: const Text('Analyser ma toux maintenant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
  }

  Widget _buildVitalInfoRow(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  /// 🩺 PRÉDICTION RISQUE TB/PNEUMONIE BASÉE SUR MESURES VITALES
  /// Analyse SANS audio, uniquement avec SpO2, FC, Température
  Widget _buildDiseaseRiskPrediction(
    BuildContext context,
    dynamic spo2Value,
    dynamic heartRateValue,
    dynamic temperatureValue,
  ) {
    // Conversion sécurisée
    final double spo2 =
        (spo2Value is int) ? spo2Value.toDouble() : (spo2Value as double);
    final int heartRate = (heartRateValue is double)
        ? heartRateValue.toInt()
        : (heartRateValue as int);
    final double temperature = (temperatureValue is int)
        ? temperatureValue.toDouble()
        : (temperatureValue as double);

    // Analyse prédictive basée UNIQUEMENT sur parametres vitaux
    final vitalsPrediction =
        _predictDiseaseRiskFromVitals(spo2, heartRate, temperature);

    final tbScore = vitalsPrediction['tbRisk'] as int;
    final pneumoniaScore = vitalsPrediction['pneumoniaRisk'] as int;
    final tbIndicators = vitalsPrediction['tbIndicators'] as List<String>;
    final pneumoniaIndicators =
        vitalsPrediction['pneumoniaIndicators'] as List<String>;
    final dominantRisk = vitalsPrediction['dominantRisk'] as String;

    // Créer données pour graphique
    final analysisForChart = {
      'diseaseComparison': {
        'tuberculosis': {
          'score': tbScore,
          'percentage':
              (tbScore / (tbScore + pneumoniaScore + 0.01) * 100).toInt(),
          'primaryIndicators': tbIndicators,
        },
        'pneumonia': {
          'score': pneumoniaScore,
          'percentage':
              (pneumoniaScore / (tbScore + pneumoniaScore + 0.01) * 100)
                  .toInt(),
          'primaryIndicators': pneumoniaIndicators,
        },
      },
    };

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade50,
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.purple,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analyse Prédictive TB/Pneumonie',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Basée sur vos paramètres vitaux',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Graphique comparatif
            DiseaseRiskComparisonChart(
              coughAnalysis: analysisForChart,
              height: 250,
            ),
            const SizedBox(height: 20),

            // Résumé
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dominantRisk == 'TB'
                    ? Colors.red.shade50
                    : dominantRisk == 'Pneumonie'
                        ? Colors.blue.shade50
                        : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        dominantRisk == 'Aucun'
                            ? Icons.check_circle
                            : Icons.warning_amber,
                        color: dominantRisk == 'TB'
                            ? Colors.red
                            : dominantRisk == 'Pneumonie'
                                ? Colors.blue
                                : Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dominantRisk == 'Aucun'
                              ? 'Risque faible détecté'
                              : 'Risque $dominantRisk détecté',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (tbIndicators.isNotEmpty) ...[
                    const Text(
                      '🔴 Indicateurs Tuberculose:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...tbIndicators.map((indicator) => Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 4),
                          child: Row(
                            children: [
                              const Text('•', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  indicator,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 8),
                  ],
                  if (pneumoniaIndicators.isNotEmpty) ...[
                    const Text(
                      '🔵 Indicateurs Pneumonie:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...pneumoniaIndicators.map((indicator) => Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 4),
                          child: Row(
                            children: [
                              const Text('•', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  indicator,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Pour une analyse plus précise, enregistrez votre toux ci-dessous',
                            style:
                                TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔬 ALGORITHME PRÉDICTION BASÉE UNIQUEMENT SUR PARAMÈTRES VITAUX
  ///
  /// Utilise les critères cliniques OMS/PNLT pour scoring sans audio
  Map<String, dynamic> _predictDiseaseRiskFromVitals(
    double spo2,
    int heartRate,
    double temperature,
  ) {
    int tbRisk = 0;
    int pneumoniaRisk = 0;
    List<String> tbIndicators = [];
    List<String> pneumoniaIndicators = [];

    // ========================================
    // CRITÈRES TUBERCULOSE (basés sur mesures vitales)
    // ========================================

    // SpO2 bas = compromission respiratoire chronique
    if (spo2 < 90) {
      tbRisk += 30;
      tbIndicators.add('SpO2 critique < 90% (${spo2.toStringAsFixed(1)}%)');
    } else if (spo2 < 92) {
      tbRisk += 25;
      tbIndicators
          .add('SpO2 très bas ${spo2.toStringAsFixed(1)}% (TB avancée)');
    } else if (spo2 < 95) {
      tbRisk += 15;
      tbIndicators.add('SpO2 sous-optimal ${spo2.toStringAsFixed(1)}%');
    }

    // Température modérée persistante (37.5-38.5°C typique TB)
    if (temperature >= 37.5 && temperature <= 38.5) {
      tbRisk += 20;
      tbIndicators.add(
          'Fièvre modérée persistante ${temperature.toStringAsFixed(1)}°C (profil TB)');
    } else if (temperature > 37.0 && temperature < 37.5) {
      tbRisk += 10;
      tbIndicators.add(
          'Température légèrement élevée ${temperature.toStringAsFixed(1)}°C');
    }

    // Fréquence cardiaque (TB: tachycardie modérée chronique)
    if (heartRate >= 85 && heartRate <= 105) {
      tbRisk += 10;
      tbIndicators.add('FC modérément élevée $heartRate bpm');
    }

    // ========================================
    // CRITÈRES PNEUMONIE (basés sur mesures vitales)
    // ========================================

    // SpO2 très bas = détresse respiratoire aiguë (pneumonie sévère)
    if (spo2 < 88) {
      pneumoniaRisk += 40;
      pneumoniaIndicators.add('🚨 SpO2 critique < 88% - URGENCE MÉDICALE');
    } else if (spo2 < 90) {
      pneumoniaRisk += 35;
      pneumoniaIndicators.add(
          'SpO2 très bas ${spo2.toStringAsFixed(1)}% (détresse respiratoire)');
    } else if (spo2 < 93) {
      pneumoniaRisk += 25;
      pneumoniaIndicators.add(
          'SpO2 bas ${spo2.toStringAsFixed(1)}% (oxygénothérapie nécessaire)');
    } else if (spo2 < 95) {
      pneumoniaRisk += 15;
      pneumoniaIndicators.add('SpO2 limite ${spo2.toStringAsFixed(1)}%');
    }

    // Fièvre élevée aiguë (>38.5°C typique pneumonie bactérienne)
    if (temperature > 39.0) {
      pneumoniaRisk += 35;
      pneumoniaIndicators.add(
          '🔥 Fièvre élevée ${temperature.toStringAsFixed(1)}°C (infection aiguë)');
    } else if (temperature > 38.5) {
      pneumoniaRisk += 30;
      pneumoniaIndicators.add(
          'Fièvre haute ${temperature.toStringAsFixed(1)}°C (pneumonie probable)');
    } else if (temperature > 37.8) {
      pneumoniaRisk += 15;
      pneumoniaIndicators
          .add('Fièvre modérée ${temperature.toStringAsFixed(1)}°C');
    }

    // Tachycardie importante (>100 bpm = réponse inflammatoire aiguë)
    if (heartRate > 110) {
      pneumoniaRisk += 25;
      pneumoniaIndicators
          .add('Tachycardie importante $heartRate bpm (réponse inflammatoire)');
    } else if (heartRate > 100) {
      pneumoniaRisk += 20;
      pneumoniaIndicators.add('FC élevée $heartRate bpm');
    } else if (heartRate > 90) {
      pneumoniaRisk += 10;
      pneumoniaIndicators.add('FC légèrement élevée $heartRate bpm');
    }

    // Combinaison SpO2 bas + Fièvre élevée + FC élevée = TRIADE PNEUMONIE
    if (spo2 < 93 && temperature > 38.5 && heartRate > 100) {
      pneumoniaRisk += 20;
      pneumoniaIndicators.add('⚠️ TRIADE PNEUMONIE détectée (SpO2+T°+FC)');
    }

    // Clamp scores 0-100
    tbRisk = tbRisk.clamp(0, 100);
    pneumoniaRisk = pneumoniaRisk.clamp(0, 100);

    // Déterminer risque dominant
    String dominantRisk;
    if (tbRisk > 40 && tbRisk > pneumoniaRisk) {
      dominantRisk = 'TB';
    } else if (pneumoniaRisk > 40 && pneumoniaRisk > tbRisk) {
      dominantRisk = 'Pneumonie';
    } else if (tbRisk > 30 || pneumoniaRisk > 30) {
      dominantRisk = tbRisk > pneumoniaRisk ? 'TB' : 'Pneumonie';
    } else {
      dominantRisk = 'Aucun';
    }

    return {
      'tbRisk': tbRisk,
      'pneumoniaRisk': pneumoniaRisk,
      'tbIndicators': tbIndicators,
      'pneumoniaIndicators': pneumoniaIndicators,
      'dominantRisk': dominantRisk,
    };
  }

  /// 💾 Sauvegarder mesures vitales pour analyse toux
  static void _saveVitalsForCoughAnalysis(
    double spo2,
    int heartRate,
    double temperature,
  ) {
    PatientContextService.saveLatestVitals(
      spo2: spo2,
      temperature: temperature,
      heartRate: heartRate,
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
        {
          'icon': Icons.check_circle_outline,
          'text': 'Continuez à surveiller votre santé régulièrement'
        },
        {
          'icon': Icons.sports_outlined,
          'text': 'Maintenez une activité physique régulière'
        },
        {
          'icon': Icons.healing_outlined,
          'text': 'Consultez un médecin en cas de symptômes'
        },
      ];
    } else if (riskLevel.toLowerCase() == 'moyen') {
      return [
        {
          'icon': Icons.medical_services_outlined,
          'text': 'Consultez un professionnel de santé'
        },
        {
          'icon': Icons.calendar_today_outlined,
          'text': 'Surveillez vos symptômes quotidiennement'
        },
        {
          'icon': Icons.phone_outlined,
          'text': 'Contactez votre médecin si aggravation'
        },
      ];
    } else {
      return [
        {
          'icon': Icons.emergency_outlined,
          'text': 'Consultez rapidement un professionnel de santé'
        },
        {
          'icon': Icons.warning_amber_outlined,
          'text': 'Évitez les efforts physiques intenses'
        },
        {
          'icon': Icons.local_hospital_outlined,
          'text': 'Rendez-vous aux urgences si difficultés respiratoires'
        },
      ];
    }
  }

  // Partager les résultats
  static void _shareResults(
    BuildContext context,
    String riskLevel,
    int riskScore,
    int spo2,
    int heartRate,
    double temperature,
  ) {
    final now = DateTime.now();
    final date =
        '${now.day}/${now.month}/${now.year} à ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final message = '''
🫁 RespiraBox - Résultats du test

📅 Date: $date

📊 Score de risque: $riskScore/100 ($riskLevel)

📈 Mesures:
• SpO2: $spo2%
• Fréquence cardiaque: $heartRate bpm
• Température: ${temperature.toStringAsFixed(1)}°C

${_getShareInterpretation(riskLevel)}

---
Application RespiraBox
Dépistage des maladies respiratoires
    ''';

    Share.share(
      message,
      subject: 'Résultats de mon test RespiraBox',
    );
  }

  static Future<void> _exportPdf(
    BuildContext context,
    int spo2,
    int heartRate,
    double temperature,
    String riskLevel,
    int riskScore,
  ) async {
    try {
      final riskEnum = riskLevel.toLowerCase() == 'faible'
          ? RiskLevel.low
          : riskLevel.toLowerCase() == 'moyen'
              ? RiskLevel.medium
              : RiskLevel.high;

      final fakeTest = TestResultModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        deviceId: '',
        testDate: DateTime.now(),
        spo2: spo2.toDouble(),
        heartRate: heartRate,
        temperature: temperature,
        audioFileUrl: '',
        audioDuration: 0,
        audioQuality: 'good',
        riskScore: riskScore,
        riskLevel: riskEnum,
        status: TestStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bytes = await PdfExportService.generateReport(
        test: fakeTest,
        patientName: 'Patient',
      );

      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: 'RespiraBox_Rapport_${DateTime.now().day}-${DateTime.now().month}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur export PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  static String _getShareInterpretation(String riskLevel) {
    if (riskLevel.toLowerCase() == 'faible') {
      return '✅ Vos paramètres respiratoires sont dans les normes.';
    } else if (riskLevel.toLowerCase() == 'moyen') {
      return '⚠️ Certains paramètres nécessitent une surveillance. Consultez un professionnel de santé.';
    } else {
      return '🚨 Score de risque élevé. Consultez rapidement un professionnel de santé.';
    }
  }
}
