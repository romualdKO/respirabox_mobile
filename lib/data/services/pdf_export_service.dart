import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/test_result_model.dart';

/// Service d'export PDF — génère un rapport médical structuré
class PdfExportService {
  static Future<Uint8List> generateReport({
    required TestResultModel test,
    required String patientName,
  }) async {
    final pdf = pw.Document();

    final riskColor = test.riskLevel == RiskLevel.low
        ? PdfColors.green700
        : test.riskLevel == RiskLevel.medium
            ? PdfColors.orange700
            : PdfColors.red700;

    final riskText = test.riskLevel == RiskLevel.low
        ? 'FAIBLE'
        : test.riskLevel == RiskLevel.medium
            ? 'MODÉRÉ'
            : 'ÉLEVÉ';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) => [
          // En-tête
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#4DB6AC'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RespiraBox',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Rapport d\'Analyse Respiratoire',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      _formatDate(test.testDate),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 11,
                      ),
                    ),
                    pw.Text(
                      _formatTime(test.testDate),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Informations patient
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: _infoRow('Patient', patientName),
                ),
                pw.Expanded(
                  child: _infoRow('ID Test', test.id.substring(0, 12)),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Score de risque
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex(
                test.riskLevel == RiskLevel.low
                    ? '#E8F5E9'
                    : test.riskLevel == RiskLevel.medium
                        ? '#FFF3E0'
                        : '#FFEBEE',
              ),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: riskColor),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Niveau de risque',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      riskText,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Score',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${test.riskScore}/100',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Mesures vitales
          pw.Text(
            'Mesures vitales',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5F5')),
                children: [
                  _tableHeader('Mesure'),
                  _tableHeader('Valeur'),
                  _tableHeader('Statut'),
                  _tableHeader('Norme'),
                ],
              ),
              pw.TableRow(children: [
                _tableCell('SpO2'),
                _tableCell('${test.spo2.round()}%'),
                _tableCell(
                  test.spo2 >= 95 ? 'Normal' : 'Bas',
                  color: test.spo2 >= 95 ? PdfColors.green700 : PdfColors.red700,
                ),
                _tableCell('≥ 95%'),
              ]),
              pw.TableRow(children: [
                _tableCell('Fréq. cardiaque'),
                _tableCell('${test.heartRate} bpm'),
                _tableCell(
                  (test.heartRate >= 60 && test.heartRate <= 100) ? 'Normal' : 'Anormal',
                  color: (test.heartRate >= 60 && test.heartRate <= 100)
                      ? PdfColors.green700
                      : PdfColors.orange700,
                ),
                _tableCell('60-100 bpm'),
              ]),
              pw.TableRow(children: [
                _tableCell('Température'),
                _tableCell('${test.temperature.toStringAsFixed(1)}°C'),
                _tableCell(
                  test.temperature < 37.5 ? 'Normal' : test.temperature < 38.5 ? 'Fièvre légère' : 'Fièvre',
                  color: test.temperature < 37.5
                      ? PdfColors.green700
                      : test.temperature < 38.5
                          ? PdfColors.orange700
                          : PdfColors.red700,
                ),
                _tableCell('< 37.5°C'),
              ]),
            ],
          ),

          pw.SizedBox(height: 20),

          // Recommandations
          if (test.diagnostic?.recommendations.isNotEmpty == true) ...[
            pw.Text(
              'Recommandations',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            ...test.diagnostic!.recommendations.map(
              (rec) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: pw.TextStyle(color: PdfColor.fromHex('#4DB6AC'))),
                    pw.Expanded(
                      child: pw.Text(rec, style: const pw.TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Avertissement médical
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.amber300),
            ),
            child: pw.Text(
              '⚠️ Ce rapport est généré automatiquement à des fins de dépistage uniquement. '
              'Il ne remplace pas une consultation médicale professionnelle.',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.brown700,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _tableCell(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: color != null ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }
}
