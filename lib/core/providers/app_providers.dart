import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/test_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/respirabox_device_service.dart';
import '../../data/services/gemini_ai_service.dart';
import '../../data/models/user_model.dart';
import '../../data/models/test_result_model.dart';
import '../../data/models/notification_model.dart';

// ============================================================================
// 🔐 AUTH PROVIDERS
// ============================================================================

/// Instance du service d'authentification
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// 🤖 Instance du service Gemini AI
final geminiAIServiceProvider = Provider<GeminiAIService>((ref) {
  return GeminiAIService();
});

/// Utilisateur actuel (stream)
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.asyncMap((firebaseUser) async {
    if (firebaseUser != null) {
      return await authService.getCurrentUserData();
    }
    return null;
  });
});

/// Données utilisateur (cache synchrone)
final userDataProvider = FutureProvider<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getCurrentUserData();
});

// ============================================================================
// 🧪 TEST PROVIDERS
// ============================================================================

/// Instance du service de tests
final testServiceProvider = Provider<TestService>((ref) {
  return TestService();
});

/// Liste des tests de l'utilisateur
final userTestsProvider = StreamProvider.family<List<TestResultModel>, String>((ref, userId) {
  final testService = ref.watch(testServiceProvider);
  return testService.watchUserTests(userId);
});

/// Tests récents (limite 30)
final recentTestsProvider = FutureProvider.family<List<TestResultModel>, String>((ref, userId) async {
  final testService = ref.watch(testServiceProvider);
  return await testService.getRecentTests(userId, limit: 30);
});

/// Statistiques de l'utilisateur
final userStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final testService = ref.watch(testServiceProvider);
  final stats = await testService.getUserStatistics(userId);
  return {
    'totalTests': stats.totalTests,
    'averageScore': stats.averageScore,
    'lastTestDate': stats.lastTestDate,
    'improvementRate': stats.improvementRate,
  };
});

/// Test spécifique par ID
final testByIdProvider = FutureProvider.family<TestResultModel?, String>((ref, testId) async {
  final testService = ref.watch(testServiceProvider);
  return await testService.getTestById(testId);
});

// ============================================================================
// 🔔 NOTIFICATION PROVIDERS
// ============================================================================

/// Instance du service de notifications
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Notifications de l'utilisateur
final userNotificationsProvider = FutureProvider.family<List<NotificationModel>, String>((ref, userId) async {
  final notificationService = ref.watch(notificationServiceProvider);
  return await notificationService.getUserNotifications(userId);
});

/// Notifications non lues
final unreadNotificationsProvider = FutureProvider.family<List<NotificationModel>, String>((ref, userId) async {
  final notificationService = ref.watch(notificationServiceProvider);
  return await notificationService.getUnreadNotifications(userId);
});

/// Nombre de notifications non lues
final unreadCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final unreadNotifications = await ref.watch(unreadNotificationsProvider(userId).future);
  return unreadNotifications.length;
});

// ============================================================================
// 📱 DEVICE PROVIDERS (BLUETOOTH)
// ============================================================================

/// Instance du service RespiraBox
final respiraBoxServiceProvider = Provider<RespiraBoxDeviceService>((ref) {
  final service = RespiraBoxDeviceService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// État de connexion du device
final deviceConnectionProvider = StateProvider<bool>((ref) => false);

/// Device actuellement connecté
final connectedDeviceProvider = StateProvider<String?>((ref) => null);

/// Stream des données en temps réel du device
final deviceDataStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final deviceService = ref.watch(respiraBoxServiceProvider);
  return deviceService.dataStream;
});

// ============================================================================
// 🎯 UI STATE PROVIDERS
// ============================================================================

/// État de chargement global
final isLoadingProvider = StateProvider<bool>((ref) => false);

/// Message d'erreur global
final errorMessageProvider = StateProvider<String?>((ref) => null);

/// Index de la page actuelle (bottom navigation)
final currentPageIndexProvider = StateProvider<int>((ref) => 0);

/// Mode sombre activé
final darkModeProvider = StateProvider<bool>((ref) => false);

/// Langue sélectionnée
final languageProvider = StateProvider<String>((ref) => 'fr');
