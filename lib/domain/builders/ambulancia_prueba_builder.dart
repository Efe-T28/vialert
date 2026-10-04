import '../../models/ambulancia_model.dart';
import 'i_ambulancia_builder.dart';

/// ConcreteBuilder de pruebas: rellena con datos de ejemplo lo que falte.
class AmbulanciaPruebaBuilder implements IAmbulanciaBuilder {
  static int _secuencia = 0; // compartida: evita placas/emails repetidos

  String? _placa;
  String? _codigoInterno;
  String? _entidadId;
  String? _email;
  String _estadoOperativo = 'habilitada';

  @override
  AmbulanciaPruebaBuilder placa(String valor) {
    _placa = valor;
    return this;
  }

  @override
  AmbulanciaPruebaBuilder codigoInterno(String valor) {
    _codigoInterno = valor;
    return this;
  }

  @override
  AmbulanciaPruebaBuilder entidad(String valor) {
    _entidadId = valor;
    return this;
  }

  @override
  AmbulanciaPruebaBuilder email(String valor) {
    _email = valor;
    return this;
  }

  @override
  AmbulanciaPruebaBuilder estadoOperativo(String valor) {
    _estadoOperativo = valor;
    return this;
  }

  @override
  AmbulanciaModel build({required String id}) {
    final n = (++_secuencia).toString().padLeft(3, '0');
    return AmbulanciaModel(
      id: id,
      email: _email ?? 'ambulancia$n@prueba.local',
      placa: _placa ?? 'TST$n',
      codigoInterno: _codigoInterno ?? 'AMB-$n',
      entidadId: _entidadId ?? 'ENT-PRUEBA',
      estadoOperativo: _estadoOperativo,
    );
  }
}