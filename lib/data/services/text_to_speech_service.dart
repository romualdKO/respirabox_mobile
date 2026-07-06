import 'package:flutter_tts/flutter_tts.dart';

/// 🔊 SYNTHÈSE VOCALE DES RÉPONSES DU CHATBOT
///
/// Utilise le moteur TTS natif de l'OS (Android/iOS). Actuellement français
/// uniquement : les moteurs TTS natifs ne proposent pas le dioula, le
/// baoulé ni le bété (voir ml/README.md et ARCHITECTURE_IA.md pour le
/// contexte multilingue plus large).
class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  factory TextToSpeechService() => _instance;
  TextToSpeechService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _tts.setLanguage('fr-FR');
    // Débit légèrement ralenti + pitch neutre : plus proche d'une élocution
    // humaine normale que le débit par défaut, souvent trop rapide/monotone.
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(0.98);
    await _tts.setVolume(1.0);
    await _selectBestFrenchVoice();
    _initialized = true;
  }

  /// Sélectionne automatiquement la meilleure voix française disponible sur
  /// l'appareil (qualité la plus élevée annoncée par le moteur TTS système,
  /// en privilégiant les voix réseau type WaveNet/Neural quand présentes —
  /// nettement plus naturelles que les voix locales compactes par défaut).
  Future<void> _selectBestFrenchVoice() async {
    try {
      final dynamic rawVoices = await _tts.getVoices;
      if (rawVoices is! List) return;

      const qualityRank = {
        'very high': 4,
        'high': 3,
        'normal': 2,
        'low': 1,
        'very low': 0,
      };

      Map<String, dynamic>? best;
      int bestScore = -1;

      for (final v in rawVoices) {
        if (v is! Map) continue;
        final locale = (v['locale'] ?? '').toString().toLowerCase();
        if (!locale.startsWith('fr')) continue;

        final quality = (v['quality'] ?? 'normal').toString().toLowerCase();
        final networkRequired = v['network_required'] == '1';
        // Score: qualité annoncée d'abord, puis léger bonus voix réseau
        // (généralement de meilleure qualité perceptuelle que les voix locales).
        final score = (qualityRank[quality] ?? 2) * 10 + (networkRequired ? 1 : 0);

        if (score > bestScore) {
          bestScore = score;
          best = Map<String, dynamic>.from(v);
        }
      }

      if (best != null) {
        await _tts.setVoice({
          'name': best['name'].toString(),
          'locale': best['locale'].toString(),
        });
        print('🔊 Voix TTS sélectionnée: ${best['name']} (qualité: ${best['quality']})');
      }
    } catch (e) {
      print('⚠️ Sélection de voix TTS impossible, voix par défaut utilisée: $e');
    }
  }

  /// Lit [text] à voix haute. Coupe toute lecture en cours avant de démarrer.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _ensureInitialized();
      await _tts.stop();
      // Les réponses contiennent souvent des emojis/markdown — on ne lit
      // que le texte utile pour éviter que le moteur TTS n'épelle les symboles.
      final cleaned = _stripForSpeech(text);
      if (cleaned.isEmpty) return;
      await _tts.speak(cleaned);
    } catch (e) {
      print('⚠️ TTS indisponible: $e');
    }
  }

  Future<void> stop() async {
    if (!_initialized) return;
    await _tts.stop();
  }

  static String _stripForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
            unicode: true), '') // emojis
        .replaceAll(RegExp(r'[*_`#]'), '') // markdown
        .replaceAll(RegExp(r'\n+'), '. ')
        .trim();
  }
}
