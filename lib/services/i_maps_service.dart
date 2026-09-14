import 'package:google_maps_flutter/google_maps_flutter.dart';
abstract class IMapsService {
  Future<List<LatLng>?> getRoute(LatLng origin, LatLng destination);

  Future<Map<String, dynamic>?> getRouteSummary(
      LatLng origin, LatLng destination);
}