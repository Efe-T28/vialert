import 'package:flutter/foundation.dart';
import '../models/alerta_model.dart';
import '../services/i_notification_service.dart';
import 'alert_controller.dart';

/// Observa el stream de alertas y dispara una notificación local cuando
/// aparece una alerta nueva sin tomar. Lo activa solo el shell de la
/// ambulancia en servicio ([AmbulanciaMapaHome]); usuarios y admin no
/// reciben estos avisos.
///
/// Las alertas presentes al entrar en servicio (línea base) no se notifican;
/// así se evita una avalancha de avisos sin depender de `createdAt`, que viene
/// del reloj del dispositivo que creó la alerta.
class NotificadorAlertas {
  final AlertController _alertController;
  final INotificationService _notificaciones;

  final Set<String> _idsConocidos = {};
  bool _activo = false;
  bool _baseTomada = false;

  NotificadorAlertas(this._alertController, this._notificaciones);

  Future<void> iniciar() async {
    if (_activo) return;
    _activo = true;
    _idsConocidos.clear();
    _baseTomada = false;
    if (_alertController.cargado) _tomarBase();
    // Se escucha antes de init(): init() puede quedar esperando el diálogo
    // de permiso y no deben perderse las alertas que lleguen mientras tanto.
    _alertController.addListener(_revisarNuevas);
    await _notificaciones.init();
  }

  void detener() {
    if (!_activo) return;
    _activo = false;
    _alertController.removeListener(_revisarNuevas);
  }

  void _tomarBase() {
    _idsConocidos.addAll(_alertController.alerts.map((a) => a.id));
    _baseTomada = true;
  }

  void _revisarNuevas() {
    if (!_baseTomada) {
      // Primer snapshot recibido después de entrar en servicio.
      if (_alertController.cargado) _tomarBase();
      return;
    }
    for (final alerta in _alertController.alerts) {
      if (!_idsConocidos.add(alerta.id)) continue;

      final esPendiente = alerta.estado == AlertState.activa &&
          alerta.ambulanciaAsignada == null;
      if (!esPendiente) continue;

      debugPrint('[Notificaciones] Alerta nueva ${alerta.id}');
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
