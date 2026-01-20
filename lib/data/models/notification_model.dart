import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔔 MODÈLE DE NOTIFICATION
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final String? actionRoute; // Route de navigation quand on clique
  final Map<String, dynamic>? data; // Données additionnelles
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    this.actionRoute,
    this.data,
    required this.createdAt,
  });

  /// Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'isRead': isRead,
      'actionRoute': actionRoute,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Création depuis Firestore
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: _parseNotificationType(data['type']),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      actionRoute: data['actionRoute'],
      data: data['data'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'testComplete':
        return NotificationType.testComplete;
      case 'reminder':
        return NotificationType.reminder;
      case 'alert':
        return NotificationType.alert;
      case 'info':
        return NotificationType.info;
      case 'success':
        return NotificationType.success;
      default:
        return NotificationType.info;
    }
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    bool? isRead,
    String? actionRoute,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 📑 TYPES DE NOTIFICATIONS
enum NotificationType {
  testComplete, // Test terminé
  reminder, // Rappel
  alert, // Alerte importante
  info, // Information
  success, // Succès
}
