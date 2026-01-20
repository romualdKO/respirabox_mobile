import 'package:cloud_firestore/cloud_firestore.dart';

/// 🫁 MODÈLE RÉSULTAT DE TEST RESPIRATOIRE
/// Contient toutes les données d'un test effectué avec le boîtier RespiraBox
class TestResultModel {
  final String id;
  final String userId; // ID de l'utilisateur ayant effectué le test
  final String deviceId; // ID du boîtier RespiraBox utilisé
  final DateTime testDate;

  // 📊 Données vitales mesurées
  final double spo2; // Saturation en oxygène (%)
  final int heartRate; // Fréquence cardiaque (BPM)
  final double temperature; // Température corporelle (°C)

  // 🎙️ Données audio
  final String audioFileUrl; // URL du fichier audio (Firebase Storage)
  final int audioDuration; // Durée de l'enregistrement (secondes)
  final String audioQuality; // 'good', 'medium', 'poor'

  // 🤖 Analyse IA
  final DiagnosticResult? diagnostic;
  final int riskScore; // Score de risque global (0-100)
  final RiskLevel riskLevel; // Niveau de risque

  // 📝 Métadonnées
  final TestStatus status;
  final String? notes; // Notes du médecin ou du patient
  final bool isSharedWithDoctor;
  final DateTime createdAt;
  final DateTime updatedAt;

  TestResultModel({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.testDate,
    required this.spo2,
    required this.heartRate,
    required this.temperature,
    required this.audioFileUrl,
    required this.audioDuration,
    required this.audioQuality,
    this.diagnostic,
    required this.riskScore,
    required this.riskLevel,
    this.status = TestStatus.completed,
    this.notes,
    this.isSharedWithDoctor = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Conversion depuis Firestore
  factory TestResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestResultModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      deviceId: data['deviceId'] ?? '',
      testDate: (data['testDate'] as Timestamp).toDate(),
      spo2: (data['spo2'] ?? 0).toDouble(),
      heartRate: data['heartRate'] ?? 0,
      temperature: (data['temperature'] ?? 0).toDouble(),
      audioFileUrl: data['audioFileUrl'] ?? '',
      audioDuration: data['audioDuration'] ?? 0,
      audioQuality: data['audioQuality'] ?? 'medium',
      diagnostic: data['diagnostic'] != null
          ? DiagnosticResult.fromMap(data['diagnostic'])
          : null,
      riskScore: data['riskScore'] ?? 0,
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.toString() == 'RiskLevel.${data['riskLevel']}',
        orElse: () => RiskLevel.low,
      ),
      status: TestStatus.values.firstWhere(
        (e) => e.toString() == 'TestStatus.${data['status']}',
        orElse: () => TestStatus.completed,
      ),
      notes: data['notes'],
      isSharedWithDoctor: data['isSharedWithDoctor'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'deviceId': deviceId,
      'testDate': Timestamp.fromDate(testDate),
      'spo2': spo2,
      'heartRate': heartRate,
      'temperature': temperature,
      'audioFileUrl': audioFileUrl,
      'audioDuration': audioDuration,
      'audioQuality': audioQuality,
      'diagnostic': diagnostic?.toMap(),
      'riskScore': riskScore,
      'riskLevel': riskLevel.toString().split('.').last,
      'status': status.toString().split('.').last,
      'notes': notes,
      'isSharedWithDoctor': isSharedWithDoctor,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copie avec modification
  TestResultModel copyWith({
    String? id,
    String? userId,
    String? deviceId,
    DateTime? testDate,
    double? spo2,
    int? heartRate,
    double? temperature,
    String? audioFileUrl,
    int? audioDuration,
    String? audioQuality,
    DiagnosticResult? diagnostic,
    int? riskScore,
    RiskLevel? riskLevel,
    TestStatus? status,
    String? notes,
    bool? isSharedWithDoctor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TestResultModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      testDate: testDate ?? this.testDate,
      spo2: spo2 ?? this.spo2,
      heartRate: heartRate ?? this.heartRate,
      temperature: temperature ?? this.temperature,
      audioFileUrl: audioFileUrl ?? this.audioFileUrl,
      audioDuration: audioDuration ?? this.audioDuration,
      audioQuality: audioQuality ?? this.audioQuality,
      diagnostic: diagnostic ?? this.diagnostic,
      riskScore: riskScore ?? this.riskScore,
      riskLevel: riskLevel ?? this.riskLevel,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isSharedWithDoctor: isSharedWithDoctor ?? this.isSharedWithDoctor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 🤖 RÉSULTAT DU DIAGNOSTIC IA
class DiagnosticResult {
  final String tuberculosisRisk; // Pourcentage de risque de tuberculose
  final String pneumoniaRisk; // Pourcentage de risque de pneumonie
  final List<String> symptoms; // Symptômes détectés
  final String interpretation; // Interprétation textuelle du résultat
  final List<String> recommendations; // Recommandations pour le patient

  DiagnosticResult({
    required this.tuberculosisRisk,
    required this.pneumoniaRisk,
    required this.symptoms,
    required this.interpretation,
    required this.recommendations,
  });

  factory DiagnosticResult.fromMap(Map<String, dynamic> map) {
    return DiagnosticResult(
      tuberculosisRisk: map['tuberculosisRisk'] ?? '0%',
      pneumoniaRisk: map['pneumoniaRisk'] ?? '0%',
      symptoms: List<String>.from(map['symptoms'] ?? []),
      interpretation: map['interpretation'] ?? '',
      recommendations: List<String>.from(map['recommendations'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tuberculosisRisk': tuberculosisRisk,
      'pneumoniaRisk': pneumoniaRisk,
      'symptoms': symptoms,
      'interpretation': interpretation,
      'recommendations': recommendations,
    };
  }
}

/// 📊 NIVEAU DE RISQUE
enum RiskLevel {
  low, // Risque faible (0-33)
  medium, // Risque moyen (34-66)
  high, // Risque élevé (67-100)
}

/// 📋 STATUT DU TEST
enum TestStatus {
  pending, // En attente
  inProgress, // En cours
  completed, // Terminé
  failed, // Échec
  cancelled, // Annulé
}
