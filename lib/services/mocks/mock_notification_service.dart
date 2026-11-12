import '../i_notification_service.dart';

/// Registra las notificaciones en memoria, sin tocar el sistema.
class MockNotificationService implements INotificationService {
  final List<({String id, String titulo, String cuerpo})> mostradas = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> mostrarAlertaNueva({
    required String id,
    required String titulo,
    required String cuerpo,
  }) async {
    mostradas.add((id: id, titulo: titulo, cuerpo: cuerpo));
  }
}
