import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:malaz_app/providers/chatbot_provider.dart';
import 'package:malaz_app/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malaz_app/helpers/shared_prefs.dart';
import 'package:malaz_app/providers/auth_provider.dart';
import 'package:malaz_app/providers/child_provider.dart';
import 'package:malaz_app/providers/safezone_provider.dart';
import 'package:malaz_app/screens/splash_screen.dart';
import 'package:malaz_app/services/api_service.dart';
import 'package:malaz_app/services/push_notification_service.dart';
import 'package:malaz_app/utils/platform_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefs.init();
  if (!kIsWeb && isAndroidPlatform) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChildProvider()),
        ChangeNotifierProvider(create: (_) => SafeZoneProvider()),
        // ✅ إضافة NotificationsProvider
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => ChatbotProvider()),
      ],
      child: const MyApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      PushNotificationService.initialize().then(
        (_) => PushNotificationService.handlePendingNavigation(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: ApiService.navigatorKey,
      scaffoldMessengerKey: ApiService.scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Malaz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.cairoTextTheme(),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
