import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/ruta_detallada.dart';

abstract class IMapsService {
  Future<List<LatLng>?> getRoute(LatLng origin, LatLng destination);

  Future<Map<String, dynamic>?> getRouteSummary(
      LatLng origin, LatLng destination);

  /// Ruta con duración/distancia reales y pasos de navegación, en una
  /// sola consulta.
  Future<RutaDetallada?> getRutaDetallada(LatLng origin, LatLng destination);
}
