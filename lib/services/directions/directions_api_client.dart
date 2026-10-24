import 'dart:convert';
import 'package:http/http.dart' as http;

/// ADAPTEE: cliente de la API Directions de Google.
/// Solo hace HTTP y devuelve el JSON crudo. No conoce LatLng ni IMapsService.
class DirectionsApiClient {
  final String apiKey;
  final http.Client _http;

  DirectionsApiClient({required this.apiKey, http.Client? client})
      : _http = client ?? http.Client();

  Future<Map<String, dynamic>?> obtenerDirecciones({
    required double origenLat,
    required double origenLng,
    required double destinoLat,
    required double destinoLng,
  }) async {
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
        'origin': '$origenLat,$origenLng',
        'destination': '$destinoLat,$destinoLng',
        'key': apiKey,
      });
      final resp = await _http.get(uri);
      if (resp.statusCode != 200) return null;
      final data = json.decode(resp.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;
      return data;
    } catch (_) {
      return null;
    }
  }
}