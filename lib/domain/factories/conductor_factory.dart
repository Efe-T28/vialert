// lib/domain/factories/conductor_factory.dart
import '../../models/personal_model.dart';
import '../../models/conductor_model.dart';
import 'personal_factory.dart';

class ConductorFactory implements PersonalFactory {
  @override
  PersonalModel crear({
    required String id,
    required String nombre,
    required String apellido,
    required String cedula,
    required String entidadId,
    String? telefono, // los conductores no usan teléfono
  }) {
    return ConductorModel(
      id: id,
      nombre: nombre,
      apellido: apellido,
      cedula: cedula,
      entidadId: entidadId,
    );
  }
}