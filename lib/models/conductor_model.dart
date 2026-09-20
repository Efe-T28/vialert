// lib/models/conductor_model.dart
import 'personal_model.dart';

class ConductorModel extends PersonalModel {
  ConductorModel({
    required super.id,
    required super.nombre,
    required super.apellido,
    required super.cedula,
    required super.entidadId,
    super.estado,
    super.ambulanciaId,
  });

  @override
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