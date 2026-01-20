import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/models/notification_model.dart';
import '../../../core/providers/app_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            body: Center(child: Text('Non connecté')),
          );
        }

        return StreamBuilder<List<NotificationModel>>(
          stream: NotificationService().watchUserNotifications(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final notifications = snapshot.data ?? [];
            final unreadCount = notifications.where((n) => !n.isRead).length;

            return Scaffold(
              backgroundColor: Colors.grey[50],
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notifications', style: AppTextStyles.h2),
                    if (unreadCount > 0)
                      Text(
                        '$unreadCount non lue${unreadCount > 1 ? 's' : ''}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primary),
                      ),
                  ],
                ),
                actions: [
                  if (notifications.isNotEmpty && unreadCount > 0)
                    TextButton(
                      onPressed: () async {
                        for (var notif
                            in notifications.where((n) => !n.isRead)) {
                          await NotificationService().markAsRead(notif.id);
                        }
                      },
                      child: const Text('Tout lire'),
                    ),
                  if (notifications.isNotEmpty)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          color: AppColors.textDark),
                      onSelected: (value) async {
                        if (value == 'clear') {
                          final notifs = await NotificationService()
                              .getUserNotifications(user.id);
                          for (var n in notifs) {
                            await NotificationService()
                                .deleteNotification(n.id);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'clear',
                          child: Text('Tout supprimer'),
                        ),
                      ],
                    ),
                ],
              ),
              body: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_outlined,
                              size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('Aucune notification',
                              style: AppTextStyles.h3
                                  .copyWith(color: Colors.grey[400])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        return Dismissible(
                          key: Key(notif.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: AppColors.error,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) async {
                            await NotificationService()
                                .deleteNotification(notif.id);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: notif.isRead
                                  ? Colors.white
                                  : AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getTypeColor(notif.type)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getTypeIcon(notif.type),
                                  color: _getTypeColor(notif.type),
                                  size: 24,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: AppTextStyles.h4.copyWith(
                                        fontWeight: notif.isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(notif.message,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textLight)),
                                  const SizedBox(height: 8),
                                  Text(_formatTime(notif.createdAt),
                                      style: AppTextStyles.bodySmall
                                          .copyWith(color: Colors.grey[400])),
                                ],
                              ),
                              onTap: () async {
                                if (!notif.isRead) {
                                  await NotificationService()
                                      .markAsRead(notif.id);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            );
          },
        );
      },
      loading: () => Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(body: Center(child: Text('Erreur'))),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.testComplete:
        return Icons.check_circle_outline;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.alert:
        return Icons.warning_amber_rounded;
      case NotificationType.success:
        return Icons.check_circle;
      default:
        return Icons.info_outline;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.testComplete:
        return AppColors.primary;
      case NotificationType.reminder:
        return Colors.blue;
      case NotificationType.alert:
        return AppColors.warning;
      case NotificationType.success:
        return AppColors.success;
      default:
        return Colors.purple;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${time.day}/${time.month}/${time.year}';
  }
}
