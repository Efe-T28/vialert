import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vialert/controllers/alert_controller.dart';
import 'package:vialert/controllers/notificador_alertas.dart';
import 'package:vialert/models/alerta_model.dart';
import 'package:vialert/services/mocks/mock_database_service.dart';
import 'package:vialert/services/mocks/mock_notification_service.dart';
import 'package:vialert/services/mocks/mock_storage_service.dart';

void main() {
  const pos = LatLng(10.47, -73.24);

  late MockDatabaseService db;
  late AlertController ctrl;
  late MockNotificationService avisos;
  late NotificadorAlertas notificador;

  // Deja que los eventos del stream en memoria lleguen al controller.
  Future<void> propagar() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  setUp(() {
    db = MockDatabaseService();
    ctrl = AlertController(db, MockStorageService(demora: Duration.zero));
    avisos = MockNotificationService();
    notificador = NotificadorAlertas(ctrl, avisos);
  });

  tearDown(() {
    notificador.detener();
    ctrl.dispose();
  });

  Future<String> crearAlerta() => ctrl.crearAlerta(
        type: 'Accidente',
        description: 'choque en la 33B',
        position: pos,
        creadaPorUsuarioId: 'Usuario Prueba',
        creadaPorUid: 'uid-1',
        fotos: const [],
      );

  test('las alertas que ya existían al entrar en servicio no se notifican',
      () async {
    await crearAlerta();
    await propagar();

    await notificador.iniciar();
    await propagar();

    expect(avisos.mostradas, isEmpty);
  });

  test('una alerta nueva genera exactamente una notificación con su tipo',
      () async {
    await notificador.iniciar();

    final id = await crearAlerta();
    await propagar();

    expect(avisos.mostradas, hasLength(1));
    expect(avisos.mostradas.single.id, id);
    expect(avisos.mostradas.single.titulo, contains('Accidente'));
    expect(avisos.mostradas.single.cuerpo, contains('choque'));
  });

  test('los cambios de estado de una alerta ya vista no re-notifican',
      () async {
    await notificador.iniciar();
    final id = await crearAlerta();
    await propagar();

    await db.tomarAlerta(alertaId: id, ambulanciaId: 'amb1');
    await propagar();
    await ctrl.marcarComoAtendida(id);
    await propagar();

    expect(avisos.mostradas, hasLength(1));
  });

  test(
      'una alerta nueva con reloj/zona horaria distinta (createdAt desfasado) '
      'igual se notifica', () async {
    await notificador.iniciar();
    await propagar();

    await db.crearAlerta(AlertaModel(
      id: 'desfasada-1',
      type: 'Accidente',
      description: 'creada en otro dispositivo',
      position: pos,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      creadaPorUsuarioId: 'Usuario Prueba',
    ));
    await propagar();

    expect(avisos.mostradas, hasLength(1));
    expect(avisos.mostradas.single.id, 'desfasada-1');
  });

  test('createdAt se guarda en UTC y se lee en hora local', () {
    final local = DateTime(2026, 11, 15, 10, 30);
    final alerta = AlertaModel(
      id: 'x',
      type: 'Accidente',
      description: '',
      position: pos,
      createdAt: local,
      creadaPorUsuarioId: 'u',
    );
    final mapa = alerta.toMap();
    expect(mapa['createdAt'], endsWith('Z'));
    final leida = AlertaModel.fromMap('x', mapa);
    expect(leida.createdAt, local);
    expect(leida.createdAt.isUtc, isFalse);
  });
}
