import 'package:google_maps_flutter/google_maps_flutter.dart';
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
}