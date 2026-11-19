/// Interruptores de funcionalidades, leídos de --dart-define / env.json.
class AppConfig {
  AppConfig._();

  /// Muestra la opción de adjuntar fotos al crear una alerta.
  static const bool fotosHabilitadas =
      bool.fromEnvironment('FOTOS_HABILITADAS');

  /// Usa un almacenamiento simulado en vez de Firebase Storage
  /// (para probar toda la UI antes de activar Storage).
  static const bool fotosSimuladas = bool.fromEnvironment('FOTOS_SIMULADAS');

  /// Marca como `simulada: true` las alertas que se creen con esta compilación,
  /// para que el panel las excluya de los KPI. Activarla en compilaciones de
  /// prueba que usen servicios simulados contra una base real:
  /// `--dart-define=DATOS_SIMULADOS=true`.
  static const bool datosSimulados = bool.fromEnvironment('DATOS_SIMULADOS');
}
