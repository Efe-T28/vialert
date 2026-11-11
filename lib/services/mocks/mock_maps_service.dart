import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/geo_math.dart';
import '../../models/ruta_detallada.dart';
import '../i_maps_service.dart';

/// Rutas falsas: línea recta entre origen y destino, sin llamar a Google.
class MockMapsService implements IMapsService {
  @override
  Future<List<LatLng>?> getRoute(LatLng origin, LatLng destination) async =>
      [origin, destination];

  @override
  Future<Map<String, dynamic>?> getRouteSummary(
      LatLng origin, LatLng destination) async {
    return {
      'distance_text': '1.0 km',
      'distance_meters': 1000,
      'duration_text': '3 mins',
      'duration_seconds': 180,
    };
  }

  @override
  Future<RutaDetallada?> getRutaDetallada(
      LatLng origin, LatLng destination) async {
    // Duración estimada a ~30 km/h sobre la distancia en línea recta,
    // con un mínimo de 30 s para que la simulación siempre avance.
    final metros = distanciaMetros(origin, destination).round();
    final segundos = (metros / (30 / 3.6)).round().clamp(30, 3600);

    final puntoMedio = LatLng(
      (origin.latitude + destination.latitude) / 2,
      (origin.longitude + destination.longitude) / 2,
    );

    return RutaDetallada(
      puntos: [origin, destination],
      duracionSegundos: segundos,
      distanciaMetros: metros,
      duracionTexto: '${(segundos / 60).ceil()} min',
      distanciaTexto: metros >= 1000
          ? '${(metros / 1000).toStringAsFixed(1)} km'
          : '$metros m',
      pasos: [
        PasoRuta(
          instruccion: 'Dirígete hacia el norte',
          maniobra: 'straight',
          posicionFin: puntoMedio,
          distanciaMetros: metros ~/ 2,
        ),
        PasoRuta(
          instruccion: 'Gira a la derecha hacia el destino',
          maniobra: 'turn-right',
          posicionFin: destination,
          distanciaMetros: metros - metros ~/ 2,
        ),
      ],
    );
  }
}
