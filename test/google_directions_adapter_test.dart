import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vialert/services/directions/directions_api_client.dart';
import 'package:vialert/services/google_directions_adapter.dart';

/// Cliente falso: devuelve un JSON fijo sin tocar la red.
class _ClienteFalso extends DirectionsApiClient {
  _ClienteFalso() : super(apiKey: 'test');

  Map<String, dynamic>? respuesta;

  @override
  Future<Map<String, dynamic>?> obtenerDirecciones({
    required double origenLat,
    required double origenLng,
    required double destinoLat,
    required double destinoLng,
  }) async =>
      respuesta;
}

void main() {
  const origen = LatLng(10.4742, -73.2436);
  const destino = LatLng(10.4598, -73.2512);

  late _ClienteFalso cliente;
  late GoogleDirectionsAdapter adapter;

  setUp(() {
    cliente = _ClienteFalso();
    adapter = GoogleDirectionsAdapter(cliente);
  });

  Map<String, dynamic> respuestaValida() => {
        'routes': [
          {
            // Polyline de ejemplo de la documentación de Google (3 puntos).
            'overview_polyline': {'points': '_p~iF~ps|U_ulLnnqC_mqNvxq`@'},
            'legs': [
              {
                'duration': {'value': 300, 'text': '5 min'},
                'distance': {'value': 2500, 'text': '2.5 km'},
                'steps': [
                  {
                    'html_instructions':
                        'Dirígete hacia el <b>norte</b> por <b>Carrera 33B</b>'
                            '<div style="font-size:0.9em">Continúa recto</div>',
                    'end_location': {'lat': 10.4650, 'lng': -73.2480},
                    'distance': {'value': 1500},
                  },
                  {
                    'html_instructions': 'Gira a la derecha hacia <b>Calle 20</b>',
                    'maneuver': 'turn-right',
                    'end_location': {'lat': 10.4598, 'lng': -73.2512},
                    'distance': {'value': 1000},
                  },
                ],
              }
            ],
          }
        ],
      };

  test('getRutaDetallada traduce duración, distancia y pasos', () async {
    cliente.respuesta = respuestaValida();

    final ruta = await adapter.getRutaDetallada(origen, destino);

    expect(ruta, isNotNull);
    expect(ruta!.duracionSegundos, 300);
    expect(ruta.distanciaMetros, 2500);
    expect(ruta.duracionTexto, '5 min');
    expect(ruta.distanciaTexto, '2.5 km');
    expect(ruta.puntos, isNotEmpty);
    expect(ruta.pasos, hasLength(2));
  });

  test('limpia el HTML de las instrucciones y conserva la maniobra', () async {
    cliente.respuesta = respuestaValida();

    final ruta = await adapter.getRutaDetallada(origen, destino);
    final pasos = ruta!.pasos;

    expect(pasos[0].instruccion,
        'Dirígete hacia el norte por Carrera 33B Continúa recto');
    expect(pasos[0].maniobra, ''); // el primer paso no trae maneuver
    expect(pasos[1].instruccion, 'Gira a la derecha hacia Calle 20');
    expect(pasos[1].maniobra, 'turn-right');
    expect(pasos[1].posicionFin, const LatLng(10.4598, -73.2512));
  });

  test('una respuesta nula o malformada devuelve null sin lanzar', () async {
    cliente.respuesta = null;
    expect(await adapter.getRutaDetallada(origen, destino), isNull);

    cliente.respuesta = {'routes': []};
    expect(await adapter.getRutaDetallada(origen, destino), isNull);
  });
}
