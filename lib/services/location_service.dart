// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Servicio para obtener la ubicación del dispositivo y exponer stream opcional.
class LocationService {
  Future<bool> _checkPermissions() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      // Geolocator no permite solicitar activar el servicio directamente;
      // el usuario debe activarlo desde ajustes del sistema.
      return false;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return false;
      }
    }
    if (perm == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<LatLng?> getCurrentLocation() async {
    final ok = await _checkPermissions();
    if (!ok) return null;
    final pos = await Geolocator.getCurrentPosition();
    return LatLng(pos.latitude, pos.longitude);
  }

  /// Stream de ubicación (útil para tracking de ambulancia)
  Stream<LatLng>? onLocationChanged() {
    try {
      return Geolocator.getPositionStream().map((pos) {
        return LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      return null;
    }
  }
}