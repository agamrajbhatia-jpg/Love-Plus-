import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';

import 'providers/app_state.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/romantic_loading_overlay.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/auth_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    await NotificationService.initialize();
    await NotificationService.requestPermissions();
    NotificationService.syncFCMToken();
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: RomanticLoadingOverlay(customMessage: "Oops, something broke our heart... \n${details.exceptionAsString()}"),
    );
  };

  try {
    if (Platform.isIOS) {
      await Purchases.configure(PurchasesConfiguration("appl_your_ios_api_key"));
    } else if (Platform.isAndroid) {
      await Purchases.configure(PurchasesConfiguration("goog_your_android_api_key"));
    }
  } catch (e) {
    debugPrint("RevenueCat init error: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;

  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
        ],
        child: MyApp(hasSeenWelcome: hasSeenWelcome),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool hasSeenWelcome;
  const MyApp({super.key, required this.hasSeenWelcome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Love Plus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B6B),
          secondary: const Color(0xFF4ECDC4),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
        useMaterial3: true,
      ),
      builder: DevicePreview.appBuilder,
      locale: DevicePreview.locale(context),
      home: hasSeenWelcome ? const RootScreen() : const WelcomeScreen(),
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: RomanticLoadingOverlay(customMessage: "Warming up..."));
        }
        
        if (!authSnapshot.hasData) {
          return const AuthScreen();
        }
        
        return _DataInitHandler(uid: authSnapshot.data!.uid);
      }
    );
  }
}

class _DataInitHandler extends StatefulWidget {
  final String uid;
  const _DataInitHandler({required this.uid});

  @override
  State<_DataInitHandler> createState() => _DataInitHandlerState();
}

class _DataInitHandlerState extends State<_DataInitHandler> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (!doc.exists) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
        return;
      }
      
      final data = doc.data() as Map<String, dynamic>? ?? {};
      if (mounted) {
        context.read<AppState>().syncUserFromFirestore(widget.uid, data);
        final isLinked = data['coupleId'] != null;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => isLinked ? const HomeScreen() : const OnboardingScreen()),
        );
      }
    } catch (e) {
      print('Loading Error: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: RomanticLoadingOverlay(customMessage: "Loading your love story..."));
  }
}






