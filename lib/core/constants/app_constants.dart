import 'package:flutter_dotenv/flutter_dotenv.dart';

/// CONSTANTES GLOBALES DE L'APPLICATION RESPIRABOX
class AppConstants {
  // ── APPLICATION ──────────────────────────────────────────────
  static const String appName     = 'RespiraBox';
  static const String appVersion  = '2.0.0';
  static const String appSubtitle = 'Surveillance Respiratoire';

  // ── SPLASH SCREEN ────────────────────────────────────────────
  static const int splashScreenDuration = 3;

  // ── FIRESTORE — COLLECTIONS ──────────────────────────────────
  static const String usersCollection           = 'users';
  static const String devicesCollection         = 'devices';
  static const String testsCollection           = 'tests';
  static const String conversationsCollection   = 'conversations';
  static const String notificationsCollection   = 'notifications';

  // ── GOOGLE GEMINI AI ─────────────────────────────────────────
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String geminiModel = 'gemini-2.0-flash';

  // ── COHERE AI (fallback) ──────────────────────────────────────
  static String get cohereApiKey =>
      dotenv.env['COHERE_API_KEY'] ?? '';
  static const String cohereApiUrl = 'https://api.cohere.ai/v1/chat';

  // ── ASSEMBLYAI ───────────────────────────────────────────────
  static String get assemblyAiApiKey =>
      dotenv.env['ASSEMBLYAI_API_KEY'] ?? '';

  // ── OPENWEATHERMAP ───────────────────────────────────────────
  static String get openWeatherApiKey =>
      dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  static const String openWeatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';
  static const double defaultLatitude  = 5.3484; // Abidjan, Côte d'Ivoire
  static const double defaultLongitude = -4.0167;

  // ── TEST RESPIRATOIRE ────────────────────────────────────────
  static const int testDurationSeconds = 30;
  static const int testSteps           = 4;
  static const List<String> testStepTitles = [
    'Préparation',
    'Positionnement',
    'Respiration',
    'Analyse',
  ];

  // ── BLUETOOTH ────────────────────────────────────────────────
  static const String respiraBoxDevicePrefix = 'RespiraBox';
  static const int    bluetoothScanDuration  = 15;

  // ── LIMITES UI ───────────────────────────────────────────────
  static const int maxChatMessages  = 50;
  static const int maxTestHistory   = 100;
  static const int minPasswordLength = 8;

  // ── SEUILS MÉDICAUX ──────────────────────────────────────────
  static const double spo2Normal    = 95.0;
  static const double tempNormal    = 37.5;
  static const double tempFever     = 38.5;
  static const int    pulseNormalMin = 60;
  static const int    pulseNormalMax = 100;

  // ── SCORES DE RISQUE ─────────────────────────────────────────
  static const double riskLowThreshold    = 30.0;
  static const double riskMediumThreshold = 70.0;

  // ── LOCALISATION ─────────────────────────────────────────────
  static const String defaultCountryCode = '+225';
  static const String defaultLanguage    = 'fr';

  // ── DÉLAIS ───────────────────────────────────────────────────
  static const int debounceDelay = 500;
}
