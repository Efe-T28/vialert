// lib/models/personal_model.dart

/// Tipo base para todo el personal de ambulancia.
/// Permite que la factory devuelva un tipo común.
abstract class PersonalModel {
  final String id;
  final String nombre;
  final String apellido;
  final String cedula;
  final String entidadId;
  final String estado; // 'disponible' | 'ocupado'
  final String? ambulanciaId;

  PersonalModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.entidadId,
    this.estado = 'disponible',
    this.ambulanciaId,
  });

  Map<String, dynamic> toMap();
}