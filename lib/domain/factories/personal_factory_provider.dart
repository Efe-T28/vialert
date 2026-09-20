// lib/domain/factories/personal_factory_provider.dart
import 'tipo_personal.dart';
import 'personal_factory.dart';
import 'conductor_factory.dart';
import 'paramedico_factory.dart';

/// Punto único donde se elige la factory según el tipo.
PersonalFactory personalFactoryPara(TipoPersonal tipo) {
  switch (tipo) {
    case TipoPersonal.conductor:
      return ConductorFactory();
    case TipoPersonal.paramedico:
      return ParamedicoFactory();
  }
}