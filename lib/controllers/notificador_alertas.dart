import '../models/alerta_model.dart';
import '../services/i_notification_service.dart';
import 'alert_controller.dart';

/// Observa el stream de alertas y dispara una notificación local cuando
/// aparece una alerta nueva sin tomar. Lo activa solo el shell de la
/// ambulancia en servicio ([AmbulanciaMapaHome]); usuarios y admin no
/// reciben estos avisos.
class NotificadorAlertas {
  final AlertController _alertController;
  final INotificationService _notificaciones;

  /// Alertas más viejas que esto no se notifican: evita una avalancha de
  /// avisos por alertas pendientes antiguas al entrar en servicio.
  static const Duration ventanaFrescura = Duration(minutes: 5);

  final Set<String> _idsConocidos = {};
  bool _activo = false;

  NotificadorAlertas(this._alertController, this._notificaciones);

  Future<void> iniciar() async {
    if (_activo) return;
    _activo = true;
    await _notificaciones.init();
    // Lo ya presente al entrar en servicio no genera avisos.
    _idsConocidos.addAll(_alertController.alerts.map((a) => a.id));
    _alertController.addListener(_revisarNuevas);
  }

  void detener() {
    if (!_activo) return;
    _activo = false;
    _alertController.removeListener(_revisarNuevas);
  }

  void _revisarNuevas() {
    final ahora = DateTime.now();
    for (final alerta in _alertController.alerts) {
      if (_idsConocidos.contains(alerta.id)) continue;
      _idsConocidos.add(alerta.id);

      final esPendiente = alerta.estado == AlertState.activa &&
          alerta.ambulanciaAsignada == null;
      final esReciente = ahora.difference(alerta.createdAt) < ventanaFrescura;
      if (!esPendiente || !esReciente) continue;

      _notificaciones.mostrarAlertaNueva(
        id: alerta.id,
        titulo: '🚨 Nueva alerta: ${alerta.type}',
        cuerpo: alerta.description.isEmpty
            ? 'Hay una emergencia pendiente por atender'
            : alerta.description,
      );
    }
  }
}
