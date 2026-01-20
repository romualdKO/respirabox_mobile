import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/firebase_config.dart';
import 'core/config/theme_config.dart';
import 'routes/app_routes.dart';

/// 🚀 POINT D'ENTRÉE DE L'APPLICATION RESPIRABOX
void main() async {
  // ✅ Initialisation des services Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialisation de Firebase
  await Firebase.initializeApp(
    options: FirebaseConfig.firebaseOptions,
  );

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
