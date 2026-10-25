// lib/models/hospital_model.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HospitalModel {
  final String id;
  final String nombre;
  final LatLng position;

  HospitalModel({
    required this.id,
    required this.nombre,
    required this.position,
  });

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'lat': position.latitude,
        'lng': position.longitude,
      };

  factory HospitalModel.fromMap(String id, Map<String, dynamic> m) {
    final lat = (m['lat'] as num).toDouble();
    final lng = (m['lng'] as num).toDouble();
    return HospitalModel(
      id: id,
      nombre: m['nombre'] ?? '',
      position: LatLng(lat, lng),
    );
  }
}
