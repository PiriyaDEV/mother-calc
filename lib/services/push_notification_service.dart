import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Must be a top-level function — runs in a separate isolate when app is terminated/background
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // FCM handles displaying the notification automatically in background/terminated state.
  // No action needed here unless you want custom processing.
  debugPrint('[Push] Background message: ${message.messageId}');
}

class PushNotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static const _channelId = 'kidtang_channel';
  static const _channelName = 'Kidtang';

  static Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // flutter_local_notifications has no web implementation — FCM's own
    // foreground/background handling covers web instead.
    if (!kIsWeb) {
      // Android notification channel (required for Android 8+)
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'การแจ้งเตือนจาก Kidtang',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Local notifications init
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _localNotifications.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
      );
    }

    // Request permission (iOS prompts user; Android 13+ also needs this)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Show local notification while app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // iOS: show notifications when app is in foreground
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // VAPID key for Web Push — injected at build time via:
  //   --dart-define=FCM_WEB_VAPID_KEY=<your-key>
  // or set FCM_WEB_VAPID_KEY in your .env file for local dev.
  static const _webVapidKey =
      String.fromEnvironment('FCM_WEB_VAPID_KEY');

  // Call after successful login to register this device
  static Future<void> saveToken() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final token = kIsWeb
          ? await _messaging.getToken(vapidKey: _webVapidKey)
          : await _messaging.getToken();
      if (token == null) return;
      await _saveToSupabase(user.id, token);

      // Re-save if token rotates
      _messaging.onTokenRefresh.listen((newToken) async {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) await _saveToSupabase(currentUser.id, newToken);
      });
    } catch (e) {
      debugPrint('[Push] Error saving token: $e');
    }
  }

  // Call on logout to stop receiving notifications on this device
  static Future<void> clearToken() async {
    final user = Supabase.instance.client.auth.currentUser;
    try {
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': null})
            .eq('id', user.id);
      }
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('[Push] Error clearing token: $e');
    }
  }

  static Future<void> _saveToSupabase(String userId, String token) async {
    await Supabase.instance.client
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', userId);
    debugPrint('[Push] FCM token saved');
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    // flutter_local_notifications has no web implementation — browsers show
    // FCM foreground messages via their own notification API instead.
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'การแจ้งเตือนจาก Kidtang',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['type'] as String?,
    );
  }
}
