import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vialert/models/alerta_model.dart';
import 'package:vialert/models/ambulancia_model.dart';
import 'package:vialert/services/mocks/mock_database_service.dart';

void main() {
  const pos = LatLng(10.47, -73.24);

  late MockDatabaseService db;

  AlertaModel alerta(String id) => AlertaModel(
        id: id,
        type: 'Accidente',
        description: 'prueba',
        position: pos,
        createdAt: DateTime.now(),
        creadaPorUsuarioId: 'Usuario Prueba',
      );

  AmbulanciaModel ambulancia(String id) => AmbulanciaModel(
        id: id,
        email: '$id@vialert.test',
        placa: 'ABC-$id',
        codigoInterno: id,
        entidadId: 'entidad-1',
      );

  setUp(() async {
    db = MockDatabaseService();
    await db.crearAlerta(alerta('a1'));
    await db.crearAlerta(alerta('a2'));
    await db.crearAmbulanciaDoc(ambulancia('amb1'));
    await db.crearAmbulanciaDoc(ambulancia('amb2'));
  });

  bool esPendiente(AlertaModel a) =>
      a.estado == AlertState.activa && a.ambulanciaAsignada == null;

  test('tomar una alerta activa la reserva para la ambulancia', () async {
    final res = await db.tomarAlerta(alertaId: 'a1', ambulanciaId: 'amb1');

    expect(res, TomarAlertaResultado.ok);
    final a1 = (await db.getAlertaById('a1'))!;
    expect(a1.estado, AlertState.enProceso);
    expect(a1.ambulanciaAsignada, 'amb1');
    expect((await db.getAmbulanciaById('amb1'))!.currentAlertaId, 'a1');
    expect(esPendiente(a1), isFalse);
  });

  test('una segunda ambulancia no puede tomar una alerta ya tomada', () async {
    await db.tomarAlerta(alertaId: 'a1', ambulanciaId: 'amb1');
    final res = await db.tomarAlerta(alertaId: 'a1', ambulanciaId: 'amb2');

    expect(res, TomarAlertaResultado.yaTomada);
    final a1 = (await db.getAlertaById('a1'))!;
    expect(a1.ambulanciaAsignada, 'amb1');
    expect((await db.getAmbulanciaById('amb2'))!.currentAlertaId, isNull);
  });

  test('una ambulancia con alerta tomada no puede tomar otra', () async {
    await db.tomarAlerta(alertaId: 'a1', ambulanciaId: 'amb1');
    final res = await db.tomarAlerta(alertaId: 'a2', ambulanciaId: 'amb1');

    expect(res, TomarAlertaResultado.ambulanciaOcupada);
    final a2 = (await db.getAlertaById('a2'))!;
    expect(esPendiente(a2), isTrue);
  });

  test('liberar una alerta tomada la devuelve a pendientes', () async {
    await db.tomarAlerta(alertaId: 'a1', ambulanciaId: 'amb1');
    await db.liberarAlerta(alertaId: 'a1', ambulanciaId: 'amb1');

    final a1 = (await db.getAlertaById('a1'))!;
    expect(a1.estado, AlertState.activa);
    expect(a1.ambulanciaAsignada, isNull);
    expect(esPendiente(a1), isTrue);
    expect((await db.getAmbulanciaById('amb1'))!.currentAlertaId, isNull);

    // Otra ambulancia ya puede tomarla.
    final res = await db.tomarAlerta(alertaId: 'a1', ambulanciaId: 'amb2');
    expect(res, TomarAlertaResultado.ok);
  });

  test('liberar no revierte una alerta ya atendida', () async {
    await db.tomarAlerta(alertaId: 'a1', ambulanciaId: 'amb1');
    await db.updateAlerta('a1', {'estado': AlertState.atendida.name});

    await db.liberarAlerta(alertaId: 'a1', ambulanciaId: 'amb1');

    final a1 = (await db.getAlertaById('a1'))!;
    expect(a1.estado, AlertState.atendida);
    expect((await db.getAmbulanciaById('amb1'))!.currentAlertaId, isNull);
  });
}
