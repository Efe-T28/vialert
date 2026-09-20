// lib/models/paramedico_model.dart
import 'personal_model.dart';

class ParamedicoModel extends PersonalModel {
  final String telefono;

  ParamedicoModel({
    required super.id,
    required super.nombre,
    required super.apellido,
    required super.cedula,
    required this.telefono,
    required super.entidadId,
    super.estado,
    super.ambulanciaId,
  });

  @override
  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'apellido': apellido,
        'cedula': cedula,
        'telefono': telefono,
        'entidadId': entidadId,
        'estado': estado,
        'ambulanciaId': ambulanciaId,
      };

  factory ParamedicoModel.fromMap(String id, Map<String, dynamic> m) {
    return ParamedicoModel(
      id: id,
      nombre: m['nombre'] ?? '',
      apellido: m['apellido'] ?? '',
      cedula: m['cedula'] ?? '',
      telefono: m['telefono'] ?? '',
      entidadId: m['entidadId'] ?? '',
      estado: m['estado'] ?? 'disponible',
      ambulanciaId: m['ambulanciaId'],
    );
  }
}