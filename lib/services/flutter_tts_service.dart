import 'package:flutter_tts/flutter_tts.dart';
import 'i_tts_service.dart';

/// Implementación con el motor TTS nativo del dispositivo (flutter_tts):
/// offline y sin costo. Prefiere es-ES y cae al primer idioma es-* que el
/// dispositivo tenga instalado.
class FlutterTtsService implements ITtsService {
  final FlutterTts _tts = FlutterTts();
  bool _inicializado = false;

  @override
  Future<void> init() async {
    if (_inicializado) return;
    _inicializado = true;

    var idioma = 'es-ES';
    try {
      if (!(await _tts.isLanguageAvailable(idioma) ?? false)) {
        final idiomas = (await _tts.getLanguages as List?) ?? const [];
        idioma = idiomas
            .whereType<String>()
            .firstWhere((l) => l.startsWith('es'), orElse: () => 'es-ES');
      }
    } catch (_) {
      // Si el motor no responde, se intenta igual con es-ES.
    }
    await _tts.setLanguage(idioma);
    await _tts.setSpeechRate(0.5);
  }

  @override
  Future<void> decir(String texto) async {
    await _tts.stop(); // no encimar frases: la nueva instrucción manda
    await _tts.speak(texto);
  }

  @override
  Future<void> callar() => _tts.stop();
}
