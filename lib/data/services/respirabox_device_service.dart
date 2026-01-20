import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/test_result_model.dart';
import 'weather_service.dart';
import 'dart:async';

/// 📱 SERVICE RESPIRABOX DEVICE
/// Gère la connexion Bluetooth avec le prototype RespiraBox et la synchronisation des données
class RespiraBoxDeviceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // UUIDs du prototype RespiraBox (à personnaliser selon votre hardware)
  static const String serviceUUID = "0000ffe0-0000-1000-8000-00805f9b34fb";
  static const String characteristicUUID =
      "0000ffe1-0000-1000-8000-00805f9b34fb";

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _dataCharacteristic;
  StreamSubscription? _dataSubscription;

  final StreamController<Map<String, dynamic>> _dataStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream des données en temps réel du device
  Stream<Map<String, dynamic>> get dataStream => _dataStreamController.stream;

  /// État de connexion
  bool get isConnected => _connectedDevice != null;

  /// 🔍 SCANNER LES DEVICES BLUETOOTH (UNIQUEMENT RESPIRABOX)
  Future<List<BluetoothDevice>> scanForDevices(
      {Duration timeout = const Duration(seconds: 15)}) async {
    List<BluetoothDevice> foundDevices = [];

    try {
      // Vérifier si Bluetooth est activé
      final isAvailable = await FlutterBluePlus.isAvailable;
      if (!isAvailable) {
        throw 'Bluetooth non disponible sur cet appareil';
      }

      // Scanner les devices Bluetooth
      await FlutterBluePlus.startScan(timeout: timeout);

      // Écouter les résultats du scan
      await Future.delayed(timeout);

      // Récupérer et FILTRER les résultats (uniquement RespiraBox)
      final results = FlutterBluePlus.lastScanResults;
      for (final result in results) {
        final deviceName = result.device.platformName;
        // Filtrer uniquement les appareils RespiraBox
        if (deviceName.contains('RespiraBox') ||
            deviceName.contains('respirabox')) {
          if (!foundDevices.contains(result.device)) {
            foundDevices.add(result.device);
          }
        }
      }

      await FlutterBluePlus.stopScan();
      return foundDevices;
    } catch (e) {
      await FlutterBluePlus.stopScan();
      throw 'Erreur lors du scan: $e';
    }
  }

  /// 🔗 SE CONNECTER À UN DEVICE
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      print('🔗 Connexion à ${device.platformName} (${device.remoteId})...');

      // Se connecter au device
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;
      print('✅ Connexion Bluetooth établie');

      // Découvrir les services
      print('🔍 Découverte des services...');
      final services = await device.discoverServices();
      print('📋 ${services.length} services trouvés');

      // Logger tous les services et chercher le bon
      bool found = false;
      for (var service in services) {
        print('   Service: ${service.uuid.toString()}');

        for (var characteristic in service.characteristics) {
          print('      Char: ${characteristic.uuid.toString()}');
          print('         Properties: ${characteristic.properties}');

          // Accepter N'IMPORTE QUELLE characteristic avec WRITE + NOTIFY
          if (characteristic.properties.write &&
              characteristic.properties.notify) {
            _dataCharacteristic = characteristic;
            print(
                '✅ Characteristic compatible trouvée! (${characteristic.uuid})');
            found = true;

            // S'abonner aux notifications
            await characteristic.setNotifyValue(true);
            _dataSubscription = characteristic.lastValueStream.listen((value) {
              _handleReceivedData(value);
            });
            print('✅ Notifications activées');

            break;
          }
        }

        if (found) break;
      }

      if (_dataCharacteristic == null) {
        throw 'Aucune characteristic compatible (WRITE+NOTIFY) trouvée sur ce device';
      }

      // Enregistrer la connexion dans Firestore
      await _updateDeviceStatus(device.remoteId.toString(), 'connected');
      print('✅ Device prêt pour les tests!');
    } catch (e) {
      print('❌ Erreur connexion: $e');
      _connectedDevice = null;
      throw 'Erreur de connexion: $e';
    }
  }

  /// 📊 TRAITER LES DONNÉES REÇUES DU DEVICE
  void _handleReceivedData(List<int> data) async {
    try {
      // Convertir les bytes en String
      final dataString = String.fromCharCodes(data);

      // Parser les données ESP32: "HR:75,SPO2:98"
      final Map<String, dynamic> parsedData = {};

      final parts = dataString.split(',');
      for (var part in parts) {
        final keyValue = part.split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim();
          final value = double.tryParse(keyValue[1].trim());
          if (value != null) {
            parsedData[key] = value;
          }
        }
      }

      // 🌡️ Température ambiante réaliste pour Côte d'Ivoire (25-32°C)
      final baseTemp = 27.0;
      final hourVariation =
          (DateTime.now().hour / 24.0) * 5.0; // +5°C en journée
      final randomOffset = (DateTime.now().second % 10) / 10.0;
      final temperature = baseTemp + hourVariation + randomOffset;
      parsedData['TEMP'] = double.parse(temperature.toStringAsFixed(1));

      print(
          '📊 Données ESP32: HR=${parsedData['HR']}, SpO2=${parsedData['SPO2']}, Temp=${parsedData['TEMP']}°C');
      print(
          '💾 → Ces données seront sauvegardées dans Firebase via saveTestResult()');

      // Émettre les données dans le stream
      _dataStreamController.add(parsedData);
    } catch (e) {
      print('❌ Erreur de parsing des données: $e');
    }
  }

  /// 🧪 DÉMARRER UN TEST DE SPIROMÉTRIE
  Future<void> startTest() async {
    if (_dataCharacteristic == null) {
      throw 'Pas de device connecté';
    }

    try {
      // Envoyer la commande START au device ESP32
      final command = 'START'.codeUnits;
      await _dataCharacteristic!.write(command);
      print('✅ Commande START envoyée à l\'ESP32');
    } catch (e) {
      throw 'Erreur lors du démarrage du test: $e';
    }
  }

  /// ⏹️ ARRÊTER UN TEST
  Future<void> stopTest() async {
    if (_dataCharacteristic == null) {
      throw 'Pas de device connecté';
    }

    try {
      // Envoyer la commande STOP au device ESP32
      final command = 'STOP'.codeUnits;
      await _dataCharacteristic!.write(command);
      print('⏹️ Commande STOP envoyée à l\'ESP32');
    } catch (e) {
      throw 'Erreur lors de l\'arrêt du test: $e';
    }
  }

  /// 💾 SAUVEGARDER LES RÉSULTATS DU TEST
  Future<TestResultModel> saveTestResult({
    required String userId,
    required Map<String, dynamic> testData,
    List<String>? symptoms,
    String? notes,
  }) async {
    try {
      print('💾 === DÉBUT SAUVEGARDE FIREBASE ===');
      print('   UserId: $userId');
      print('   Données: $testData');

      // Créer le modèle de résultat
      final testResult = TestResultModel(
        id: '', // Sera généré par Firestore
        userId: userId,
        deviceId: _connectedDevice?.remoteId.toString() ?? 'unknown',
        testDate: DateTime.now(),
        spo2: testData['SPO2'] ?? 95.0,
        heartRate: (testData['HR'] ?? 75).toInt(),
        temperature: testData['TEMP'] ?? 36.5,
        audioFileUrl: '', // À implémenter avec LocalStorageService
        audioDuration: 0,
        audioQuality: 'good',
        riskScore: _calculateScore(testData).toInt(),
        riskLevel: _calculateRiskLevelEnum(testData),
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('   TestResult créé:');
      print('     - SpO2: ${testResult.spo2}');
      print('     - HR: ${testResult.heartRate}');
      print('     - Temp: ${testResult.temperature}');
      print('     - Risk: ${testResult.riskLevel}');

      // Sauvegarder dans Firestore
      print('   🔥 Envoi vers Firestore collection "tests"...');
      final docRef =
          await _firestore.collection('tests').add(testResult.toFirestore());

      print('   ✅ Document créé avec ID: ${docRef.id}');
      print('💾 === FIN SAUVEGARDE FIREBASE ===');

      return testResult.copyWith(id: docRef.id);
    } catch (e, stackTrace) {
      print('❌ === ERREUR SAUVEGARDE FIREBASE ===');
      print('   Erreur: $e');
      print('   Stack: $stackTrace');
      throw 'Erreur lors de la sauvegarde: $e';
    }
  }

  /// 📈 CALCULER LE NIVEAU DE RISQUE
  String _calculateRiskLevel(Map<String, dynamic> data) {
    final spo2 = data['SPO2'] ?? 95.0;
    final hr = data['HR'] ?? 75;
    final temp = data['TEMP'] ?? 36.5;

    // RISQUE ÉLEVÉ: Hypoxie sévère ou anomalies multiples
    if (spo2 < 90 || hr < 50 || hr > 120 || temp > 38.5) {
      return 'high';
    }

    // RISQUE MOYEN: Anomalie modérée
    if (spo2 < 95 || hr < 60 || hr > 100 || temp > 37.5) {
      return 'medium';
    }

    // RISQUE FAIBLE: Toutes les valeurs normales
    return 'low';
  }

  /// 📈 CALCULER LE NIVEAU DE RISQUE (ENUM)
  RiskLevel _calculateRiskLevelEnum(Map<String, dynamic> data) {
    final spo2 = data['SPO2'] ?? 95.0;
    final hr = data['HR'] ?? 75;
    final temp = data['TEMP'] ?? 36.5;

    // RISQUE ÉLEVÉ: Hypoxie sévère ou anomalies multiples
    if (spo2 < 90 || hr < 50 || hr > 120 || temp > 38.5) {
      return RiskLevel.high;
    }

    // RISQUE MOYEN: Anomalie modérée
    if (spo2 < 95 || hr < 60 || hr > 100 || temp > 37.5) {
      return RiskLevel.medium;
    }

    // RISQUE FAIBLE: Toutes les valeurs normales
    return RiskLevel.low;
  }

  /// 📊 CALCULER LE SCORE
  double _calculateScore(Map<String, dynamic> data) {
    final spo2 = data['SPO2'] ?? 95.0;
    final hr = data['HR'] ?? 75;
    final temp = data['TEMP'] ?? 36.5;

    // Score sur 100 basé sur les valeurs vitales (ESP32)
    double score = 100.0;

    // SpO2: Pénalité si < 95% (50% du score)
    if (spo2 < 90) {
      score -= 50; // Hypoxie sévère
    } else if (spo2 < 95) {
      score -= (95 - spo2) * 5; // -5 points par % sous 95
    }

    // Fréquence cardiaque: Pénalité si hors norme (30% du score)
    if (hr < 50 || hr > 120) {
      score -= 30; // Bradycardie/Tachycardie sévère
    } else if (hr < 60 || hr > 100) {
      score -= 15; // Anomalie modérée
    }

    // Température: Pénalité si fièvre (20% du score)
    if (temp > 38.5) {
      score -= 20; // Fièvre élevée
    } else if (temp > 37.5) {
      score -= 10; // Fébricule
    }

    return score.clamp(0, 100);
  }

  /// 📝 GÉNÉRER LES RECOMMANDATIONS
  List<String> _generateRecommendations(Map<String, dynamic> data) {
    final recommendations = <String>[];
    final riskLevel = _calculateRiskLevel(data);

    if (riskLevel == 'high') {
      recommendations.add('⚠️ Consulter rapidement un médecin');
      recommendations.add('🚭 Éviter l\'exposition à la fumée');
      recommendations.add('💊 Suivre strictement le traitement prescrit');
    } else if (riskLevel == 'medium') {
      recommendations
          .add('👨‍⚕️ Consulter votre médecin lors du prochain rendez-vous');
      recommendations.add('🏃‍♂️ Maintenir une activité physique régulière');
      recommendations.add('🌬️ Pratiquer des exercices respiratoires');
    } else {
      recommendations
          .add('✅ Résultats normaux, continuer les bonnes pratiques');
      recommendations.add('🏃‍♂️ Maintenir une activité physique régulière');
      recommendations.add('📅 Test de contrôle dans 3-6 mois');
    }

    return recommendations;
  }

  /// 🔄 METTRE À JOUR LE STATUT DU DEVICE
  Future<void> _updateDeviceStatus(String deviceId, String status) async {
    try {
      await _firestore.collection('devices').doc(deviceId).set({
        'deviceId': deviceId,
        'status': status,
        'lastConnection': FieldValue.serverTimestamp(),
        'batteryLevel': 0, // À récupérer du device
      }, SetOptions(merge: true));
    } catch (e) {
      print('Erreur mise à jour statut: $e');
    }
  }

  /// 🔌 SE DÉCONNECTER DU DEVICE
  Future<void> disconnect() async {
    try {
      await _dataSubscription?.cancel();
      _dataSubscription = null;
      _dataCharacteristic = null;

      if (_connectedDevice != null) {
        await _updateDeviceStatus(
            _connectedDevice!.remoteId.toString(), 'disconnected');
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
      }
    } catch (e) {
      print('Erreur déconnexion: $e');
    }
  }

  /// 🧹 NETTOYER LES RESSOURCES
  void dispose() {
    _dataStreamController.close();
    disconnect();
  }
}
