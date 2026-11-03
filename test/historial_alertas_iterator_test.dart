import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vialert/domain/iterators/historial_alertas_collection.dart';
import 'package:vialert/models/alerta_model.dart';

AlertaModel _alerta(String id, DateTime createdAt, LatLng position) {
  return AlertaModel(
    id: id,
    type: 'accidente',
    description: 'desc',
    position: position,
    createdAt: createdAt,
    creadaPorUsuarioId: 'tester',
    estado: AlertState.atendida,
  );
}

void main() {
  const referencia = LatLng(0, 0);

  // lejana: ~111km, cercana: ~11km, media: ~55km (aprox., sobre el ecuador)
  final lejana = _alerta('lejana', DateTime(2024, 1, 1), const LatLng(1, 0));
  final cercana = _alerta('cercana', DateTime(2024, 3, 1), const LatLng(0.1, 0));
  final media = _alerta('media', DateTime(2024, 2, 1), const LatLng(0.5, 0));

  final historial = HistorialAlertasCollection([lejana, cercana, media]);

  test('porFecha ordena de más reciente a más antigua por defecto', () {
    final it = historial.porFecha();
    final orden = <String>[];
    while (it.hasNext()) {
      orden.add(it.next().id);
    }
    expect(orden, ['cercana', 'media', 'lejana']);
  });

  test('porFecha ascendente ordena de más antigua a más reciente', () {
    final it = historial.porFecha(masRecientePrimero: false);
    final orden = <String>[];
    while (it.hasNext()) {
      orden.add(it.next().id);
    }
    expect(orden, ['lejana', 'media', 'cercana']);
  });

  test('porCercania ordena de la más próxima a la más lejana', () {
    final it = historial.porCercania(referencia);
    final orden = <String>[];
    while (it.hasNext()) {
      orden.add(it.next().id);
    }
    expect(orden, ['cercana', 'media', 'lejana']);
  });
}
