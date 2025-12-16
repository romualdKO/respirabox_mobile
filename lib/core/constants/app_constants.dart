/// 🔧 CONSTANTES GLOBALES DE L'APPLICATION RESPIRABOX
class AppConstants {
  // 📱 INFORMATIONS APPLICATION
  static const String appName = 'RespiraBox';
  static const String appVersion = '1.0.0';
  static const String appSubtitle = 'Surveillance Respiratoire';
  
  // ⏱️ SPLASH SCREEN
  static const int splashScreenDuration = 3; // secondes
  
  // 🔥 FIREBASE - COLLECTIONS FIRESTORE
  static const String usersCollection = 'users';
  static const String devicesCollection = 'devices';
  static const String testsCollection = 'user_tests';
  static const String environmentalDataCollection = 'environmental_data';
  static const String chatCollection = 'chat_conversations';
  static const String notificationsCollection = 'notifications';
  static const String alertsCollection = 'system_alerts';
  
  // 🤖 GEMINI AI - Configuration
  static const String geminiApiKey = 'VOTRE_CLE_API_GEMINI'; // ⚠️ À configurer plus tard
  static const String geminiModel = 'gemini-pro';
  
  // 🫁 TEST RESPIRATOIRE - Paramètres
  static const int testDurationSeconds = 10; // Durée du test de souffle
  static const int testSteps = 4; // Nombre d'étapes dans le test
  static const List<String> testStepTitles = [
    'Préparation',
    'Positionnement',
    'Respiration',
    'Analyse'
  ];
  
  // 📶 BLUETOOTH - Configuration
  static const String respiraBoxDevicePrefix = 'RespiraBox'; // Préfixe des boîtiers
  static const int bluetoothScanDuration = 30; // Secondes
  
  // 📊 LIMITES & SEUILS
  static const int maxChatMessages = 50;
  static const int maxTestHistory = 100;
  static const int minPasswordLength = 8;
  
  // 🏥 SEUILS MÉDICAUX (pour analyse des résultats)
  static const double spo2Normal = 95.0; // SpO2 minimum normal (%)
  static const double tempNormal = 37.5; // Température maximum normale (°C)
  static const int pulseNormalMin = 60; // Pouls minimum normal (BPM)
  static const int pulseNormalMax = 100; // Pouls maximum normal (BPM)
  
  // 🚨 SCORES DE RISQUE (%)
  static const double riskLowThreshold = 30.0; // < 30% = Risque faible
  static const double riskMediumThreshold = 70.0; // 30-70% = Risque moyen
  // > 70% = Risque élevé
  
  // 🌍 LOCALISATION (Côte d'Ivoire)
  static const String defaultCountryCode = '+225';
  static const String defaultLanguage = 'fr'; // Français
  
  // ⏱️ DÉLAIS
  static const int debounceDelay = 500; // Millisecondes
}
