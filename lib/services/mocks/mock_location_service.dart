import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../i_location_service.dart';

/// Ubicación fija (Valledupar), sin pedir permisos ni usar GPS.
class MockLocationService implements ILocationService {
  static const LatLng _ubicacionFija = LatLng(10.4631, -73.2532);

  @override
  Future<LatLng?> getCurrentLocation() async => _ubicacionFija;

  @override
  Stream<LatLng>? onLocationChanged() => Stream<LatLng>.value(_ubicacionFija);
}