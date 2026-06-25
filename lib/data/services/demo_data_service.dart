import 'dart:async';
import 'dart:math';

/// Service de données simulées pour tester l'app sans device BLE physique
class DemoDataService {
  static Stream<Map<String, dynamic>> simulateData() async* {
    final random = Random();
    double spo2 = 96.0;
    double hr = 74.0;
    double temp = 36.7;
    int tick = 0;

    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      tick++;

      // Variations réalistes avec bruit gaussien
      spo2 = (spo2 + (random.nextDouble() - 0.5) * 0.8).clamp(93.0, 99.5);
      hr = (hr + (random.nextDouble() - 0.5) * 3).clamp(62.0, 98.0);
      temp = (temp + (random.nextDouble() - 0.5) * 0.15).clamp(36.2, 37.4);

      // Légère tendance sinusoïdale pour la FC (simulation battements)
      final hrVariation = 2.0 * sin(tick * 0.3);
      final hrFinal = (hr + hrVariation).clamp(60.0, 100.0);

      yield {
        'SPO2': double.parse(spo2.toStringAsFixed(1)),
        'HR': hrFinal.round().toDouble(),
        'TEMP': double.parse(temp.toStringAsFixed(1)),
        'STATUS': tick < 3 ? 'FINGER_ON' : 'READY',
      };
    }
  }
}
