import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vialert/controllers/alert_controller.dart';
import 'package:vialert/controllers/ambulancia_controller.dart';
import 'package:vialert/controllers/atencion_alerta_controller.dart';
import 'package:vialert/controllers/guia_voz.dart';
import 'package:vialert/controllers/hospital_controller.dart';
import 'package:vialert/controllers/map_controller.dart';
import 'package:vialert/models/ambulancia_model.dart';
import 'package:vialert/services/mocks/mock_database_service.dart';
import 'package:vialert/services/mocks/mock_location_service.dart';
import 'package:vialert/services/mocks/mock_maps_service.dart';
import 'package:vialert/services/mocks/mock_storage_service.dart';
import 'package:vialert/services/mocks/mock_tts_service.dart';

void main() {
  const posAlerta = LatLng(10.4700, -73.2400);

  late MockDatabaseService db;
  late AlertController alertCtrl;
  late MapController mapCtrl;
  late AtencionAlertaController atencion;
  late MockTtsService tts;
  late GuiaVoz guia;

  Future<void> propagar() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  setUp(() async {
    db = MockDatabaseService();
    alertCtrl = AlertController(db, MockStorageService(demora: Duration.zero));
    final ambCtrl = AmbulanciaController(db);
    mapCtrl = MapController(
      mapsService: MockMapsService(),
      locationService: MockLocationService(),
    );
    final hospCtrl = HospitalController(db);
    atencion = AtencionAlertaController(alertCtrl, ambCtrl, mapCtrl, hospCtrl);
    tts = MockTtsService();
    guia = GuiaVoz(atencion, mapCtrl, MockLocationService(), tts);

    await db.crearAmbulanciaDoc(AmbulanciaModel(
      id: 'amb1',
      email: 'amb1@vialert.test',
      placa: 'ABC-123',
      codigoInterno: 'amb1',
      entidadId: 'entidad-1',
    ));
    await propagar(); // carga de streams (alertas/hospitales)
  });

  tearDown(() {
    guia.dispose();
    atencion.dispose();
    mapCtrl.dispose();
    alertCtrl.dispose();
  });

  /// Crea una alerta, la toma amb1 y arranca la atención.
  Future<void> iniciarRuta() async {
    final id = await alertCtrl.crearAlerta(
      type: 'Accidente',
      description: 'choque',
      position: posAlerta,
      creadaPorUsuarioId: 'Usuario Prueba',
      creadaPorUid: 'uid-1',
      fotos: const [],
    );
    await propagar();
    await db.tomarAlerta(alertaId: id, ambulanciaId: 'amb1');
    await propagar();
    final alerta = (await db.getAlertaById(id))!;
    await atencion.iniciarAtencion(alerta, 'amb1');
    await propagar();
  }

  test('anuncia el inicio de ruta con la primera instrucción', () async {
    await guia.iniciar();
    await iniciarRuta();

    expect(tts.frases, isNotEmpty);
    expect(tts.frases.first, contains('Iniciando ruta'));
    // Primera instrucción de la ruta falsa de MockMapsService.
    expect(tts.frases.first, contains('norte'));
  });

  test('anuncia la llegada y el traslado al hospital', () async {
    await guia.iniciar();
    await iniciarRuta();

    await atencion.finalizarManualmente();
    await propagar();
    expect(atencion.esperandoConfirmacionHospital, isTrue);
    expect(tts.frases,
        anyElement(contains('Has llegado al lugar del accidente')));

    await atencion.confirmarTrasladoHospital();
    await propagar();
    expect(tts.frases.any((f) => f.contains('Iniciando traslado al hospital')),
        isTrue);
  });

  test('silenciada no habla y reactivada vuelve a hablar', () async {
    await guia.iniciar();
    guia.alternar(); // silenciar antes de todo
    await iniciarRuta();

    expect(tts.frases, isEmpty);

    guia.alternar(); // reactivar
    await atencion.finalizarManualmente();
    await propagar();

    expect(tts.frases, isNotEmpty);
  });
}
