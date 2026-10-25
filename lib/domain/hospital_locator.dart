// lib/domain/hospital_locator.dart
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/hospital_model.dart';

/// Devuelve el hospital más cercano a [origen] según distancia en línea recta
/// (fórmula de Haversine), o `null` si [hospitales] está vacía.
HospitalModel? hospitalMasCercano(
  LatLng origen,
  List<HospitalModel> hospitales,
) {
  if (hospitales.isEmpty) return null;

  HospitalModel masCercano = hospitales.first;
  double menorDistancia = _distanciaMetros(origen, masCercano.position);

  for (final hospital in hospitales.skip(1)) {
    final distancia = _distanciaMetros(origen, hospital.position);
    if (distancia < menorDistancia) {
      menorDistancia = distancia;
      masCercano = hospital;
    }
  }

  return masCercano;
}

double _distanciaMetros(LatLng a, LatLng b) {
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
