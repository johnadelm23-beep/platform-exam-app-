import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:platformexamapp/firebase_options.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/exams/ui/exam_list_screen.dart';
import 'package:platformexamapp/features/home/ui/daily_content_screen.dart';
import 'package:platformexamapp/features/home/ui/home_screen.dart';

/// Global navigator key for notification tap routing
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint(
    '[FCM DEBUG] Background Message Received: ID=${message.messageId}, Title=${message.notification?.title}, Body=${message.notification?.body}, Data=${message.data}',
  );
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'egtma3na_high_importance_channel',
        'Egtma3na Notifications',
        description:
            'This channel is used for important Egtma3na app notifications.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  bool _isInitialized = false;
  String? _currentToken;

  String? get currentToken => _currentToken;

  /// Initialize FCM, local notifications, channels, and listeners
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Request notification permissions
    await requestPermission();

    // 2. Setup Local Notifications for Foreground display
    const androidInitSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinInitSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: darwinInitSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint(
          '[FCM DEBUG] Local Notification Tapped: payload=${response.payload}',
        );
        if (response.payload != null && response.payload!.isNotEmpty) {
          _handlePayloadString(response.payload!);
        }
      },
    );

    // Create high importance channel on Android
    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.createNotificationChannel(_androidChannel);

    // 3. Foreground presentation options
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 5. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '[FCM DEBUG] Foreground Received: ID=${message.messageId}, Title=${message.notification?.title}, Body=${message.notification?.body}, Data=${message.data}',
      );

      final notification = message.notification;
      final android = message.notification?.android;

      // If notification payload exists and we need local display in foreground
      if (notification != null && android != null) {
        _showLocalNotification(
          id: message.hashCode,
          title: notification.title ?? 'Egtma3na',
          body: notification.body ?? '',
          payload: _encodeDataPayload(message.data),
        );
      } else if (message.data.isNotEmpty) {
        // Fallback for data-only messages in foreground
        final title = message.data['title'] ?? 'Egtma3na';
        final body = message.data['body'] ?? '';
        if (body.isNotEmpty || title.isNotEmpty) {
          _showLocalNotification(
            id: message.hashCode,
            title: title,
            body: body,
            payload: _encodeDataPayload(message.data),
          );
        }
      }
    });

    // 6. Handle Background Notification Taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '[FCM DEBUG] Notification Tapped / Opened (Background): Data=${message.data}',
      );
      handleRoutingData(message.data);
    });

    // 7. Handle Terminated State Notification Open
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '[FCM DEBUG] Notification Tapped / Opened (Terminated): Data=${initialMessage.data}',
      );
      // Short delay to ensure app navigation tree is ready
      Future.delayed(const Duration(milliseconds: 600), () {
        handleRoutingData(initialMessage.data);
      });
    }

    // 8. Topic Subscription
    try {
      await _fcm.subscribeToTopic('all_users');
      debugPrint('[FCM DEBUG] Successfully subscribed to topic: all_users');
    } catch (e) {
      debugPrint('[FCM DEBUG] Failed to subscribe to topic all_users: $e');
    }

    // 9. Fetch and Sync FCM Token
    await syncFcmToken();

    // 10. Listen for Token Refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM DEBUG] FCM Token Refreshed: $newToken');
      _currentToken = newToken;
      await _saveTokenToFirestore(newToken);
    });
  }

  /// Request Notification Permissions
  Future<void> requestPermission() async {
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint(
        '[FCM DEBUG] Notification Permission Status: ${settings.authorizationStatus}',
      );
    } catch (e) {
      debugPrint('[FCM DEBUG] Error requesting notification permission: $e');
    }
  }

  /// Sync FCM token for currently logged in user
  Future<void> syncFcmToken() async {
    try {
      final token = await _fcm.getToken();
      _currentToken = token;
      debugPrint('[FCM DEBUG] Current FCM Token: $token');
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('[FCM DEBUG] Error getting FCM Token: $e');
    }
  }

  /// Save FCM token under `users/{uid}/fcmTokens/{token}`
  Future<void> _saveTokenToFirestore(String token) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('fcmTokens')
          .doc(token)
          .set({
            'token': token,
            'platform': defaultTargetPlatform.name.toLowerCase(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      debugPrint(
        '[FCM DEBUG] FCM Token stored in Firestore for user ${currentUser.uid}',
      );
    } catch (e) {
      debugPrint('[FCM DEBUG] Error storing FCM token in Firestore: $e');
    }
  }

  /// Display a local notification when message arrives in foreground
  void _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) {
    _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// Encode data map into key=val&key2=val2 string for payload
  String _encodeDataPayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// Decode payload string back to map
  void _handlePayloadString(String payload) {
    final Map<String, dynamic> data = {};
    for (var pair in payload.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        data[parts[0]] = parts[1];
      }
    }
    handleRoutingData(data);
  }

  /// Deep link / route handling on notification tap
  void handleRoutingData(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final contentId = data['contentId']?.toString();

    debugPrint(
      '[FCM DEBUG] Handling Notification Route: type=$type, contentId=$contentId',
    );

    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('[FCM DEBUG] Navigator context is null, skipping navigation.');
      return;
    }

    if (type == 'post') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (type == 'exam') {
      _navigateToExams(context);
    } else if (type == 'daily_content' || type == 'competition') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const DailyContentScreen()),
      );
    }
  }

  Future<void> _navigateToExams(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
      if (doc.exists && doc.data() != null) {
        final userData = UserData.fromJson(doc.data()!, currentUser.uid);
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => ExamsScreen(user: userData)),
        );
      }
    } catch (e) {
      debugPrint('[FCM DEBUG] Error fetching user data for exams route: $e');
    }
  }
}
