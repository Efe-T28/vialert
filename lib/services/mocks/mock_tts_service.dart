import '../i_tts_service.dart';

/// Acumula las frases "habladas" en memoria, sin tocar el motor TTS.
class MockTtsService implements ITtsService {
  final List<String> frases = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> decir(String texto) async {
    frases.add(texto);
  }

  @override
  Future<void> callar() async {}
}
