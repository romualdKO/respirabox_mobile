import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/test_result_model.dart';

/// 🔥 SERVICE FIRESTORE
/// Gère toutes les opérations CRUD avec la base de données Firestore
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 📊 COLLECTIONS
  static const String usersCollection = 'users';
  static const String testsCollection = 'tests';
  static const String devicesCollection = 'devices';

  /// 💾 SAUVEGARDER UN RÉSULTAT DE TEST
  Future<String> saveTestResult(TestResultModel testResult) async {
    try {
      final docRef = await _firestore
          .collection(testsCollection)
          .add(testResult.toFirestore());
      return docRef.id;
    } catch (e) {
      throw 'Erreur lors de la sauvegarde du test: $e';
    }
  }

  /// 📖 RÉCUPÉRER UN RÉSULTAT DE TEST PAR ID
  Future<TestResultModel?> getTestResult(String testId) async {
    try {
      final doc =
          await _firestore.collection(testsCollection).doc(testId).get();

      if (doc.exists) {
        return TestResultModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Erreur lors de la récupération du test: $e';
    }
  }

  /// 📋 RÉCUPÉRER TOUS LES TESTS D'UN UTILISATEUR
  Future<List<TestResultModel>> getUserTests(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(testsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('testDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TestResultModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Erreur lors de la récupération des tests: $e';
    }
  }

  /// 🔄 STREAM DES TESTS D'UN UTILISATEUR (temps réel)
  Stream<List<TestResultModel>> getUserTestsStream(String userId) {
    return _firestore
        .collection(testsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('testDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TestResultModel.fromFirestore(doc))
            .toList());
  }

  /// ✏️ METTRE À JOUR UN RÉSULTAT DE TEST
  Future<void> updateTestResult(
      String testId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(testsCollection).doc(testId).update({
        ...updates,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw 'Erreur lors de la mise à jour du test: $e';
    }
  }

  /// 🗑️ SUPPRIMER UN RÉSULTAT DE TEST
  Future<void> deleteTestResult(String testId) async {
    try {
      await _firestore.collection(testsCollection).doc(testId).delete();
    } catch (e) {
      throw 'Erreur lors de la suppression du test: $e';
    }
  }

  /// 📊 OBTENIR LES STATISTIQUES D'UN UTILISATEUR
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      final tests = await getUserTests(userId);

      if (tests.isEmpty) {
        return {
          'totalTests': 0,
          'averageRiskScore': 0,
          'lastTestDate': null,
          'highRiskCount': 0,
          'mediumRiskCount': 0,
          'lowRiskCount': 0,
        };
      }

      // Calculs statistiques
      final totalTests = tests.length;
      final averageRiskScore =
          tests.map((t) => t.riskScore).reduce((a, b) => a + b) / totalTests;
      final lastTestDate = tests.first.testDate;

      final highRiskCount =
          tests.where((t) => t.riskLevel == RiskLevel.high).length;
      final mediumRiskCount =
          tests.where((t) => t.riskLevel == RiskLevel.medium).length;
      final lowRiskCount =
          tests.where((t) => t.riskLevel == RiskLevel.low).length;

      return {
        'totalTests': totalTests,
        'averageRiskScore': averageRiskScore.toInt(),
        'lastTestDate': lastTestDate,
        'highRiskCount': highRiskCount,
        'mediumRiskCount': mediumRiskCount,
        'lowRiskCount': lowRiskCount,
      };
    } catch (e) {
      throw 'Erreur lors du calcul des statistiques: $e';
    }
  }

  /// 🔍 RECHERCHER DES TESTS PAR CRITÈRES
  Future<List<TestResultModel>> searchTests({
    required String userId,
    RiskLevel? riskLevel,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(testsCollection)
          .where('userId', isEqualTo: userId);

      if (riskLevel != null) {
        query = query.where('riskLevel',
            isEqualTo: riskLevel.toString().split('.').last);
      }

      if (startDate != null) {
        query = query.where('testDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('testDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot =
          await query.orderBy('testDate', descending: true).get();

      return querySnapshot.docs
          .map((doc) => TestResultModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Erreur lors de la recherche: $e';
    }
  }

  /// 🔢 COMPTER LES TESTS D'UN UTILISATEUR
  Future<int> countUserTests(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(testsCollection)
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      throw 'Erreur lors du comptage: $e';
    }
  }

  /// 📤 PARTAGER UN TEST AVEC UN MÉDECIN
  Future<void> shareTestWithDoctor(String testId, bool share) async {
    try {
      await _firestore.collection(testsCollection).doc(testId).update({
        'isSharedWithDoctor': share,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw 'Erreur lors du partage: $e';
    }
  }
}
