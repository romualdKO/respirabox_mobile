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
  static const String characteristicUUID = "0000ffe1-0000-1000-8000-00805f9b34fb";
  
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _dataCharacteristic;
  StreamSubscription? _dataSubscription;
  
  final StreamController<Map<String, dynamic>> _dataStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  /// Stream des données en temps réel du device
  Stream<Map<String, dynamic>> get dataStream => _dataStreamController.stream;
  
  /// État de connexion
  bool get isConnected => _connectedDevice != null;

  /// 🔍 SCANNER LES DEVICES RESPIRABOX
  Future<List<BluetoothDevice>> scanForDevices({Duration timeout = const Duration(seconds: 10)}) async {
    List<BluetoothDevice> foundDevices = [];
    
    try {
      // Vérifier si Bluetooth est activé
      final isAvailable = await FlutterBluePlus.isAvailable;
      if (!isAvailable) {
        throw 'Bluetooth non disponible sur cet appareil';
      }

      // Scanner les devices
      await FlutterBluePlus.startScan(timeout: timeout);
      
      // Écouter les résultats du scan
      final scanResults = FlutterBluePlus.scanResults;
      
      await for (final results in scanResults) {
        for (final result in results) {
          // Filtrer uniquement les RespiraBox (selon le nom ou UUID)
          if (result.device.platformName.contains('RespiraBox') ||
              result.advertisementData.serviceUuids.contains(serviceUUID)) {
            if (!foundDevices.contains(result.device)) {
              foundDevices.add(result.device);
            }
          }
        }
        
        // Arrêter après timeout
        if (foundDevices.isNotEmpty) break;
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
      // Se connecter au device
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;

      // Découvrir les services
      final services = await device.discoverServices();
      
      // Trouver le service RespiraBox
      for (var service in services) {
        if (service.uuid.toString() == serviceUUID) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == characteristicUUID) {
              _dataCharacteristic = characteristic;
              
              // S'abonner aux notifications
              await characteristic.setNotifyValue(true);
              _dataSubscription = characteristic.lastValueStream.listen((value) {
                _handleReceivedData(value);
              });
              
              break;
            }
          }
        }
      }

      if (_dataCharacteristic == null) {
        throw 'Service RespiraBox non trouvé sur ce device';
      }

      // Enregistrer la connexion dans Firestore
      await _updateDeviceStatus(device.remoteId.toString(), 'connected');
      
    } catch (e) {
      _connectedDevice = null;
      throw 'Erreur de connexion: $e';
    }
  }

  /// 📊 TRAITER LES DONNÉES REÇUES DU DEVICE
  void _handleReceivedData(List<int> data) {
    try {
      // Convertir les bytes en String (protocole à définir selon votre hardware)
      final dataString = String.fromCharCodes(data);
      
      // Parser les données (exemple: format JSON ou CSV)
      // Format exemple: "FEV1:2.5,PEF:350,FVC:3.0,TEMP:36.5,BAT:85"
      final Map<String, dynamic> parsedData = {};
      
      final parts = dataString.split(',');
      for (var part in parts) {
        final keyValue = part.split(':');
        if (keyValue.length == 2) {
          parsedData[keyValue[0].trim()] = double.tryParse(keyValue[1].trim()) ?? 0.0;
        }
      }

      // Émettre les données dans le stream
      _dataStreamController.add(parsedData);
      
    } catch (e) {
      print('Erreur de parsing des données: $e');
    }
  }

  /// 🧪 DÉMARRER UN TEST DE SPIROMÉTRIE
  Future<void> startTest() async {
    if (_dataCharacteristic == null) {
      throw 'Pas de device connecté';
    }

    try {
      // Envoyer la commande START au device
      final command = 'START_TEST'.codeUnits;
      await _dataCharacteristic!.write(command);
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
      // Envoyer la commande STOP au device
      final command = 'STOP_TEST'.codeUnits;
      await _dataCharacteristic!.write(command);
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

      // Sauvegarder dans Firestore
      final docRef = await _firestore.collection('tests').add(testResult.toFirestore());
      
      return testResult.copyWith(id: docRef.id);
    } catch (e) {
      throw 'Erreur lors de la sauvegarde: $e';
    }
  }

  /// 📈 CALCULER LE NIVEAU DE RISQUE
  String _calculateRiskLevel(Map<String, dynamic> data) {
    final fev1 = data['FEV1'] ?? 0.0;
    final fvc = data['FVC'] ?? 0.0;
    
    if (fev1 == 0 || fvc == 0) return 'unknown';
    
    final ratio = (fev1 / fvc) * 100;
    
    if (ratio >= 70 && fev1 >= 2.5) return 'low';
    if (ratio >= 60 && fev1 >= 2.0) return 'medium';
    return 'high';
  }

  /// 📈 CALCULER LE NIVEAU DE RISQUE (ENUM)
  RiskLevel _calculateRiskLevelEnum(Map<String, dynamic> data) {
    final spo2 = data['SPO2'] ?? 95.0;
    final hr = data['HR'] ?? 75;
    
    // Critères simplifiés
    if (spo2 >= 95 && hr >= 60 && hr <= 100) return RiskLevel.low;
    if (spo2 >= 90 && hr >= 50 && hr <= 120) return RiskLevel.medium;
    return RiskLevel.high;
  }

  /// 📊 CALCULER LE SCORE
  double _calculateScore(Map<String, dynamic> data) {
    final fev1 = data['FEV1'] ?? 0.0;
    final pef = data['PEF'] ?? 0.0;
    final fvc = data['FVC'] ?? 0.0;
    
    // Score sur 100 basé sur les valeurs normales
    final fev1Score = (fev1 / 4.0) * 40; // 40% du score
    final pefScore = (pef / 600.0) * 30; // 30% du score
    final fvcScore = (fvc / 5.0) * 30; // 30% du score
    
    return (fev1Score + pefScore + fvcScore).clamp(0, 100);
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
      recommendations.add('👨‍⚕️ Consulter votre médecin lors du prochain rendez-vous');
      recommendations.add('🏃‍♂️ Maintenir une activité physique régulière');
      recommendations.add('🌬️ Pratiquer des exercices respiratoires');
    } else {
      recommendations.add('✅ Résultats normaux, continuer les bonnes pratiques');
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
        await _updateDeviceStatus(_connectedDevice!.remoteId.toString(), 'disconnected');
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
