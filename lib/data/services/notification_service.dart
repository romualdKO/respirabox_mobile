import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

/// 🔔 SERVICE DE GESTION DES NOTIFICATIONS
/// Gère les notifications locales et Firebase Cloud Messaging (FCM)
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Collection Firestore des notifications
  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  /// INITIALISER FCM (Firebase Cloud Messaging)
  Future<void> initFCM() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('[FCM] Permission refusée');
        return;
      }

      // Récupérer et sauvegarder le token FCM dans Firestore
      final token = await _messaging.getToken();
      if (token != null) {
        print('[FCM] Token: $token');
        await _saveFcmToken(token);
      }

      // Rafraîchissement automatique du token
      _messaging.onTokenRefresh.listen(_saveFcmToken);

      // Notifications reçues quand l'app est au premier plan
      FirebaseMessaging.onMessage.listen(_handleForegroundNotification);

      // Notification cliquée depuis l'arrière-plan
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      print('[FCM] Initialisation réussie');
    } catch (e) {
      print('[FCM] Erreur initialisation: $e');
    }
  }

  /// Sauvegarde le token FCM dans Firestore pour l'utilisateur connecté
  Future<void> _saveFcmToken(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
      });
      if (kDebugMode) print('[FCM] Token sauvegardé pour $uid');
    } catch (e) {
      print('[FCM] Erreur sauvegarde token: $e');
    }
  }

  /// Sauvegarde le token FCM pour un utilisateur spécifique
  Future<void> saveFcmTokenForUser(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('[FCM] Erreur mise à jour token utilisateur: $e');
    }
  }

  /// Notification reçue en premier plan : crée une notification Firestore
  void _handleForegroundNotification(RemoteMessage message) {
    final title = message.notification?.title ?? 'RespiraBox';
    final body  = message.notification?.body  ?? '';
    print('[FCM] Notification premier plan: $title — $body');

    // Persister dans Firestore pour affichage dans l'écran Notifications
    if (message.data['userId'] != null) {
      createNotification(NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: message.data['userId'] as String,
        type: NotificationType.info,
        title: title,
        message: body,
        actionRoute: message.data['route'] as String?,
        data: message.data,
        createdAt: DateTime.now(),
      ));
    }
  }

  /// Notification cliquée depuis l'arrière-plan : navigation vers la route
  void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route'] as String?;
    print('[FCM] Tap notification, route: $route');
    // La navigation est gérée par le NavigatorKey global de l'app
    // navigatorKey.currentState?.pushNamed(route); ← activer si NavigatorKey configuré
  }

  /// ➕ CRÉER UNE NOTIFICATION
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _notificationsCollection
          .doc(notification.id)
          .set(notification.toFirestore());
    } catch (e) {
      throw 'Erreur lors de la création de la notification: $e';
    }
  }

  /// 📋 RÉCUPÉRER LES NOTIFICATIONS D'UN UTILISATEUR
  Future<List<NotificationModel>> getUserNotifications(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Erreur lors de la récupération des notifications: $e';
    }
  }

  /// 📬 RÉCUPÉRER LES NOTIFICATIONS NON LUES
  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Erreur lors de la récupération des notifications non lues: $e';
    }
  }

  /// 🔵 NOMBRE DE NOTIFICATIONS NON LUES
  Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw 'Erreur lors du comptage des notifications: $e';
    }
  }

  /// ✅ MARQUER UNE NOTIFICATION COMME LUE
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw 'Erreur lors du marquage de la notification: $e';
    }
  }

  /// ✅✅ MARQUER TOUTES LES NOTIFICATIONS COMME LUES
  Future<void> markAllAsRead(String userId) async {
    try {
      final unreadNotifications = await getUnreadNotifications(userId);

      // Mise à jour en batch
      final batch = _firestore.batch();
      for (var notification in unreadNotifications) {
        batch.update(
          _notificationsCollection.doc(notification.id),
          {'isRead': true},
        );
      }
      await batch.commit();
    } catch (e) {
      throw 'Erreur lors du marquage global: $e';
    }
  }

  /// 🗑️ SUPPRIMER UNE NOTIFICATION
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      throw 'Erreur lors de la suppression de la notification: $e';
    }
  }

  /// 🗑️🗑️ SUPPRIMER TOUTES LES NOTIFICATIONS
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final notifications = await getUserNotifications(userId);

      // Suppression en batch
      final batch = _firestore.batch();
      for (var notification in notifications) {
        batch.delete(_notificationsCollection.doc(notification.id));
      }
      await batch.commit();
    } catch (e) {
      throw 'Erreur lors de la suppression globale: $e';
    }
  }

  /// 🔄 STREAM EN TEMPS RÉEL DES NOTIFICATIONS
  Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  /// 🔄 STREAM DU NOMBRE DE NOTIFICATIONS NON LUES
  Stream<int> watchUnreadCount(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 🔔 ENVOYER UNE NOTIFICATION DE TEST TERMINÉ
  Future<void> sendTestCompletedNotification(
    String userId,
    String testId,
    int score,
  ) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: NotificationType.testComplete,
      title: '✅ Test terminé',
      message: 'Votre test respiratoire est terminé. Score: $score/100',
      actionRoute: '/test-result/$testId',
      data: {'testId': testId, 'score': score},
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  /// 🔔 ENVOYER UN RAPPEL
  Future<void> sendReminderNotification(
    String userId,
    String message,
  ) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: NotificationType.reminder,
      title: '⏰ Rappel',
      message: message,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  /// 🔔 ENVOYER UNE ALERTE
  Future<void> sendAlertNotification(
    String userId,
    String message,
  ) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: NotificationType.alert,
      title: '⚠️ Alerte importante',
      message: message,
      createdAt: DateTime.now(),
    );

    await createNotification(notification);
  }

  /// 🧠 NOTIFICATIONS INTELLIGENTES BASÉES SUR L'ÉTAT DE SANTÉ
  /// Analyse les résultats de tests et envoie des rappels personnalisés
  Future<void> sendHealthBasedReminders(String userId) async {
    try {
      // Récupérer les derniers tests de l'utilisateur
      final testsSnapshot = await _firestore
          .collection('tests')
          .where('userId', isEqualTo: userId)
          .orderBy('testDate', descending: true)
          .limit(5)
          .get();

      if (testsSnapshot.docs.isEmpty) {
        // Aucun test, envoyer rappel pour faire un test
        await sendReminderNotification(
          userId,
          '🫁 Il est temps de faire votre premier test respiratoire pour surveiller votre santé.',
        );
        return;
      }

      final tests = testsSnapshot.docs;
      final lastTest = tests.first.data();
      final testDateRaw = lastTest['testDate'];
      if (testDateRaw == null) return;
      final lastTestDate = (testDateRaw as Timestamp).toDate();
      final daysSinceLastTest = DateTime.now().difference(lastTestDate).inDays;

      // Analyser le niveau de risque moyen
      int highRiskCount = 0;
      int moderateRiskCount = 0;

      for (var test in tests) {
        final riskLevel = test.data()['riskLevel'] as String?;
        if (riskLevel == 'high') highRiskCount++;
        if (riskLevel == 'moderate') moderateRiskCount++;
      }

      // LOGIQUE INTELLIGENTE DES RAPPELS

      // 1. Risque élevé répété -> Alerte médicale urgente
      if (highRiskCount >= 2) {
        await sendAlertNotification(
          userId,
          '⚠️ URGENT : Vos derniers tests montrent un risque élevé. Consultez immédiatement un médecin.',
        );
        return;
      }

      // 2. Risque élevé récent -> Rappel test de contrôle
      if (lastTest['riskLevel'] == 'high' && daysSinceLastTest >= 2) {
        await sendReminderNotification(
          userId,
          '🏥 Test de contrôle recommandé : Votre dernier test montrait un risque élevé il y a $daysSinceLastTest jours.',
        );
        return;
      }

      // 3. Risque modéré répété -> Suivi régulier
      if (moderateRiskCount >= 3) {
        await sendReminderNotification(
          userId,
          '📊 Vos tests montrent un risque modéré persistant. Pensez à consulter votre médecin pour un suivi.',
        );
        return;
      }

      // 4. SpO2 bas détecté -> Alerte oxygénation
      final spo2 = lastTest['spo2'] as num?;
      if (spo2 != null && spo2 < 90) {
        await sendAlertNotification(
          userId,
          '💨 Oxygénation basse détectée (${spo2.round()}%). Faites un nouveau test et consultez si les symptômes persistent.',
        );
        return;
      }

      // 5. Fréquence cardiaque anormale -> Alerte
      final heartRate = lastTest['heartRate'] as num?;
      if (heartRate != null && (heartRate > 120 || heartRate < 50)) {
        await sendReminderNotification(
          userId,
          '❤️ Fréquence cardiaque anormale détectée (${heartRate} bpm). Surveillez votre état et consultez si nécessaire.',
        );
        return;
      }

      // 6. Pas de test depuis longtemps -> Rappel régulier
      if (daysSinceLastTest >= 7 && lastTest['riskLevel'] == 'low') {
        await sendReminderNotification(
          userId,
          '⏰ Cela fait $daysSinceLastTest jours depuis votre dernier test. Pensez à faire un contrôle régulier.',
        );
        return;
      }

      // 7. Amélioration constatée -> Encouragement
      if (tests.length >= 2) {
        final previousTest = tests[1].data();
        final currentRisk = lastTest['riskLevel'];
        final previousRisk = previousTest['riskLevel'];

        if (previousRisk == 'high' && currentRisk == 'moderate') {
          await createNotification(NotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: userId,
            type: NotificationType.info,
            title: '🎉 Excellentes nouvelles !',
            message:
                'Vos résultats s\'améliorent ! Continuez vos efforts et maintenez une bonne hygiène respiratoire.',
            createdAt: DateTime.now(),
          ));
        }
      }

      // 8. Tout va bien -> Rappel préventif mensuel
      if (daysSinceLastTest >= 30 && lastTest['riskLevel'] == 'low') {
        await sendReminderNotification(
          userId,
          '✅ Votre santé respiratoire semble bonne ! Test de contrôle mensuel recommandé.',
        );
      }
    } catch (e) {
      print('❌ Erreur notifications intelligentes: $e');
    }
  }

  /// 📅 PLANIFIER DES RAPPELS AUTOMATIQUES
  /// À appeler régulièrement (ex: chaque jour via background task)
  Future<void> scheduleHealthReminders(String userId) async {
    try {
      // Vérifier la dernière notification envoyée
      final lastNotifications = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('type', whereIn: ['reminder', 'alert'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (lastNotifications.docs.isNotEmpty) {
        final data =
            lastNotifications.docs.first.data() as Map<String, dynamic>;
        final lastNotifDate = (data['createdAt'] as Timestamp).toDate();
        final hoursSinceLastNotif =
            DateTime.now().difference(lastNotifDate).inHours;

        // Ne pas envoyer plus d'une notification toutes les 24h
        if (hoursSinceLastNotif < 24) {
          return;
        }
      }

      // Envoyer les notifications intelligentes
      await sendHealthBasedReminders(userId);
    } catch (e) {
      print('❌ Erreur planification rappels: $e');
    }
  }
}
