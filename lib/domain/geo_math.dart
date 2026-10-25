// lib/domain/geo_math.dart
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Distancia aproximada en metros entre dos puntos (fórmula de Haversine).
/// Utilidad geométrica pura, sin dependencias de Firebase/Flutter más allá
/// del tipo `LatLng`, para que el dominio pueda calcular distancias sin
/// depender de un paquete de GPS específico (p. ej. `geolocator`).
double distanciaMetros(LatLng a, LatLng b) {
  const radioTierraMetros = 6371000.0;
  final dLat = _gradosARadianes(b.latitude - a.latitude);
  final dLng = _gradosARadianes(b.longitude - a.longitude);

  final h = sin(dLat / 2) * sin(dLat / 2) +
      cos(_gradosARadianes(a.latitude)) *
          cos(_gradosARadianes(b.latitude)) *
          sin(dLng / 2) *
          sin(dLng / 2);
  final c = 2 * atan2(sqrt(h), sqrt(1 - h));

  return radioTierraMetros * c;
}

double _gradosARadianes(double grados) => grados * pi / 180;
