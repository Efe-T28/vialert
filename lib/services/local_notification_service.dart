import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'i_notification_service.dart';

/// Implementación real con flutter_local_notifications: canal de máxima
/// importancia para que la alerta suene/vibre y aparezca como heads-up
/// aunque la pantalla esté apagada o la app en segundo plano.
class LocalNotificationService implements INotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _inicializado = false;

  static const _canal = AndroidNotificationDetails(
    'alertas_emergencia',
    'Alertas de emergencia',
    channelDescription: 'Avisos de nuevas alertas de accidente',
    importance: Importance.max,
    priority: Priority.high,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
  );

  @override
  Future<void> init() async {
    if (_inicializado) return;
    _inicializado = true;

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // Android 13+: permiso runtime de notificaciones.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  @override
  Future<void> mostrarAlertaNueva({
    required String id,
    required String titulo,
    required String cuerpo,
  }) async {
    await _plugin.show(
      // mismo id de alerta => misma notificación, sin duplicados
      id: id.hashCode,
      title: titulo,
      body: cuerpo,
      notificationDetails: const NotificationDetails(android: _canal),
    );
  }
}
