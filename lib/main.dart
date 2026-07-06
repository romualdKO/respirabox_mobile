import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/firebase_config.dart';
import 'core/config/theme_config.dart';
import 'data/services/notification_service.dart';
import 'routes/app_routes.dart';

/// POINT D'ENTRÉE DE L'APPLICATION RESPIRABOX
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Chargement des clés API depuis .env
  await dotenv.load(fileName: '.env');

  // Initialisation Firebase
  await Firebase.initializeApp(
    options: FirebaseConfig.firebaseOptions,
  );

  // Initialisation FCM (notifications push)
  await NotificationService().initFCM();

  // 🌍 Données de date localisées (français) — requis pour DateFormat('fr_FR')
  await initializeDateFormatting('fr_FR', null);

  // 📱 Configuration de l'orientation (portrait uniquement)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 🎨 Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 🚀 Lancement de l'application avec Riverpod
  runApp(
    const ProviderScope(
      child: RespiraBoxApp(),
    ),
  );
}

/// 🏠 APPLICATION PRINCIPALE
class RespiraBoxApp extends StatelessWidget {
  const RespiraBoxApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 📝 Configuration de l'application
      title: 'RespiraBox',
      debugShowCheckedModeBanner: false, // Masquer le bandeau "DEBUG"

      // 🎨 Thème
      theme: ThemeConfig.lightTheme,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: ThemeMode.light, // Mode clair par défaut

      // 🧭 Navigation
      initialRoute: AppRoutes.splash, // Démarre sur le splash screen
      onGenerateRoute: AppRoutes.generateRoute,

      // 🌍 Localisation (français)
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'), // Français (prioritaire)
        Locale('en', 'US'), // Anglais (optionnel)
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
