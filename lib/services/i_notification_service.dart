/// Notificaciones locales del dispositivo (sonido/vibración), usadas para
/// avisar a la tripulación de ambulancia cuando entra una alerta nueva.
abstract class INotificationService {
  /// Crea el canal y solicita el permiso de notificaciones si hace falta.
  Future<void> init();

  Future<void> mostrarAlertaNueva({
    required String id,
    required String titulo,
    required String cuerpo,
  });
}
