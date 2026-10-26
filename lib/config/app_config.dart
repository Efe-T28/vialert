/// Interruptores de funcionalidades, leídos de --dart-define / env.json.
class AppConfig {
  AppConfig._();

  /// Muestra la opción de adjuntar fotos al crear una alerta.
  static const bool fotosHabilitadas =
      bool.fromEnvironment('FOTOS_HABILITADAS');

  /// Usa un almacenamiento simulado en vez de Firebase Storage
  /// (para probar toda la UI antes de activar Storage).
  static const bool fotosSimuladas = bool.fromEnvironment('FOTOS_SIMULADAS');
}