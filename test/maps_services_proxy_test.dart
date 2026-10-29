import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vialert/services/i_maps_service.dart';
import 'package:vialert/services/maps_services_proxy.dart';

/// Espía: cuenta cuántas veces se le pide cada operación al servicio "real",
/// para verificar que el proxy evita llamadas repetidas.
class _MapsServiceEspia implements IMapsService {
  int llamadasGetRoute = 0;
  int llamadasGetRouteSummary = 0;
  List<LatLng>? rutaAEntregar;
  Map<String, dynamic>? resumenAEntregar;

  @override
  Future<List<LatLng>?> getRoute(LatLng origin, LatLng destination) async {
    llamadasGetRoute++;
    return rutaAEntregar;
  }

  @override
  Future<Map<String, dynamic>?> getRouteSummary(
      LatLng origin, LatLng destination) async {
    llamadasGetRouteSummary++;
    return resumenAEntregar;
  }
}

void main() {
  const origen = LatLng(10.4742, -73.2436);
  const destino = LatLng(10.4598, -73.2512);

  late _MapsServiceEspia espia;
  late MapsServicesProxy proxy;

  setUp(() {
    espia = _MapsServiceEspia()
      ..rutaAEntregar = [origen, destino]
      ..resumenAEntregar = {'distance_text': '1 km'};
    proxy = MapsServicesProxy(espia,
        tiempoDeVida: const Duration(milliseconds: 50));
  });

  test('getRoute solo consulta al real una vez para la misma ruta', () async {
    await proxy.getRoute(origen, destino);
    await proxy.getRoute(origen, destino);
    await proxy.getRoute(origen, destino);

    expect(espia.llamadasGetRoute, 1);
  });

  test('coordenadas con variación menor a 4 decimales reusan el caché',
      () async {
    const origenCasiIgual = LatLng(10.47421, -73.24362);

    await proxy.getRoute(origen, destino);
    await proxy.getRoute(origenCasiIgual, destino);

    expect(espia.llamadasGetRoute, 1);
  });

  test('un destino distinto genera una nueva consulta', () async {
    const otroDestino = LatLng(10.40, -73.30);

    await proxy.getRoute(origen, destino);
    await proxy.getRoute(origen, otroDestino);

    expect(espia.llamadasGetRoute, 2);
  });

  test('tras vencer el tiempo de vida se vuelve a consultar', () async {
    await proxy.getRoute(origen, destino);
    await Future.delayed(const Duration(milliseconds: 80));
    await proxy.getRoute(origen, destino);

    expect(espia.llamadasGetRoute, 2);
  });

  test('un fallo (null) no se cachea: se reintenta en cada llamada',
      () async {
    espia.rutaAEntregar = null;

    await proxy.getRoute(origen, destino);
    await proxy.getRoute(origen, destino);

    expect(espia.llamadasGetRoute, 2);
  });

  test('getRouteSummary se cachea de forma independiente de getRoute',
      () async {
    await proxy.getRoute(origen, destino);
    await proxy.getRouteSummary(origen, destino);
    await proxy.getRouteSummary(origen, destino);

    expect(espia.llamadasGetRoute, 1);
    expect(espia.llamadasGetRouteSummary, 1);
  });
}
