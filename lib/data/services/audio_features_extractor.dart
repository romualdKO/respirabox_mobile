import 'dart:io';
import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:scidart/numdart.dart';

/// 🎵 SERVICE EXTRACTION FEATURES ACOUSTIQUES
///
/// Analyse spectrale avancée pour détection TB vs Pneumonie
///
/// FEATURES EXTRAITES:
/// - Frequency (Hz): Fréquence fondamentale du son
/// - Amplitude: Intensité du signal (0-1)
/// - Energy: Énergie RMS du signal
/// - Zero Crossing Rate (ZCR): Transitions signal (dry vs wet indicator)
/// - Spectral Centroid: Centre de gravité spectral
/// - Spectral Rolloff: 85% énergie concentrée
/// - Bandes fréquentielles: Low (0-500Hz), Mid (500-2000Hz), High (2000+Hz)
/// - MFCC: Mel-Frequency Cepstral Coefficients (13 coefficients)
/// - Energy Peaks: Détection des pics de toux
///
/// BASE SCIENTIFIQUE:
/// - TB: Fréquence 200-400 Hz, toux sèche chronique
/// - Pneumonie: Fréquence <250 Hz, toux grasse avec crépitements
class AudioFeaturesExtractor {
  /// Taux d'échantillonnage (Hz)
  static const int sampleRate = 44100;

  /// Taille de la fenêtre FFT (puissance de 2)
  static const int fftSize = 2048;

  /// Hop size pour fenêtrage (overlap 50%)
  static const int hopSize = fftSize ~/ 2;

  /// 🎯 EXTRACTION COMPLÈTE DES FEATURES AUDIO
  ///
  /// Paramètres:
  /// - audioFilePath: Chemin du fichier audio (.aac, .wav, .mp3)
  ///
  /// Retour: Map avec toutes les features acoustiques
  static Future<Map<String, dynamic>> extractFeatures(
      String audioFilePath) async {
    try {
      print('🎵 Extraction features audio: $audioFilePath');

      // 1️⃣ CHARGER FICHIER AUDIO
      final audioData = await _loadAudioFile(audioFilePath);

      if (audioData.isEmpty) {
        print('⚠️ Fichier audio vide, retour features par défaut');
        return _getDefaultFeatures();
      }

      print(
          '✅ Audio chargé: ${audioData.length} samples (${(audioData.length / sampleRate).toStringAsFixed(2)}s)');

      // 2️⃣ ANALYSE TEMPORELLE
      final amplitude = _calculateAmplitude(audioData);
      final energy = _calculateEnergy(audioData);
      final zcr = _calculateZeroCrossingRate(audioData);

      // 3️⃣ ANALYSE FRÉQUENTIELLE (FFT)
      final fftResult = _performFFT(audioData);
      final magnitudeSpectrum = fftResult['magnitude'] as List<double>;
      final frequencies = fftResult['frequencies'] as List<double>;

      // 4️⃣ EXTRACTION FEATURES SPECTRALES
      final fundamentalFreq =
          _findFundamentalFrequency(magnitudeSpectrum, frequencies);
      final spectralCentroid =
          _calculateSpectralCentroid(magnitudeSpectrum, frequencies);
      final spectralRolloff =
          _calculateSpectralRolloff(magnitudeSpectrum, frequencies);

      // Bandes fréquentielles
      final spectralBands =
          _calculateSpectralBands(magnitudeSpectrum, frequencies);

      // 5️⃣ MFCC (Mel-Frequency Cepstral Coefficients)
      final mfcc = _calculateMFCC(magnitudeSpectrum, frequencies);

      // 6️⃣ DÉTECTION ÉVÉNEMENTS TOUX
      final energyPeaks = _detectEnergyPeaks(audioData);
      final hasCrackles = _detectCrackles(magnitudeSpectrum, frequencies);

      print('🎯 Features extraites:');
      print('   Fréquence: ${fundamentalFreq.toStringAsFixed(1)} Hz');
      print('   Amplitude: ${(amplitude * 100).toStringAsFixed(1)}%');
      print('   Énergie: ${(energy * 100).toStringAsFixed(1)}%');
      print('   ZCR: ${zcr.toStringAsFixed(3)}');
      print('   Crépitements: ${hasCrackles ? "OUI" : "NON"}');
      print('   Pics d\'énergie: ${energyPeaks.length}');

      return {
        // Caractéristiques temporelles
        'frequency': fundamentalFreq,
        'amplitude': amplitude,
        'energy': energy,
        'zeroCrossingRate': zcr,

        // Caractéristiques spectrales
        'spectral': {
          'centroid': spectralCentroid,
          'rolloff': spectralRolloff,
          'lowBand': spectralBands['low']!,
          'midBand': spectralBands['mid']!,
          'highBand': spectralBands['high']!,
        },

        // Coefficients MFCC
        'mfcc': mfcc,

        // Événements détectés
        'energyPeaks': energyPeaks,
        'crackles': hasCrackles,

        // Métadonnées
        'duration': audioData.length / sampleRate,
        'sampleRate': sampleRate,
        'samplesCount': audioData.length,
        'isReliable': true,
      };
    } catch (e) {
      print('❌ Erreur extraction features: $e');
      return _getDefaultFeatures();
    }
  }

  /// 📂 CHARGER FICHIER AUDIO WAV → samples PCM normalisés [-1,1]
  ///
  /// Exposé publiquement pour être réutilisé par CrackleWheezeMLService
  /// (évite de dupliquer le parsing WAV).
  static Future<List<double>> loadPcmSamples(String filePath) =>
      _loadAudioFile(filePath);

  /// 📂 CHARGER FICHIER AUDIO WAV → samples PCM 16-bit
  ///
  /// Lit le fichier WAV en sautant l'entête RIFF (44 bytes standard).
  /// Le codec d'enregistrement doit être pcm16WAV (flutter_sound).
  static Future<List<double>> _loadAudioFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        print('⚠️ Fichier inexistant: $filePath');
        return [];
      }

      final bytes = await file.readAsBytes();
      print('📂 Fichier: ${bytes.length} bytes');

      // Trouver le début des données PCM en cherchant "data" chunk dans l'entête WAV
      int dataOffset = 44; // Entête WAV standard
      for (int i = 0; i < min(200, bytes.length - 4); i++) {
        // Chercher le marqueur "data" (0x64617461)
        if (bytes[i] == 0x64 && bytes[i + 1] == 0x61 &&
            bytes[i + 2] == 0x74 && bytes[i + 3] == 0x61) {
          dataOffset = i + 8; // "data" + 4 bytes taille chunk
          break;
        }
      }

      print('📂 Données PCM démarrent à l\'octet $dataOffset');

      final samples = <double>[];
      for (int i = dataOffset; i < bytes.length - 1; i += 2) {
        final sample = bytes[i] | (bytes[i + 1] << 8);
        final signedSample = sample > 32767 ? sample - 65536 : sample;
        samples.add(signedSample / 32768.0);
      }

      print('📂 ${samples.length} samples PCM extraits');
      // Un fichier avec trop peu de samples n'est pas exploitable : on ne
      // fabrique plus de signal factice (ça produisait un faux diagnostic
      // silencieux). On retourne vide pour déclencher le fallback marqué
      // "non fiable" dans extractFeatures().
      if (samples.length <= 100) {
        print('⚠️ Trop peu de samples PCM (${samples.length}), audio jugé non exploitable');
        return [];
      }
      return samples;
    } catch (e) {
      print('⚠️ Erreur lecture audio: $e');
      return [];
    }
  }

  /// 📊 CALCUL AMPLITUDE MOYENNE
  static double _calculateAmplitude(List<double> samples) {
    if (samples.isEmpty) return 0.0;

    double sum = 0.0;
    for (var sample in samples) {
      sum += sample.abs();
    }

    return sum / samples.length;
  }

  /// ⚡ CALCUL ÉNERGIE RMS (Root Mean Square)
  static double _calculateEnergy(List<double> samples) {
    if (samples.isEmpty) return 0.0;

    double sumSquares = 0.0;
    for (var sample in samples) {
      sumSquares += sample * sample;
    }

    return sqrt(sumSquares / samples.length);
  }

  /// 〰️ CALCUL ZERO CROSSING RATE
  ///
  /// Mesure la fréquence de changement de signe du signal
  /// ZCR élevé = son sec/crackling (toux sèche)
  /// ZCR faible = son fluide/continu (toux grasse)
  static double _calculateZeroCrossingRate(List<double> samples) {
    if (samples.length < 2) return 0.0;

    int crossings = 0;

    for (int i = 1; i < samples.length; i++) {
      if ((samples[i] >= 0 && samples[i - 1] < 0) ||
          (samples[i] < 0 && samples[i - 1] >= 0)) {
        crossings++;
      }
    }

    return crossings / (samples.length - 1);
  }

  /// 🌈 FFT (Fast Fourier Transform)
  ///
  /// Convertit signal temporel → spectre fréquentiel
  static Map<String, dynamic> _performFFT(List<double> samples) {
    // Padding ou truncation à fftSize
    final paddedSamples = List<double>.filled(fftSize, 0.0);
    final copyLength = min(samples.length, fftSize);

    for (int i = 0; i < copyLength; i++) {
      // Appliquer fenêtre de Hann pour réduire spectral leakage
      final window = 0.5 * (1 - cos(2 * pi * i / fftSize));
      paddedSamples[i] = samples[i] * window;
    }

    // FFT avec package fftea
    final fft = FFT(fftSize);
    final complexInput = Float64x2List(fftSize);

    for (int i = 0; i < fftSize; i++) {
      complexInput[i] = Float64x2(paddedSamples[i], 0.0);
    }

    final spectrum = fft.realFft(paddedSamples);

    // Calcul magnitude et fréquences
    final magnitude = <double>[];
    final frequencies = <double>[];

    for (int i = 0; i < spectrum.length; i++) {
      final real = spectrum[i].x;
      final imag = spectrum[i].y;
      magnitude.add(sqrt(real * real + imag * imag));
      frequencies.add(i * sampleRate / fftSize);
    }

    return {
      'magnitude': magnitude,
      'frequencies': frequencies,
    };
  }

  /// 🎯 TROUVER FRÉQUENCE FONDAMENTALE
  ///
  /// Trouve le pic principal dans le spectre (50-2000 Hz)
  static double _findFundamentalFrequency(
    List<double> magnitude,
    List<double> frequencies,
  ) {
    double maxMagnitude = 0.0;
    double fundamentalFreq = 250.0; // Défaut

    for (int i = 0; i < frequencies.length; i++) {
      final freq = frequencies[i];

      // Limiter recherche à bande vocale/toux (50-2000 Hz)
      if (freq >= 50 && freq <= 2000) {
        if (magnitude[i] > maxMagnitude) {
          maxMagnitude = magnitude[i];
          fundamentalFreq = freq;
        }
      }
    }

    return fundamentalFreq;
  }

  /// 🌟 CALCUL SPECTRAL CENTROID
  ///
  /// "Centre de gravité" du spectre fréquentiel
  /// Valeur haute = son brillant/aigu
  /// Valeur basse = son sombre/grave
  static double _calculateSpectralCentroid(
    List<double> magnitude,
    List<double> frequencies,
  ) {
    double numerator = 0.0;
    double denominator = 0.0;

    for (int i = 0; i < magnitude.length; i++) {
      numerator += frequencies[i] * magnitude[i];
      denominator += magnitude[i];
    }

    return denominator > 0 ? numerator / denominator : 0.0;
  }

  /// 📉 CALCUL SPECTRAL ROLLOFF
  ///
  /// Fréquence en-dessous de laquelle se trouve 85% de l'énergie
  static double _calculateSpectralRolloff(
    List<double> magnitude,
    List<double> frequencies,
  ) {
    // Calculer énergie totale
    double totalEnergy = 0.0;
    for (var mag in magnitude) {
      totalEnergy += mag;
    }

    final threshold = 0.85 * totalEnergy;
    double cumulativeEnergy = 0.0;

    for (int i = 0; i < magnitude.length; i++) {
      cumulativeEnergy += magnitude[i];
      if (cumulativeEnergy >= threshold) {
        return frequencies[i];
      }
    }

    return frequencies.last;
  }

  /// 🎚️ CALCUL ÉNERGIE PAR BANDE FRÉQUENTIELLE
  ///
  /// Low: 0-500 Hz (mucus, fluides pulmonaires)
  /// Mid: 500-2000 Hz (voix, toux normale)
  /// High: 2000+ Hz (crépitements, sifflements)
  static Map<String, double> _calculateSpectralBands(
    List<double> magnitude,
    List<double> frequencies,
  ) {
    double lowEnergy = 0.0;
    double midEnergy = 0.0;
    double highEnergy = 0.0;
    double totalEnergy = 0.0;

    for (int i = 0; i < frequencies.length; i++) {
      final freq = frequencies[i];
      final mag = magnitude[i];

      totalEnergy += mag;

      if (freq < 500) {
        lowEnergy += mag;
      } else if (freq < 2000) {
        midEnergy += mag;
      } else {
        highEnergy += mag;
      }
    }

    // Normaliser par énergie totale
    return {
      'low': totalEnergy > 0 ? lowEnergy / totalEnergy : 0.0,
      'mid': totalEnergy > 0 ? midEnergy / totalEnergy : 0.0,
      'high': totalEnergy > 0 ? highEnergy / totalEnergy : 0.0,
    };
  }

  /// 🎼 CALCUL MFCC (Mel-Frequency Cepstral Coefficients)
  ///
  /// Représentation compacte du spectre selon échelle mel (perception humaine)
  /// Utilisé en reconnaissance vocale et analyse audio médicale
  static List<double> _calculateMFCC(
    List<double> magnitude,
    List<double> frequencies,
  ) {
    const int numMelFilters = 26;
    const int numMFCC = 13;

    try {
      // 1. Convertir échelle Hz → Mel
      final melFrequencies = frequencies.map(_hzToMel).toList();

      // 2. Créer bancs de filtres mel
      final melFilterBanks = _createMelFilterBanks(
        numMelFilters,
        melFrequencies,
        magnitude.length,
      );

      // 3. Appliquer filtres sur magnitude spectrum
      final melSpectrum = <double>[];
      for (var filterBank in melFilterBanks) {
        double energy = 0.0;
        for (int i = 0; i < min(filterBank.length, magnitude.length); i++) {
          energy += filterBank[i] * magnitude[i];
        }
        melSpectrum
            .add(log(energy + 1e-10)); // Log avec protection division par zéro
      }

      // 4. DCT (Discrete Cosine Transform) pour obtenir MFCC
      final mfcc = <double>[];
      for (int i = 0; i < numMFCC; i++) {
        double coefficient = 0.0;
        for (int j = 0; j < melSpectrum.length; j++) {
          coefficient +=
              melSpectrum[j] * cos(pi * i * (j + 0.5) / melSpectrum.length);
        }
        mfcc.add(coefficient);
      }

      return mfcc;
    } catch (e) {
      print('⚠️ Erreur calcul MFCC: $e');
      return List.filled(numMFCC, 0.0);
    }
  }

  /// 🎵 CONVERSION Hz → Mel
  static double _hzToMel(double hz) {
    return 2595 * log(1 + hz / 700) / ln10;
  }

  /// 🎚️ CRÉATION BANCS DE FILTRES MEL
  static List<List<double>> _createMelFilterBanks(
    int numFilters,
    List<double> melFreqs,
    int fftBins,
  ) {
    final filterBanks = <List<double>>[];

    final minMel = melFreqs.first;
    final maxMel = melFreqs.last;
    final melStep = (maxMel - minMel) / (numFilters + 1);

    for (int i = 0; i < numFilters; i++) {
      final centerMel = minMel + (i + 1) * melStep;
      final filter = List<double>.filled(fftBins, 0.0);

      // Filtre triangulaire simplifié
      for (int j = 0; j < fftBins; j++) {
        final mel = melFreqs[j];
        if (mel >= centerMel - melStep && mel <= centerMel + melStep) {
          filter[j] = 1.0 - (mel - centerMel).abs() / melStep;
        }
      }

      filterBanks.add(filter);
    }

    return filterBanks;
  }

  /// ⚡ DÉTECTION PICS D'ÉNERGIE (comptage toux)
  ///
  /// Trouve les pics d'énergie dans le signal (chaque pic = une toux)
  static List<double> _detectEnergyPeaks(List<double> samples) {
    const int windowSize = sampleRate ~/ 10; // Fenêtre 100ms
    // Seuil 4% RMS. 0.08 s'est révélé trop strict en usage réel (vraies
    // toux rejetées, cf. rapport "0 détection") ; 0.04 reste plus prudent
    // que l'original 0.05 tout en ne bloquant plus les toux légitimes.
    const double threshold = 0.04;

    final peaks = <double>[];

    for (int i = 0; i < samples.length - windowSize; i += windowSize) {
      final window = samples.sublist(i, i + windowSize);
      final energy = _calculateEnergy(window);

      if (energy > threshold) {
        // Trouver position exacte du pic dans cette fenêtre
        double maxAmp = 0.0;
        int maxIdx = 0;

        for (int j = 0; j < window.length; j++) {
          if (window[j].abs() > maxAmp) {
            maxAmp = window[j].abs();
            maxIdx = j;
          }
        }

        // Timestamp en secondes
        peaks.add((i + maxIdx) / sampleRate);
      }
    }

    return peaks;
  }

  /// 🔍 DÉTECTION CRÉPITEMENTS (Crackles)
  ///
  /// Indicateur de pneumonie: sons secs haute fréquence (>3000 Hz)
  /// irréguliers et brefs
  static bool _detectCrackles(
    List<double> magnitude,
    List<double> frequencies,
  ) {
    // Analyser énergie dans bande haute fréquence (3000-8000 Hz)
    double highFreqEnergy = 0.0;
    double totalEnergy = 0.0;

    for (int i = 0; i < frequencies.length; i++) {
      totalEnergy += magnitude[i];

      if (frequencies[i] >= 3000 && frequencies[i] <= 8000) {
        highFreqEnergy += magnitude[i];
      }
    }

    // Crépitements si >15% énergie en haute fréquence
    final ratio = totalEnergy > 0 ? highFreqEnergy / totalEnergy : 0.0;

    return ratio > 0.15;
  }

  /// 🔧 FEATURES PAR DÉFAUT (fallback)
  ///
  /// ⚠️ Utilisé uniquement quand l'audio est illisible/vide. `isReliable:
  /// false` doit être vérifié par les appelants pour éviter d'afficher un
  /// score TB/pneumonie basé sur ces valeurs comme s'il s'agissait d'une
  /// vraie analyse.
  static Map<String, dynamic> _getDefaultFeatures() {
    return {
      'frequency': 250.0,
      'amplitude': 0.5,
      'energy': 0.5,
      'zeroCrossingRate': 0.15,
      'spectral': {
        'centroid': 800.0,
        'rolloff': 2000.0,
        'lowBand': 0.4,
        'midBand': 0.5,
        'highBand': 0.1,
      },
      'mfcc': List.filled(13, 0.0),
      'energyPeaks': const <double>[],
      'crackles': false,
      'duration': 0.0,
      'sampleRate': sampleRate,
      'samplesCount': 0,
      'isReliable': false,
    };
  }
}
