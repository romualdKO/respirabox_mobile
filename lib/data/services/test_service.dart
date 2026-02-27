import 'package:cloud_firestore/cloud_firestore.dart';
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
      print('🔍 Récupération tests pour userId: $userId');

      final querySnapshot = await _testsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('testDate', descending: true)
          .get();

      print('📊 Nombre de tests trouvés: ${querySnapshot.docs.length}');

      // Afficher détails des tests
      if (querySnapshot.docs.isNotEmpty) {
        print('✅ Tests récupérés:');
        for (var i = 0; i < querySnapshot.docs.length && i < 3; i++) {
          final doc = querySnapshot.docs[i];
          final data = doc.data() as Map<String, dynamic>;
          print('   Test ${i + 1}:');
          print('     - ID: ${doc.id}');
          print('     - Date: ${data['testDate']}');
          print('     - SpO2: ${data['spo2']}%');
          print('     - FC: ${data['heartRate']} bpm');
          print('     - Score: ${data['riskScore']}');
        }
        if (querySnapshot.docs.length > 3) {
          print('   ... et ${querySnapshot.docs.length - 3} autres');
        }
      } else {
        print('⚠️ Aucun test trouvé pour cet utilisateur dans Firestore!');
        print('   Vérifiez que userId correspond aux tests sauvegardés.');
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
      print('🔍 Récupération des $limit derniers tests pour userId: $userId');

      final querySnapshot = await _testsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('testDate', descending: true)
          .limit(limit)
          .get();

      print('📊 Tests récents trouvés: ${querySnapshot.docs.length}');

      // Debug: afficher les IDs des tests
      if (querySnapshot.docs.isNotEmpty) {
        print('✅ IDs des tests:');
        for (var doc in querySnapshot.docs) {
          print('   - ${doc.id}');
        }
      } else {
        print('⚠️ Aucun test récent trouvé!');
      }

      return querySnapshot.docs
          .map((doc) => TestResultModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      print('❌ Erreur récupération tests récents: $e');
      print('Stack: $stackTrace');
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

  /// 📊 RÉCUPÉRER LES STATISTIQUES
  Future<TestStatistics> getUserStatistics(String userId) async {
    try {
      final tests = await getUserTests(userId);

      if (tests.isEmpty) {
        return TestStatistics(
          totalTests: 0,
          averageScore: 0,
          lastTestDate: null,
          improvementRate: 0,
        );
      }

      final totalTests = tests.length;
      final averageScore =
          tests.map((t) => t.riskScore).reduce((a, b) => a + b) / totalTests;
      final lastTestDate = tests.first.testDate;

      // Calcul du taux d'amélioration (comparison premier vs dernier test)
      double improvementRate = 0;
      if (tests.length >= 2) {
        final firstScore = tests.last.riskScore;
        final lastScore = tests.first.riskScore;
        improvementRate = ((firstScore - lastScore) / firstScore) * 100;
      }

      return TestStatistics(
        totalTests: totalTests,
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
