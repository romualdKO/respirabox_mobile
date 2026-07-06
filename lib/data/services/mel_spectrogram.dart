import 'dart:math';
import 'package:fftea/fftea.dart';

/// Réimplémentation en Dart du calcul log-mel-spectrogramme de librosa
/// (librosa.feature.melspectrogram + power_to_db, htk=False, norm='slaney',
/// pad_mode='constant'), pour rester numériquement cohérent avec le
/// prétraitement Python utilisé à l'entraînement du modèle TFLite.
class MelSpectrogram {
  final int sampleRate;
  final int nFft;
  final int hopLength;
  final int nMels;
  late final List<List<double>> _filterbank; // [nMels][nFft~/2+1]

  MelSpectrogram({
    required this.sampleRate,
    required this.nFft,
    required this.hopLength,
    required this.nMels,
  }) {
    _filterbank = _buildMelFilterbank();
  }

  static double _hzToMel(double hz) {
    const fMin = 0.0;
    const fSp = 200.0 / 3;
    double mel = (hz - fMin) / fSp;
    const minLogHz = 1000.0;
    const minLogMel = (minLogHz - fMin) / fSp;
    final logStep = log(6.4) / 27.0;
    if (hz >= minLogHz) {
      mel = minLogMel + log(hz / minLogHz) / logStep;
    }
    return mel;
  }

  static double _melToHz(double mel) {
    const fMin = 0.0;
    const fSp = 200.0 / 3;
    double freq = fMin + fSp * mel;
    const minLogHz = 1000.0;
    const minLogMel = (minLogHz - fMin) / fSp;
    final logStep = log(6.4) / 27.0;
    if (mel >= minLogMel) {
      freq = minLogHz * exp(logStep * (mel - minLogMel));
    }
    return freq;
  }

  List<List<double>> _buildMelFilterbank() {
    final nBins = nFft ~/ 2 + 1;
    final fMax = sampleRate / 2.0;
    final melMin = _hzToMel(0.0);
    final melMax = _hzToMel(fMax);

    final melPts = List<double>.generate(
      nMels + 2,
      (i) => melMin + (melMax - melMin) * i / (nMels + 1),
    );
    final hzPts = melPts.map(_melToHz).toList();

    final fftFreqs =
        List<double>.generate(nBins, (i) => i * sampleRate / nFft);

    final filters = List.generate(nMels, (_) => List<double>.filled(nBins, 0.0));

    for (int m = 0; m < nMels; m++) {
      final lower = hzPts[m];
      final center = hzPts[m + 1];
      final upper = hzPts[m + 2];
      final enorm = 2.0 / (upper - lower);

      for (int k = 0; k < nBins; k++) {
        final f = fftFreqs[k];
        double weight = 0.0;
        if (f >= lower && f <= center && center != lower) {
          weight = (f - lower) / (center - lower);
        } else if (f > center && f <= upper && upper != center) {
          weight = (upper - f) / (upper - center);
        }
        filters[m][k] = max(0.0, weight) * enorm;
      }
    }
    return filters;
  }

  /// Retourne un log-mel-spectrogramme normalisé [0,1], shape [nMels][nFrames]
  List<List<double>> computeNormalized(List<double> samples) {
    final pad = nFft ~/ 2;
    final padded = List<double>.filled(samples.length + 2 * pad, 0.0);
    for (int i = 0; i < samples.length; i++) {
      padded[pad + i] = samples[i];
    }

    final nFrames = 1 + (samples.length ~/ hopLength);
    final nBins = nFft ~/ 2 + 1;
    final fft = FFT(nFft);

    // power spectrum par frame : [nFrames][nBins]
    final powerFrames = List.generate(nFrames, (_) => List<double>.filled(nBins, 0.0));

    for (int t = 0; t < nFrames; t++) {
      final start = t * hopLength;
      final frame = List<double>.filled(nFft, 0.0);
      for (int i = 0; i < nFft; i++) {
        final idx = start + i;
        final sample = idx < padded.length ? padded[idx] : 0.0;
        final window = 0.5 * (1 - cos(2 * pi * i / nFft)); // Hann périodique
        frame[i] = sample * window;
      }
      final spectrum = fft.realFft(frame);
      for (int k = 0; k < nBins; k++) {
        final re = spectrum[k].x;
        final im = spectrum[k].y;
        powerFrames[t][k] = re * re + im * im;
      }
    }

    // Application du banc de filtres mel : [nMels][nFrames]
    final mel = List.generate(nMels, (_) => List<double>.filled(nFrames, 0.0));
    for (int m = 0; m < nMels; m++) {
      for (int t = 0; t < nFrames; t++) {
        double energy = 0.0;
        for (int k = 0; k < nBins; k++) {
          energy += _filterbank[m][k] * powerFrames[t][k];
        }
        mel[m][t] = energy;
      }
    }

    // power_to_db(ref=max) + clip top_db=80
    double globalMax = 0.0;
    for (final row in mel) {
      for (final v in row) {
        if (v > globalMax) globalMax = v;
      }
    }
    const amin = 1e-10;
    final refDb = 10.0 * log(max(amin, globalMax)) / ln10;

    double dbMax = -double.infinity;
    double dbMin = double.infinity;
    final db = List.generate(nMels, (_) => List<double>.filled(nFrames, 0.0));
    for (int m = 0; m < nMels; m++) {
      for (int t = 0; t < nFrames; t++) {
        final v = 10.0 * log(max(amin, mel[m][t])) / ln10 - refDb;
        db[m][t] = v;
        if (v > dbMax) dbMax = v;
      }
    }
    final floor = dbMax - 80.0;
    for (int m = 0; m < nMels; m++) {
      for (int t = 0; t < nFrames; t++) {
        final v = max(db[m][t], floor);
        db[m][t] = v;
        if (v < dbMin) dbMin = v;
      }
    }

    final norm = List.generate(nMels, (_) => List<double>.filled(nFrames, 0.0));
    final range = dbMax - dbMin + 1e-8;
    for (int m = 0; m < nMels; m++) {
      for (int t = 0; t < nFrames; t++) {
        norm[m][t] = (db[m][t] - dbMin) / range;
      }
    }
    return norm;
  }
}
