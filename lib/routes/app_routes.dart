import 'package:flutter/material.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/welcome/welcome_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/home/main_home_screen.dart';
import '../presentation/screens/device/device_scan_screen.dart';
import '../presentation/screens/test/test_preparation_screen.dart';
import '../presentation/screens/test/test_execution_screen.dart';
import '../presentation/screens/test/test_results_screen.dart';
import '../presentation/screens/chatbot/chatbot_screen.dart';
import '../presentation/screens/notifications/notifications_screen.dart';
import '../presentation/screens/support/support_screens.dart';
import '../presentation/screens/analysis/cough_analysis_results_screen.dart';

/// 🧭 GESTIONNAIRE DE ROUTES DE L'APPLICATION RESPIRABOX
/// Définit toutes les routes de navigation
class AppRoutes {
  // 🏠 ROUTES PRINCIPALES
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';

  // 🔐 AUTHENTIFICATION
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // 📱 ÉCRANS PRINCIPAUX
  static const String home = '/home';
  static const String profile = '/profile';
  static const String notifications = '/notifications';

  // 📶 CONNEXION BOÎTIER
  static const String deviceScan = '/device-scan';
  static const String deviceConnection = '/device-connection';
  static const String wifiSetup = '/wifi-setup';
  static const String connectionStatus = '/connection-status';

  // 🫁 TEST RESPIRATOIRE
  static const String testPreparation = '/test-preparation';
  static const String testExecution = '/test-execution';
  static const String testResults = '/test-results';

  // 📊 HISTORIQUE
  static const String history = '/history';
  static const String historyDetail = '/history-detail';

  // �‍⚕️ ANALYSE MÉDICALE
  static const String coughAnalysisResults = '/cough-analysis-results';

  // �💬 CHATBOT IA
  static const String chatbot = '/chatbot';

  // 📚 SUPPORT
  static const String help = '/help';
  static const String privacy = '/privacy';
  static const String terms = '/terms';
  static const String about = '/about';

  // 🌍 DONNÉES ENVIRONNEMENTALES
  static const String environmental = '/environmental';

  /// Générateur de routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const MainHomeScreen());

      case deviceScan:
        return MaterialPageRoute(builder: (_) => const DeviceScanScreen());

      case testPreparation:
        return MaterialPageRoute(builder: (_) => const TestPreparationScreen());

      case testExecution:
        return MaterialPageRoute(builder: (_) => const TestExecutionScreen());

      case testResults:
        return MaterialPageRoute(builder: (_) => const TestResultsScreen());

      case chatbot:
        return MaterialPageRoute(builder: (_) => const ChatbotScreen());

      case coughAnalysisResults:
        return MaterialPageRoute(
          builder: (_) => const CoughAnalysisResultsScreen(),
          settings: settings,
        );

      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case help:
        return MaterialPageRoute(builder: (_) => const HelpScreen());

      case privacy:
        return MaterialPageRoute(builder: (_) => const PrivacyScreen());

      case terms:
        return MaterialPageRoute(builder: (_) => const TermsScreen());

      case about:
        return MaterialPageRoute(builder: (_) => const AboutScreen());

      // TODO: Ajouter les autres routes au fur et à mesure du développement

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Erreur')),
            body: Center(
              child: Text('Route "${settings.name}" introuvable'),
            ),
          ),
        );
    }
  }
}
