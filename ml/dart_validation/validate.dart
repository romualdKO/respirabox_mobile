import 'dart:io';
import 'dart:typed_data';
import 'mel_spectrogram.dart';

void main() {
  final rawBytes = File('/tmp/test_signal_f32.bin').readAsBytesSync();
  final refBytes = File('/tmp/ref_mel_f32.bin').readAsBytesSync();

  final rawFloats = Float32List.view(rawBytes.buffer, rawBytes.offsetInBytes, rawBytes.length ~/ 4);
  final refFloats = Float32List.view(refBytes.buffer, refBytes.offsetInBytes, refBytes.length ~/ 4);

  final samples = rawFloats.toList();
  print('Signal chargé: ${samples.length} samples');

  final mel = MelSpectrogram(sampleRate: 4000, nFft: 256, hopLength: 64, nMels: 64);
  final result = mel.computeNormalized(samples);

  final nMels = result.length;
  final nFrames = result[0].length;
  print('Mel calculé: ${nMels}x$nFrames (attendu: 64x313, ref len: ${refFloats.length})');

  // ref sauvegardé en row-major (nMels, nFrames) via numpy tofile()
  double sumSqError = 0.0;
  double maxError = 0.0;
  int idx = 0;
  for (int m = 0; m < nMels; m++) {
    for (int t = 0; t < nFrames; t++) {
      final refVal = refFloats[idx];
      final dartVal = result[m][t];
      final err = (refVal - dartVal).abs();
      sumSqError += err * err;
      if (err > maxError) maxError = err;
      idx++;
    }
  }
  final mse = sumSqError / (nMels * nFrames);
  print('MSE: ${mse.toStringAsExponential(4)}');
  print('Erreur max: ${maxError.toStringAsExponential(4)}');
  print('Échantillon Dart [0:5,0]: ${List.generate(5, (i) => result[i][0].toStringAsFixed(4))}');
}
