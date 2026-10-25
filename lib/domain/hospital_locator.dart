// lib/domain/hospital_locator.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'geo_math.dart';
import '../models/hospital_model.dart';

/// Devuelve el hospital más cercano a [origen] según distancia en línea recta
/// (fórmula de Haversine), o `null` si [hospitales] está vacía.
HospitalModel? hospitalMasCercano(
  LatLng origen,
  List<HospitalModel> hospitales,
) {
  if (hospitales.isEmpty) return null;

  HospitalModel masCercano = hospitales.first;
  double menorDistancia = distanciaMetros(origen, masCercano.position);

  for (final hospital in hospitales.skip(1)) {
    final distancia = distanciaMetros(origen, hospital.position);
    if (distancia < menorDistancia) {
      menorDistancia = distancia;
      masCercano = hospital;
    }
  }

  return masCercano;
}
