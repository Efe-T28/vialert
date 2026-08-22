// lib/models/conductor_model.dart
class ConductorModel {
  final String id;
  final String nombre;
  final String apellido;
  final String cedula;
  final String entidadId;
  final String estado; // 'disponible' | 'ocupado'
  final String? ambulanciaId; // id ambulancia si está ocupado

  ConductorModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.entidadId,
    this.estado = 'disponible',
    this.ambulanciaId,
  });

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'apellido': apellido,
        'cedula': cedula,
        'entidadId': entidadId,
        'estado': estado,
        'ambulanciaId': ambulanciaId,
      };

  factory ConductorModel.fromMap(String id, Map<String, dynamic> m) {
    return ConductorModel(
      id: id,
      nombre: m['nombre'] ?? '',
      apellido: m['apellido'] ?? '',
      cedula: m['cedula'] ?? '',
      entidadId: m['entidadId'] ?? '',
      estado: m['estado'] ?? 'disponible',
      ambulanciaId: m['ambulanciaId'],
    );
  }
}
