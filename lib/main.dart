import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

// Screens
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/user/user_dashboard.dart';
import 'screens/user/report_lost_screen.dart';
import 'screens/user/report_found_screen.dart';
import 'screens/user/my_reports_screen.dart';
import 'screens/user/notifications_screen.dart';
import 'screens/verifier/verifier_dashboard.dart';
import 'screens/verifier/item_verification_screen.dart';
import 'screens/admin/admin_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local notifications
  await NotificationService().initialize();

  runApp(const CampusLostFoundApp());
}

class CampusLostFoundApp extends StatelessWidget {
  const CampusLostFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: OverlaySupport.global(
        child: MaterialApp(
          title: 'CampusRetrieve',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: '/',
          routes: {
            '/': (_) => const SplashScreen(),
            '/login': (_) => const LoginScreen(),
            '/verify-email': (_) => const VerifyEmailScreen(),
            '/user': (_) => const UserDashboard(),
            '/report-lost': (_) => const ReportLostScreen(),
            '/report-found': (_) => const ReportFoundScreen(),
            '/my-reports': (_) => const MyReportsScreen(),
            '/notifications': (_) => const NotificationsScreen(),
            '/verifier': (_) => const VerifierDashboard(),
            '/verify-item': (_) => const ItemVerificationScreen(),
            '/admin': (_) => const AdminDashboard(),
          },
        ),
      ),
    );
  }
}
