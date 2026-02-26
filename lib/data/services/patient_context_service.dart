import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 📊 SERVICE CONTEXTE PATIENT
///
/// Sauvegarde et récupère les données vitales récentes du patient
/// pour utilisation dans l'analyse de toux
class PatientContextService {
  static const String _keyLatestVitals = 'latest_patient_vitals';
  static const String _keyPatientProfile = 'patient_profile';

  /// 💾 Sauvegarder les mesures vitales récentes
  ///
  /// Appelé après chaque test ESP32 pour mémoriser:
  /// - SpO2 (%)
  /// - Température (°C)
  /// - Fréquence cardiaque (BPM)
  /// - Date de la mesure
  static Future<void> saveLatestVitals({
    required double spo2,
    required double temperature,
    required int heartRate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final vitalsData = {
        'spo2': spo2,
        'temperature': temperature,
        'heartRate': heartRate,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_keyLatestVitals, jsonEncode(vitalsData));

      print('✅ Mesures vitales sauvegardées:');
      print('   SpO2: $spo2%');
      print('   Température: $temperature°C');
      print('   Fréquence cardiaque: $heartRate bpm');
    } catch (e) {
      print('❌ Erreur sauvegarde mesures vitales: $e');
    }
  }

  /// 📖 Récupérer les mesures vitales récentes
  ///
  /// Retourne null si:
  /// - Aucune mesure sauvegardée
  /// - Mesures trop anciennes (>24h)
  static Future<Map<String, dynamic>?> getLatestVitals({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vitalsJson = prefs.getString(_keyLatestVitals);

      if (vitalsJson == null) {
        print('ℹ️ Aucune mesure vitale récente trouvée');
        return null;
      }

      final vitalsData = jsonDecode(vitalsJson) as Map<String, dynamic>;
      final timestamp = DateTime.parse(vitalsData['timestamp'] as String);

      // Vérifier si les mesures ne sont pas trop anciennes
      final age = DateTime.now().difference(timestamp);
      if (age > maxAge) {
        print('⚠️ Mesures vitales trop anciennes (${age.inHours}h)');
        return null;
      }

      print('✅ Mesures vitales récupérées (${age.inMinutes}min):');
      print('   SpO2: ${vitalsData['spo2']}%');
      print('   Température: ${vitalsData['temperature']}°C');
      print('   Fréquence cardiaque: ${vitalsData['heartRate']} bpm');

      return vitalsData;
    } catch (e) {
      print('❌ Erreur récupération mesures vitales: $e');
      return null;
    }
  }

  /// 🗑️ Effacer les mesures vitales
  static Future<void> clearLatestVitals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLatestVitals);
      print('✅ Mesures vitales effacées');
    } catch (e) {
      print('❌ Erreur effacement mesures vitales: $e');
    }
  }

  /// 👤 Sauvegarder le profil patient
  ///
  /// Informations démographiques et médicales:
  /// - Âge
  /// - Genre
  /// - Conditions médicales (VIH, asthme, BPCO, diabète)
  static Future<void> savePatientProfile({
    required int age,
    required String gender,
    List<String> medicalConditions = const [],
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final profileData = {
        'age': age,
        'gender': gender,
        'medicalConditions': medicalConditions,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_keyPatientProfile, jsonEncode(profileData));

      print('✅ Profil patient sauvegardé:');
      print('   Âge: $age ans');
      print('   Genre: $gender');
      print('   Conditions: ${medicalConditions.join(", ")}');
    } catch (e) {
      print('❌ Erreur sauvegarde profil patient: $e');
    }
  }

  /// 📖 Récupérer le profil patient
  static Future<Map<String, dynamic>?> getPatientProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_keyPatientProfile);

      if (profileJson == null) {
        print('ℹ️ Aucun profil patient trouvé');
        return null;
      }

      final profileData = jsonDecode(profileJson) as Map<String, dynamic>;

      print('✅ Profil patient récupéré:');
      print('   Âge: ${profileData['age']} ans');
      print('   Genre: ${profileData['gender']}');

      return profileData;
    } catch (e) {
      print('❌ Erreur récupération profil patient: $e');
      return null;
    }
  }

  /// 🔍 Construire contexte patient complet
  ///
  /// Combine profil + mesures vitales récentes
  /// pour utilisation dans analyse de toux
  static Future<Map<String, dynamic>> buildPatientContext() async {
    final context = <String, dynamic>{};

    // Récupérer profil
    final profile = await getPatientProfile();
    if (profile != null) {
      context['age'] = profile['age'];
      context['gender'] = profile['gender'];
      context['medicalConditions'] = profile['medicalConditions'] ?? [];
    }

    // Récupérer mesures vitales récentes
    final vitals = await getLatestVitals();
    if (vitals != null) {
      context['spo2'] = vitals['spo2'];
      context['temperature'] = vitals['temperature'];
      context['heartRate'] = vitals['heartRate'];
      context['vitalsAge'] = DateTime.now()
          .difference(DateTime.parse(vitals['timestamp'] as String))
          .inMinutes;
    }

    print('🔍 Contexte patient construit: ${context.keys.join(", ")}');

    return context;
  }

  /// ⏰ Obtenir âge des mesures vitales
  static Future<Duration?> getVitalsAge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vitalsJson = prefs.getString(_keyLatestVitals);

      if (vitalsJson == null) return null;

      final vitalsData = jsonDecode(vitalsJson) as Map<String, dynamic>;
      final timestamp = DateTime.parse(vitalsData['timestamp'] as String);

      return DateTime.now().difference(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// ✅ Vérifier si mesures récentes disponibles
  static Future<bool> hasRecentVitals({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final vitals = await getLatestVitals(maxAge: maxAge);
    return vitals != null;
  }
}
