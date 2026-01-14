import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/test_result_model.dart';
import '../../data/services/test_service.dart';

/// 📊 PROVIDER TESTS RESPIRATOIRES
/// Gère l'état des tests dans l'application

// Provider TestService
final testServiceProvider = Provider<TestService>((ref) {
  return TestService();
});

// Provider liste des tests utilisateur
final userTestsProvider = StreamProvider.autoDispose.family<List<TestResult>, String>((ref, userId) {
  final testService = ref.watch(testServiceProvider);
  return testService.watchUserTests(userId);
});

// Provider tests récents (dernier mois)
final recentTestsProvider = FutureProvider.autoDispose.family<List<TestResult>, String>((ref, userId) async {
  final testService = ref.watch(testServiceProvider);
  return testService.getRecentTests(userId, limit: 10);
});

// Provider statistiques utilisateur
final userStatsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, userId) async {
  final testService = ref.watch(testServiceProvider);
  return testService.getUserStatistics(userId);
});

// Provider test par ID
final testByIdProvider = FutureProvider.autoDispose.family<TestResult?, String>((ref, testId) async {
  final testService = ref.watch(testServiceProvider);
  return testService.getTestById(testId);
});

// Provider pour sauvegarder un test
final saveTestProvider = Provider<Future<void> Function(TestResult)>((ref) {
  final testService = ref.watch(testServiceProvider);
  return (TestResult test) async {
    await testService.saveTest(test);
    // Invalider le cache des tests pour forcer le rechargement
    ref.invalidate(userTestsProvider);
    ref.invalidate(recentTestsProvider);
    ref.invalidate(userStatsProvider);
  };
});
