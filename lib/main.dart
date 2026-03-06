import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'register.dart';
import 'services/notification_service.dart';
import 'notifications_screen.dart';
import 'view_my_reports.dart';
import 'service_request.dart';
import 'community_news.dart';
import 'barangay_information.dart';
import 'homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize notification service after user logs in
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        NotificationService().initialize();
      }
    });
    
    runApp(const MyApp());
  } catch (e) {
    // If Firebase initialization fails, show error screen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text(
                    'Failed to initialize app',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Error: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupNotificationNavigation();
  }

  void _setupNotificationNavigation() {
    // Set up notification tap handler
    NotificationService().onNotificationTap = (type, actionId, data) {
      // Navigate to appropriate screen based on notification type
      String? route;
      switch (type) {
        case 'report':
          route = '/view_my_reports';
          break;
        case 'service':
          route = '/view_my_reports';
          break;
        case 'supplies':
          route = '/view_my_reports';
          break;
        case 'news':
          route = '/community_news';
          break;
        case 'barangay_info':
          route = '/barangay_information';
          break;
      }

      if (route != null) {
        navigatorKey.currentState?.pushNamed(route);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Komunidad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF10B981),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/register': (context) => const RegisterPage(),
        '/notifications': (context) => const NotificationsScreen(),
        '/view_my_reports': (context) => const ViewMyReportsPage(),
        '/service_request': (context) => const ServiceRequestPage(),
        '/community_news': (context) => const CommunityNewsPage(),
        '/barangay_information': (context) => const BarangayInformationPage(),
        '/homepage': (context) => const HomePage(),
      },
    );
  }
}
