import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase background handler init error: $e");
  }
  debugPrint("Handling background FCM message: ${message.messageId}");
  await NotificationService.showBackgroundNotification(message);
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await firebaseMessagingBackgroundHandler(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static StreamSubscription<User?>? _authSubscription;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (_) {}

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("Notification tapped: ${response.payload}");
      },
    );

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground FCM message received: ${message.messageId}");
      _showNotification(message);
    });
  }

  static Future<void> requestPermissions() async {
    // Explicitly request for Android 13+ as per user requirement
    await Permission.notification.request();

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
      'loveplus_high_importance_channel',
      'Love Plus Important Alerts',
      description: 'High importance notifications for Love Plus messages, fits, and letters',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel loveplusChannel = AndroidNotificationChannel(
      'loveplus_alerts',
      'Love Plus Alerts',
      description: 'High priority notifications for Love Plus',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel legacyChannel = AndroidNotificationChannel(
      'couple_app_channel',
      'Couple App Notifications',
      description: 'Legacy channel for Couple App',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(highImportanceChannel);
    await androidPlugin?.createNotificationChannel(loveplusChannel);
    await androidPlugin?.createNotificationChannel(legacyChannel);
  }

  static Future<void> syncFCMToken([String? providedUid]) async {
    // Listen for auth state changes so we always persist when user logs in or is restored
    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _persistTokenForUid(user.uid);
      }
    });

    final uid = providedUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _persistTokenForUid(uid);
    }

    // Always listen to token refresh
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final activeUid = providedUid ?? FirebaseAuth.instance.currentUser?.uid;
      if (activeUid != null && newToken.isNotEmpty) {
        await _saveTokenToFirestore(activeUid, newToken);
      }
    });
  }

  static Future<void> _persistTokenForUid(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveTokenToFirestore(uid, token);
      }
    } catch (e) {
      debugPrint("Error fetching FCM token: $e");
    }
  }

  static Future<void> _saveTokenToFirestore(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint("Persisted FCM token for user $uid to users/$uid/fcmToken");
    } catch (e) {
      debugPrint("Error saving FCM token to Firestore: $e");
    }
  }

  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotificationsPlugin.initialize(initializationSettings);
    await _showNotification(message);
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    String title = notification?.title ?? message.data['title'] ?? 'New Notification';
    String body = notification?.body ?? message.data['body'] ?? '';

    if (title.isNotEmpty || body.isNotEmpty) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'loveplus_high_importance_channel',
        'Love Plus Important Alerts',
        channelDescription: 'High importance notifications for Love Plus messages, fits, and letters',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        color: Color(0xFFFF4D6D),
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
      );
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosDetails,
      );
      
      int id = notification?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _localNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
      );
    }
  }

  static Future<void> sendLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'loveplus_high_importance_channel',
      'Love Plus Important Alerts',
      channelDescription: 'High importance notifications for Love Plus messages, fits, and letters',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      color: Color(0xFFFF4D6D),
      playSound: true,
      enableVibration: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  static Future<void> dispatchPushNotification({
    required String? coupleId,
    required String? partnerUid,
    required String title,
    required String body,
    required String type, // 'chat' | 'ootd' | 'memo' | 'theme'
    String? chatId,
  }) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    try {
      String? targetPartnerUid = partnerUid;
      if (targetPartnerUid == null && coupleId != null) {
        final coupleDoc = await FirebaseFirestore.instance.collection('couples').doc(coupleId).get();
        if (coupleDoc.exists) {
          final cData = coupleDoc.data()!;
          targetPartnerUid = cData['user1'] == myUid ? cData['user2'] : cData['user1'];
        }
      }

      if (targetPartnerUid == null) return;

      final partnerDoc = await FirebaseFirestore.instance.collection('users').doc(targetPartnerUid).get();
      final partnerData = partnerDoc.data();
      final String? partnerFcmToken = partnerData?['fcmToken'];

      final Map<String, dynamic> payload = {
        'toToken': partnerFcmToken,
        'recipientUid': targetPartnerUid,
        'senderId': myUid,
        'coupleId': coupleId ?? chatId,
        'timestamp': FieldValue.serverTimestamp(),
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'channel_id': 'loveplus_high_importance_channel',
        },
        'data': {
          'type': type,
          'chatId': chatId ?? coupleId ?? '',
          'senderId': myUid,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channelId': 'loveplus_high_importance_channel',
            'sound': 'default',
          },
        },
      };

      if (coupleId != null) {
        await FirebaseFirestore.instance
            .collection('couples')
            .doc(coupleId)
            .collection('notifications')
            .add(payload);
      }

      await FirebaseFirestore.instance
          .collection('notifications_queue')
          .add(payload);

      debugPrint("Dispatched push notification ($type) to partner $targetPartnerUid");
    } catch (e) {
      debugPrint("Error dispatching push notification: $e");
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'loveplus_high_importance_channel',
      'Love Plus Important Alerts',
      channelDescription: 'High importance notifications for Love Plus messages, fits, and letters',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      color: Color(0xFFFF4D6D),
      playSound: true,
      enableVibration: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(delay),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}


