// lib/domain/factories/paramedico_factory.dart
import '../../models/personal_model.dart';
import '../../models/paramedico_model.dart';
import 'personal_factory.dart';

class ParamedicoFactory implements PersonalFactory {
  @override
  PersonalModel crear({
    required String id,
    required String nombre,
    required String apellido,
    required String cedula,
    required String entidadId,
    String? telefono,
  }) {
    return ParamedicoModel(
      id: id,
      nombre: nombre,
      apellido: apellido,
      cedula: cedula,
      telefono: telefono ?? '',
      entidadId: entidadId,
    );
  }
}