import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Recibe el estado EXTRÍNSECO por parámetro.
abstract class IMarcador {
  Marker dibujar({
    required String id,
    required LatLng posicion,
    VoidCallback? onTap,
  });
}