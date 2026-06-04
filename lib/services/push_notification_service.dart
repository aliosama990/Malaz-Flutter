import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../helpers/shared_prefs.dart';
import '../models/child_mode.dart';
import '../providers/child_provider.dart';
import '../screens/reports_screen.dart';
import '../utils/platform_utils.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb || !isAndroidPlatform) {
    return;
  }

  await Firebase.initializeApp();
  debugPrint(
    '[FCM_RECEIVE_DEBUG] Background handler received message data: ${message.data}',
  );
  await PushNotificationService.showBackgroundNotification(message);
}

class PushNotificationService {
  PushNotificationService._();

  static const String _androidChannelId = 'malaz_alerts';
  static const String _androidChannelName = 'Malaz alerts';
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    _androidChannelId,
    _androidChannelName,
    description: 'SOS and child safety alerts',
    importance: Importance.high,
  );

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final ApiService _apiService = ApiService();

  static bool _isInitialized = false;
  static bool _localNotificationsInitialized = false;
  static Map<String, dynamic>? _pendingNavigationData;

  static Future<void> initialize() async {
    debugPrint('[FCM_DEBUG] PushNotificationService.initialize() started');
    if (kIsWeb || !isAndroidPlatform || _isInitialized) {
      debugPrint(
        '[FCM_DEBUG] PushNotificationService.initialize() finished: skipped',
      );
      return;
    }

    _isInitialized = true;
    await _ensureLocalNotificationsInitialized();
    await _requestPermission();
    await registerDeviceToken();

    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    debugPrint('[FCM_RECEIVE_DEBUG] FirebaseMessaging.onMessage registered');
    FirebaseMessaging.onMessage.listen((message) async {
      final kind = _messageKind(message);
      final dataType = message.data['type'];
      debugPrint(
        '[FCM_RECEIVE_DEBUG] onMessage fired: title=${message.notification?.title}, body=${message.notification?.body}, kind=$kind',
      );
      debugPrint('[FCM_RECEIVE_DEBUG] onMessage data: ${message.data}');
      debugPrint('[FCM_RECEIVE_DEBUG] onMessage data.type: $dataType');
      await _showLocalNotification(message);
    });

    debugPrint(
      '[FCM_RECEIVE_DEBUG] FirebaseMessaging.onMessageOpenedApp registered',
    );
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint(
        '[FCM_RECEIVE_DEBUG] onMessageOpenedApp fired with data: ${message.data}',
      );
      _handleNotificationTap(message.data);
    });

    final initialMessage = await _messaging.getInitialMessage();
    final initialMessageResult =
        initialMessage == null ? 'null' : initialMessage.data.toString();
    debugPrint(
      '[FCM_RECEIVE_DEBUG] getInitialMessage result: $initialMessageResult',
    );
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data);
    }
    debugPrint('[FCM_DEBUG] PushNotificationService.initialize() finished');
  }

  static void handlePendingNavigation() {
    final data = _pendingNavigationData;
    if (data == null) {
      return;
    }

    _pendingNavigationData = null;
    _handleNotificationTap(data);
  }

  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    await _ensureLocalNotificationsInitialized();
    await _showLocalNotification(message);
  }

  static Future<void> registerDeviceToken() async {
    debugPrint('[FCM_DEBUG] registerDeviceToken() called');
    if (kIsWeb || !isAndroidPlatform) {
      return;
    }

    try {
      final token = await _messaging.getToken();
      if (token == null || token.trim().isEmpty) {
        debugPrint('[FCM_DEBUG] FirebaseMessaging.getToken() returned null');
        return;
      }
      final tokenPrefix =
          token.substring(0, token.length < 12 ? token.length : 12);
      debugPrint(
        '[FCM_DEBUG] FirebaseMessaging.getToken() returned token prefix: $tokenPrefix',
      );

      final authToken = SharedPrefs.authToken;
      debugPrint(
        '[FCM_DEBUG] SharedPrefs.authToken exists at registration time: ${authToken != null && authToken.trim().isNotEmpty}',
      );
      if (authToken == null || authToken.trim().isEmpty) {
        debugPrint(
          '[PushNotificationService] Skipping FCM token registration: no auth token yet',
        );
        return;
      }

      await _registerToken(token);
    } catch (error) {
      debugPrint('[PushNotificationService] FCM token read failed: $error');
    }
  }

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _registerToken(String token) async {
    final authToken = SharedPrefs.authToken;
    debugPrint(
      '[FCM_DEBUG] SharedPrefs.authToken exists at registration time: ${authToken != null && authToken.trim().isNotEmpty}',
    );
    if (authToken == null || authToken.trim().isEmpty) {
      debugPrint(
        '[PushNotificationService] Skipping FCM token registration: no auth token yet',
      );
      return;
    }

    try {
      debugPrint(
        '[FCM_DEBUG] Calling POST /api/Notification/device-token',
      );
      await _apiService.post(
        '/api/Notification/device-token',
        body: {
          'token': token,
          'deviceType': 'Android',
        },
        handleUnauthorized: false,
      );
      debugPrint('[FCM_DEBUG] FCM token registration succeeded');
    } on ApiException catch (error) {
      debugPrint(
        '[FCM_DEBUG] FCM token registration failed: statusCode=${error.statusCode}, message=${error.message}',
      );
    } catch (error) {
      debugPrint(
        '[FCM_DEBUG] FCM token registration failed: statusCode=null, message=$error',
      );
    }
  }

  static Future<void> _ensureLocalNotificationsInitialized() async {
    if (_localNotificationsInitialized) {
      return;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    _localNotificationsInitialized = true;
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];
    final kind = _messageKind(message);

    if ((title == null || title.toString().trim().isEmpty) &&
        (body == null || body.toString().trim().isEmpty)) {
      debugPrint(
        '[FCM_RECEIVE_DEBUG] Skipping local notification: no title/body, kind=$kind',
      );
      return;
    }

    try {
      debugPrint(
        '[FCM_RECEIVE_DEBUG] Showing local foreground notification on channel $_androidChannelId, kind=$kind',
      );
      await _localNotifications.show(
        id: message.hashCode,
        title: title?.toString(),
        body: body?.toString(),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: 'SOS and child safety alerts',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
      debugPrint('[FCM_RECEIVE_DEBUG] Local notification show succeeded');
    } catch (error) {
      debugPrint('[FCM_RECEIVE_DEBUG] Local notification show failed: $error');
      rethrow;
    }
  }

  static String _messageKind(RemoteMessage message) {
    final hasNotification = message.notification != null;
    final hasData = message.data.isNotEmpty;
    if (hasNotification && hasData) {
      return 'mixed';
    }
    if (hasNotification) {
      return 'notification-only';
    }
    if (hasData) {
      return 'data-only';
    }
    return 'empty';
  }

  static void _handleLocalNotificationResponse(
    NotificationResponse response,
  ) {
    final payload = response.payload;
    if (payload == null || payload.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        _handleNotificationTap(Map<String, dynamic>.from(decoded));
      }
    } catch (error) {
      debugPrint(
          '[PushNotificationService] Invalid notification payload: $error');
    }
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    final type = _readString(data, 'type').toUpperCase();
    if (type != 'SOS' && type != 'EMERGENCY_AUDIO') {
      return;
    }

    _openReports(data);
  }

  static void _openReports(Map<String, dynamic> data) {
    final navigatorState = ApiService.navigatorKey.currentState;
    final navigatorContext = ApiService.navigatorKey.currentContext;
    if (navigatorState == null || navigatorContext == null) {
      _pendingNavigationData = data;
      return;
    }

    final child = _resolveChild(navigatorContext, data);
    navigatorState.push(
      MaterialPageRoute(
        builder: (_) => ReportsScreen(child: child),
      ),
    );
  }

  static ChildModel _resolveChild(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final childId = _readString(data, 'childId');
    if (childId.isNotEmpty) {
      try {
        final childProvider = context.read<ChildProvider>();
        final existingChild = childProvider.getChildById(childId);
        if (existingChild != null) {
          return existingChild;
        }
      } on ProviderNotFoundException {
        // Fall back to payload data below.
      }
    }

    return ChildModel(
      id: childId.isEmpty ? 'notification-child' : childId,
      name: _readString(data, 'childName').isEmpty
          ? 'الطفل'
          : _readString(data, 'childName'),
      birthDate: DateTime.now()
          .subtract(const Duration(days: 365 * 7))
          .toIso8601String()
          .split('T')
          .first,
      gender: 0,
      deviceId: _readString(data, 'deviceId'),
    );
  }

  static String _readString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }
}
