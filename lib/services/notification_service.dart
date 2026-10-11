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
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling background FCM message: ${message.messageId}");
  await NotificationService.showBackgroundNotification(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
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
    await androidPlugin?.createNotificationChannel(loveplusChannel);
    await androidPlugin?.createNotificationChannel(legacyChannel);
  }

  static Future<void> syncFCMToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': newToken,
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint("Error syncing FCM token: $e");
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
        'loveplus_alerts',
        'Love Plus Alerts',
        channelDescription: 'High priority notifications for Love Plus',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        color: Color(0xFFFF4D6D),
        playSound: true,
        enableVibration: true,
      );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
      
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
      'loveplus_alerts',
      'Love Plus Alerts',
      channelDescription: 'High priority notifications for Love Plus',
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
    required String type, // 'chat' | 'ootd' | 'memo'
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
        },
        'data': {
          'type': type,
          'chatId': chatId ?? coupleId ?? '',
          'senderId': myUid,
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
      'loveplus_alerts',
      'Love Plus Alerts',
      channelDescription: 'High priority notifications for Love Plus',
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


