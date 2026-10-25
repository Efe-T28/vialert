import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../i_location_service.dart';

/// Simula una ambulancia moviéndose desde una ubicación fija (Valledupar),
/// sin pedir permisos ni usar GPS real. Útil para probar en modo mock que un
/// desvío sostenido dispara el recálculo de ruta.
class MockLocationService implements ILocationService {
  static const LatLng _ubicacionFija = LatLng(10.4631, -73.2532);

  @override
  Future<LatLng?> getCurrentLocation() async => _ubicacionFija;

  @override
  Stream<LatLng>? onLocationChanged() {
    return Stream<LatLng>.periodic(const Duration(seconds: 4), (tick) {
      final deriva = (tick + 1) * 0.0004;
      return LatLng(
        _ubicacionFija.latitude + deriva,
        _ubicacionFija.longitude + deriva,
      );
    }).take(30);
  }
}
