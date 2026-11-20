import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/ubicacion_model.dart';
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
      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      );
      return Geolocator.getPositionStream(locationSettings: settings)
          .map((pos) => LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<UbicacionModel>? onPositionChanged({bool segundoPlano = false}) {
    try {
      final LocationSettings settings;
      if (segundoPlano && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // El servicio en primer plano (con su notificación fija) es lo que
        // mantiene vivo el seguimiento con la pantalla bloqueada.
        settings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
          intervalDuration: const Duration(seconds: 5),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'ViAlert - ambulancia en servicio',
            notificationText: 'Compartiendo la ubicación con la central',
            enableWakeLock: true,
          ),
        );
      } else {
        settings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        );
      }
      return Geolocator.getPositionStream(locationSettings: settings)
          .map((pos) => UbicacionModel(
                lat: pos.latitude,
                lng: pos.longitude,
                rumbo: pos.heading >= 0 ? _r1(pos.heading) : null,
                velocidadKmh: pos.speed >= 0 ? _r1(pos.speed * 3.6) : null,
                precisionM: pos.accuracy >= 0 ? _r1(pos.accuracy) : null,
              ));
    } catch (e) {
      return null;
    }
  }

  /// Un decimal basta y mantiene el documento pequeño.
  double _r1(double v) => (v * 10).roundToDouble() / 10;
}
