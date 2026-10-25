// lib/domain/route_deviation.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'geo_math.dart';

/// Distancia mínima entre [punto] y cualquiera de los puntos de [ruta].
/// Aproximación suficiente para detectar desvíos, dado que el polyline
/// decodificado trae muchos puntos, sin necesitar proyección sobre
/// segmentos.
double distanciaMinimaARuta(LatLng punto, List<LatLng> ruta) {
  double minDistancia = double.infinity;
  for (final p in ruta) {
    final distancia = distanciaMetros(punto, p);
    if (distancia < minDistancia) minDistancia = distancia;
  }
  return minDistancia;
}
