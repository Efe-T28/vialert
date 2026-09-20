// lib/domain/factories/personal_factory.dart
import '../../models/personal_model.dart';
import '../../models/conductor_model.dart';
import '../../models/paramedico_model.dart';

/// Tipos de personal que la factory sabe crear.
enum TipoPersonal { conductor, paramedico }

/// Producto abstracto: cada factory concreta decide qué modelo construir.
abstract class PersonalFactory {
  PersonalModel crear({
    required String id,
    required String nombre,
    required String apellido,
    required String cedula,
    required String entidadId,
    String? telefono,
  });
}

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

/// Punto único donde se elige la factory según el tipo.
PersonalFactory personalFactoryPara(TipoPersonal tipo) {
  switch (tipo) {
    case TipoPersonal.conductor:
      return ConductorFactory();
    case TipoPersonal.paramedico:
      return ParamedicoFactory();
  }
}