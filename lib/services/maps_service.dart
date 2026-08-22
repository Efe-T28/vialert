// lib/services/maps_service.dart
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

/// Servicio para Google Directions API.
/// Reemplaza `apiKey` por tu clave de Directions (preferible server key o key restricta).
class MapsService {
  final String apiKey = '';

  /// Retorna lista de LatLng (polyline) y opcionalmente distancia/duracion.
  /// Devuelve null si hay error.
  Future<List<LatLng>?> getRoute(LatLng origin, LatLng destination) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) return null;
      final data = json.decode(resp.body) as Map<String, dynamic>;
      if ((data['status'] as String?) != 'OK') return null;
      final poly = data['routes'][0]['overview_polyline']['points'] as String;
      final pts = PolylinePoints().decodePolyline(poly);
      return pts.map((p) => LatLng(p.latitude, p.longitude)).toList();
    } catch (e) {
      return null;
    }
  }

  /// Opción: obtener distancia y duración (en forma legible) desde la respuesta
  Future<Map<String, dynamic>?> getRouteSummary(
      LatLng origin, LatLng destination) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) return null;
      final data = json.decode(resp.body) as Map<String, dynamic>;
      if ((data['status'] as String?) != 'OK') return null;
      final leg = data['routes'][0]['legs'][0];
      return {
        'distance_text': leg['distance']['text'],
        'distance_meters': leg['distance']['value'],
        'duration_text': leg['duration']['text'],
        'duration_seconds': leg['duration']['value'],
      };
    } catch (e) {
      return null;
    }
  }
}
