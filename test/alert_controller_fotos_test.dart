import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vialert/controllers/alert_controller.dart';
import 'package:vialert/services/mocks/mock_database_service.dart';
import 'package:vialert/services/mocks/mock_storage_service.dart';

Future<void> esperarSubidas(AlertController c) async {
  for (var i = 0; i < 200; i++) {
    if (!c.subidasConAviso.any((s) => s.enCurso)) return;
    await Future.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  final foto = Uint8List.fromList([1, 2, 3]);
  const pos = LatLng(10.47, -73.24);

  late MockDatabaseService db;
  late MockStorageService storage;
  late AlertController ctrl;

  setUp(() {
    db = MockDatabaseService();
    storage = MockStorageService(demora: Duration.zero);
    ctrl = AlertController(db, storage);
  });

  Future<String> crear(List<Uint8List> fotos) => ctrl.crearAlerta(
        type: 'Accidente',
        description: 'prueba',
        position: pos,
        creadaPorUsuarioId: 'Usuario Prueba',
        creadaPorUid: 'uid-1',
        fotos: fotos,
      );

  test('respeta el máximo de 3 fotos', () async {
    final id = await crear([foto, foto, foto, foto]);
    await esperarSubidas(ctrl);

    final alerta = (await db.streamAlertas().first).firstWhere((a) => a.id == id);
    expect(alerta.fotos.length, AlertController.maxFotos);
  });

  test('una foto fallida no afecta a las demás y se puede reintentar', () async {
    storage.indicesQueFallan.add(1);
    final id = await crear([foto, foto, foto]);
    await esperarSubidas(ctrl);

    var alerta = (await db.streamAlertas().first).firstWhere((a) => a.id == id);
    expect(alerta.fotos.length, 2);
    expect(ctrl.subidasConAviso.single.fallidas.keys, [1]);

    storage.indicesQueFallan.clear();
    await ctrl.reintentarFotos(id);
    await esperarSubidas(ctrl);

    alerta = (await db.streamAlertas().first).firstWhere((a) => a.id == id);
    expect(alerta.fotos.length, 3);
    expect(ctrl.subidasConAviso, isEmpty);
  });

  test('la alerta se crea aunque fallen todas las fotos', () async {
    storage.fallarSiempre = true;
    final id = await crear([foto, foto, foto]);
    await esperarSubidas(ctrl);

    final alerta = (await db.streamAlertas().first).firstWhere((a) => a.id == id);
    expect(alerta.fotos, isEmpty);
    expect(ctrl.subidasConAviso.single.fallidas.length, 3);
  });
}