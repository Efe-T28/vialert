import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'i_location_service.dart';

class LocationService implements ILocationService {
  Future<bool> _checkPermissions() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
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

  @override
  Future<LatLng?> getCurrentLocation() async {
    final ok = await _checkPermissions();
    if (!ok) return null;
    final pos = await Geolocator.getCurrentPosition();
    return LatLng(pos.latitude, pos.longitude);
  }

  @override
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