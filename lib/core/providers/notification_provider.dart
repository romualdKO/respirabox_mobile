import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';

/// 🔔 PROVIDER NOTIFICATIONS
/// Gère l'état des notifications dans l'application

// Provider NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Provider liste des notifications utilisateur
final userNotificationsProvider = StreamProvider.autoDispose
    .family<List<NotificationModel>, String>((ref, userId) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.watchUserNotifications(userId);
});

// Provider notifications non lues
final unreadNotificationsProvider = FutureProvider.autoDispose
    .family<List<NotificationModel>, String>((ref, userId) async {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.getUnreadNotifications(userId);
});

// Provider nombre de notifications non lues
final unreadCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, userId) async {
  final notifications =
      await ref.watch(unreadNotificationsProvider(userId).future);
  return notifications.length;
});

// Provider pour marquer comme lu
final markAsReadProvider = Provider<Future<void> Function(String)>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return (String notificationId) async {
    await notificationService.markAsRead(notificationId);
    // Invalider le cache pour forcer le rechargement
    ref.invalidate(userNotificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
    ref.invalidate(unreadCountProvider);
  };
});

// Provider pour marquer toutes comme lues
final markAllAsReadProvider = Provider<Future<void> Function(String)>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return (String userId) async {
    await notificationService.markAllAsRead(userId);
    // Invalider le cache
    ref.invalidate(userNotificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
    ref.invalidate(unreadCountProvider);
  };
});
