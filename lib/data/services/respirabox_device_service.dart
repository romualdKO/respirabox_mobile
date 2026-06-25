import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/test_result_model.dart';
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

  // Stream des statuts envoyés par l'Arduino (STATUS:FINGER_ON, STATUS:READY, etc.)
  final StreamController<String> _statusStreamController =
      StreamController<String>.broadcast();

  /// Stream des données en temps réel du device
  Stream<Map<String, dynamic>> get dataStream => _dataStreamController.stream;

  /// Stream des événements de statut Arduino
  Stream<String> get statusStream => _statusStreamController.stream;

  /// État de connexion
  bool get isConnected => _connectedDevice != null;

  /// 🔍 SCANNER TOUS LES DEVICES BLUETOOTH
  Future<List<ScanResult>> scanForDevices(
      {Duration timeout = const Duration(seconds: 15)}) async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw 'Bluetooth non disponible ou éteint';
      }

      // Démarrer le scan et ATTENDRE sa fin (timeout inclus)
      await FlutterBluePlus.startScan(timeout: timeout);
      await FlutterBluePlus.isScanning
          .where((scanning) => scanning == false)
          .first;

      // Dédupliquer par remoteId et retourner tous les appareils
      final seen = <String>{};
      final results = <ScanResult>[];
      for (final result in FlutterBluePlus.lastScanResults) {
        final id = result.device.remoteId.toString();
        if (seen.add(id)) {
          results.add(result);
        }
      }
      return results;
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
            _dataSubscription = characteristic.onValueReceived.listen((value) {
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
      final dataString = String.fromCharCodes(data).trim();

      // Messages de statut Arduino → stream dédié (pas de données numériques)
      if (dataString.startsWith('STATUS:') || dataString.startsWith('ERROR:')) {
        print('📡 Arduino status: $dataString');
        _statusStreamController.add(dataString);
        return;
      }

      // Format données : "HR:75,SPO2:98,TEMP:36.7"
      final Map<String, dynamic> parsedData = {};
      final parts = dataString.split(',');
      for (var part in parts) {
        final keyValue = part.split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim();
          final value = double.tryParse(keyValue[1].trim());
          if (value != null) parsedData[key] = value;
        }
      }

      if (parsedData.isEmpty) return;

      if (!parsedData.containsKey('TEMP')) parsedData['TEMP'] = 0.0;

      print('📊 ESP32 → HR=${parsedData['HR']}, SpO2=${parsedData['SPO2']}, T=${parsedData['TEMP']}°C');

      _dataStreamController.add(parsedData);
    } catch (e) {
      print('❌ Erreur parsing BLE: $e');
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
    _statusStreamController.close();
    disconnect();
  }
}
