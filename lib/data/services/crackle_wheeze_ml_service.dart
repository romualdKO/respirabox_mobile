import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'mel_spectrogram.dart';

/// 🤖 DÉTECTEUR ML DE CRÉPITEMENTS / SIBILANTS
///
/// Modèle CNN entraîné sur ICBHI 2017 Respiratory Sound Database (6898 cycles
/// respiratoires annotés, 126 patients) — voir ml/README.md pour la
/// méthodologie complète et ses limites.
///
/// ⚠️ LIMITE CONNUE: ICBHI est enregistré au stéthoscope numérique posé sur
/// le thorax, pas au micro de smartphone sur une toux volontaire (décalage
/// de domaine). AUC mesurée sur le jeu de test ICBHI: crackles=0.70,
/// wheezes=0.72 — un signal réel mais modeste, à utiliser comme UN indice
/// parmi d'autres dans le scoring clinique, jamais comme verdict autonome.
class CrackleWheezeMLService {
  static const int _modelSampleRate = 4000;
  static const int _nFft = 256;
  static const int _hopLength = 64;
  static const int _nMels = 64;
  static const double _windowDurationS = 5.0;

  static Interpreter? _interpreter;
  static bool _loadFailed = false;

  static Future<bool> _ensureLoaded() async {
    if (_interpreter != null) return true;
    if (_loadFailed) return false;
    try {
      _interpreter = await Interpreter.fromAsset(
          'assets/models/crackle_wheeze_model.tflite');
      return true;
    } catch (e) {
      print('⚠️ Modèle crackle/wheeze ML indisponible: $e');
      _loadFailed = true;
      return false;
    }
  }

  /// Analyse un enregistrement complet (samples PCM normalisés [-1,1] au
  /// [inputSampleRate] d'origine) et retourne les probabilités agrégées
  /// {crackleProbability, wheezeProbability} sur [0,1].
  ///
  /// Retourne null si le modèle n'a pas pu être chargé (fallback attendu:
  /// heuristique acoustique existante dans AudioFeaturesExtractor).
  static Future<Map<String, double>?> predict(
    List<double> samples, {
    required int inputSampleRate,
  }) async {
    final loaded = await _ensureLoaded();
    if (!loaded || samples.isEmpty) return null;

    final resampled = _resample(samples, inputSampleRate, _modelSampleRate);
    final windowSize = (_modelSampleRate * _windowDurationS).round();

    double maxCrackle = 0.0;
    double maxWheeze = 0.0;
    int windowCount = 0;

    for (int start = 0; start < resampled.length; start += windowSize) {
      final end = min(start + windowSize, resampled.length);
      var chunk = resampled.sublist(start, end);
      if (chunk.length < windowSize) {
        chunk = [...chunk, ...List.filled(windowSize - chunk.length, 0.0)];
      }
      // Ignorer les fenêtres de bruit résiduel trop courtes (<0.5s de vrai signal)
      if (end - start < _modelSampleRate * 0.5) continue;

      final mel = MelSpectrogram(
        sampleRate: _modelSampleRate,
        nFft: _nFft,
        hopLength: _hopLength,
        nMels: _nMels,
      ).computeNormalized(chunk);

      final probs = _runInference(mel);
      if (probs == null) continue;
      maxCrackle = max(maxCrackle, probs[0]);
      maxWheeze = max(maxWheeze, probs[1]);
      windowCount++;
    }

    if (windowCount == 0) return null;
    return {'crackleProbability': maxCrackle, 'wheezeProbability': maxWheeze};
  }

  static List<double>? _runInference(List<List<double>> mel) {
    final interpreter = _interpreter;
    if (interpreter == null) return null;
    try {
      final input = [mel]; // shape [1, nMels, nFrames]
      final output = List.generate(1, (_) => List<double>.filled(2, 0.0));
      interpreter.run(input, output);
      return output[0];
    } catch (e) {
      print('⚠️ Erreur inférence crackle/wheeze: $e');
      return null;
    }
  }

  /// Rééchantillonnage avec filtre passe-bas anti-repliement (sinc fenêtré
  /// Hann) suivi d'une interpolation linéaire — nécessaire car le ratio
  /// 44100→4000 Hz n'est pas entier.
  static List<double> _resample(List<double> input, int fromRate, int toRate) {
    if (fromRate == toRate) return input;

    final filtered = fromRate > toRate
        ? _lowPassFilter(input, fromRate, toRate / 2.0)
        : input;

    final ratio = toRate / fromRate;
    final outputLength = (filtered.length * ratio).round();
    final output = List<double>.filled(outputLength, 0.0);
    for (int i = 0; i < outputLength; i++) {
      final srcPos = i / ratio;
      final srcIndex = srcPos.floor();
      final frac = srcPos - srcIndex;
      if (srcIndex + 1 < filtered.length) {
        output[i] =
            filtered[srcIndex] * (1 - frac) + filtered[srcIndex + 1] * frac;
      } else if (srcIndex < filtered.length) {
        output[i] = filtered[srcIndex];
      }
    }
    return output;
  }

  /// Filtre passe-bas FIR (sinc fenêtré Hann, 63 coefficients) — atténue les
  /// fréquences au-dessus de [cutoffHz] avant décimation pour limiter le
  /// repliement de spectre (aliasing).
  static List<double> _lowPassFilter(
      List<double> input, int sampleRate, double cutoffHz) {
    const numTaps = 63;
    final fc = cutoffHz / sampleRate; // fréquence de coupure normalisée
    final taps = List<double>.filled(numTaps, 0.0);
    final center = (numTaps - 1) / 2.0;

    double sum = 0.0;
    for (int i = 0; i < numTaps; i++) {
      final x = i - center;
      final sinc = x == 0 ? 2 * fc : sin(2 * pi * fc * x) / (pi * x);
      final hann = 0.5 - 0.5 * cos(2 * pi * i / (numTaps - 1));
      taps[i] = sinc * hann;
      sum += taps[i];
    }
    // Normalisation pour gain unitaire en bande passante
    for (int i = 0; i < numTaps; i++) {
      taps[i] /= sum;
    }

    final output = List<double>.filled(input.length, 0.0);
    final half = numTaps ~/ 2;
    for (int i = 0; i < input.length; i++) {
      double acc = 0.0;
      for (int j = 0; j < numTaps; j++) {
        final idx = i + j - half;
        if (idx >= 0 && idx < input.length) {
          acc += input[idx] * taps[j];
        }
      }
      output[i] = acc;
    }
    return output;
  }
}
