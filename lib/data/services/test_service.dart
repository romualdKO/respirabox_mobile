import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/test_result_model.dart';

/// 🧪 SERVICE DE GESTION DES TESTS RESPIRATOIRES
/// Gère la sauvegarde, la récupération et la synchronisation des tests avec Firestore
class TestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection Firestore des tests
  CollectionReference get _testsCollection => _firestore.collection('tests');

  /// 💾 SAUVEGARDER UN TEST
  Future<void> saveTest(TestResultModel test) async {
    try {
      await _testsCollection.doc(test.id).set(test.toFirestore());
    } catch (e) {
      throw 'Erreur lors de la sauvegarde du test: $e';
    }
  }

  /// 📋 RÉCUPÉRER TOUS LES TESTS D'UN UTILISATEUR
  Future<List<TestResultModel>> getUserTests(String userId) async {
    try {
      if (kDebugMode) print('🔍 Récupération tests pour userId: $userId');

      final querySnapshot = await _testsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('testDate', descending: true)
          .get();

      if (kDebugMode) {
        print('📊 Nombre de tests trouvés: ${querySnapshot.docs.length}');
        if (querySnapshot.docs.isNotEmpty) {
          print('✅ Tests récupérés (${querySnapshot.docs.length} total)');
        } else {
          print('⚠️ Aucun test trouvé pour cet utilisateur dans Firestore.');
        }
      }

      return querySnapshot.docs
          .map((doc) => TestResultModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la récupération des tests: $e');
      print('Stack trace: $stackTrace');
      throw 'Erreur lors de la récupération des tests: $e';
    }
  }

  /// 🔍 RÉCUPÉRER UN TEST PAR ID
  Future<TestResultModel?> getTestById(String testId) async {
    try {
      final doc = await _testsCollection.doc(testId).get();

      if (doc.exists) {
        return TestResultModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Erreur lors de la récupération du test: $e';
    }
  }

  /// ✏️ METTRE À JOUR UN TEST
  Future<void> updateTest(TestResultModel test) async {
    try {
      await _testsCollection.doc(test.id).update(test.toFirestore());
    } catch (e) {
      throw 'Erreur lors de la mise à jour du test: $e';
    }
  }

  /// 🗑️ SUPPRIMER UN TEST
  Future<void> deleteTest(String testId) async {
    try {
      await _testsCollection.doc(testId).delete();
    } catch (e) {
      throw 'Erreur lors de la suppression du test: $e';
    }
  }

  /// 📊 RÉCUPÉRER LES DERNIERS TESTS
  Future<List<TestResultModel>> getRecentTests(String userId,
      {int limit = 5}) async {
    try {
      if (kDebugMode) print('🔍 getRecentTests: $limit tests pour $userId');

      final querySnapshot = await _testsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('testDate', descending: true)
          .limit(limit)
          .get();

      if (kDebugMode) print('📊 Tests récents: ${querySnapshot.docs.length}');

      return querySnapshot.docs
          .map((doc) => TestResultModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur récupération tests récents: $e');
      throw 'Erreur lors de la récupération des tests récents: $e';
    }
  }

  /// 📈 RÉCUPÉRER LES TESTS PAR PÉRIODE
  Future<List<TestResultModel>> getTestsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _testsCollection
          .where('userId', isEqualTo: userId)
          .where('testDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('testDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('testDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TestResultModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Erreur lors de la récupération des tests par période: $e';
    }
  }

  /// 🔄 STREAM EN TEMPS RÉEL DES TESTS
  Stream<List<TestResultModel>> watchUserTests(String userId) {
    return _testsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('testDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TestResultModel.fromFirestore(doc))
            .toList());
  }

  /// RÉCUPÉRER LES STATISTIQUES
  /// Utilise deux requêtes ciblées au lieu de charger tous les tests.
  Future<TestStatistics> getUserStatistics(String userId) async {
    try {
      // Requête 1 : Count + dernier test (pour score récent + date)
      final recentSnap = await _testsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('testDate', descending: true)
          .limit(50)  // Limité à 50 pour le calcul de la moyenne
          .get();

      if (recentSnap.docs.isEmpty) {
        return TestStatistics(
          totalTests: 0,
          averageScore: 0,
          lastTestDate: null,
          improvementRate: 0,
        );
      }

      final tests = recentSnap.docs
          .map((doc) => TestResultModel.fromFirestore(doc))
          .toList();

      final totalFetched  = tests.length;
      final averageScore  = tests.map((t) => t.riskScore).reduce((a, b) => a + b) / totalFetched;
      final lastTestDate  = tests.first.testDate;

      // Taux d'amélioration : premier vs dernier test disponible
      double improvementRate = 0;
      if (tests.length >= 2) {
        final firstScore = tests.last.riskScore;
        final lastScore  = tests.first.riskScore;
        if (firstScore > 0) {
          improvementRate = ((firstScore - lastScore) / firstScore) * 100;
        }
      }

      // Requête 2 : Compte total réel (agrégation légère)
      final countSnap = await _testsCollection
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return TestStatistics(
        totalTests: countSnap.count ?? totalFetched,
        averageScore: averageScore,
        lastTestDate: lastTestDate,
        improvementRate: improvementRate,
      );
    } catch (e) {
      throw 'Erreur lors du calcul des statistiques: $e';
    }
  }
}

/// 📊 STATISTIQUES DES TESTS
class TestStatistics {
  final int totalTests;
  final double averageScore;
  final DateTime? lastTestDate;
  final double improvementRate; // Pourcentage d'amélioration

  TestStatistics({
    required this.totalTests,
    required this.averageScore,
    this.lastTestDate,
    required this.improvementRate,
  });
}
