/// Voz de navegación (texto a voz del dispositivo): anuncia las maniobras
/// de la ruta en voz alta para que la tripulación no mire la pantalla.
abstract class ITtsService {
  /// Configura idioma (español) y velocidad.
  Future<void> init();

  Future<void> decir(String texto);

  /// Corta cualquier frase en curso.
  Future<void> callar();
}
