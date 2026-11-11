import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/ruta_detallada.dart';
import 'directions/directions_api_client.dart';
import 'i_maps_service.dart';

/// ADAPTER: traduce el JSON de Google Directions (Adaptee)
/// a lo que la app espera (IMapsService, el Target).
class GoogleDirectionsAdapter implements IMapsService {
  final DirectionsApiClient _cliente;

  GoogleDirectionsAdapter(this._cliente);

  Future<Map<String, dynamic>?> _consultar(LatLng o, LatLng d) =>
      _cliente.obtenerDirecciones(
        origenLat: o.latitude,
        origenLng: o.longitude,
        destinoLat: d.latitude,
        destinoLng: d.longitude,
      );

  @override
  Future<List<LatLng>?> getRoute(LatLng origin, LatLng destination) async {
    final data = await _consultar(origin, destination);
    if (data == null) return null;
    try {
      final poly = data['routes'][0]['overview_polyline']['points'] as String;
      return PolylinePoints()
          .decodePolyline(poly)
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getRouteSummary(
      LatLng origin, LatLng destination) async {
    final data = await _consultar(origin, destination);
    if (data == null) return null;
    try {
      final leg = data['routes'][0]['legs'][0];
      return {
        'distance_text': leg['distance']['text'],
        'distance_meters': leg['distance']['value'],
        'duration_text': leg['duration']['text'],
        'duration_seconds': leg['duration']['value'],
      };
    } catch (_) {
      return null;
    }
  }

  @override
  Future<RutaDetallada?> getRutaDetallada(
      LatLng origin, LatLng destination) async {
    final data = await _consultar(origin, destination);
    if (data == null) return null;
    try {
      final ruta = data['routes'][0];
      final leg = ruta['legs'][0];
      final poly = ruta['overview_polyline']['points'] as String;
      final puntos = PolylinePoints()
          .decodePolyline(poly)
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      final pasos = <PasoRuta>[];
      for (final paso in (leg['steps'] as List? ?? const [])) {
        final fin = paso['end_location'];
        pasos.add(PasoRuta(
          instruccion: _sinHtml(paso['html_instructions'] ?? ''),
          maniobra: paso['maneuver'] ?? '',
          posicionFin: LatLng(
            (fin['lat'] as num).toDouble(),
            (fin['lng'] as num).toDouble(),
          ),
          distanciaMetros: paso['distance']['value'],
        ));
      }

      return RutaDetallada(
        puntos: puntos,
        duracionSegundos: leg['duration']['value'],
        distanciaMetros: leg['distance']['value'],
        duracionTexto: leg['duration']['text'],
        distanciaTexto: leg['distance']['text'],
        pasos: pasos,
      );
    } catch (_) {
      return null;
    }
  }

  /// Las instrucciones de Directions vienen con etiquetas HTML (<b>, <div>…).
  String _sinHtml(String html) => html
      .replaceAll(RegExp(r'<div[^>]*>'), ' ')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}