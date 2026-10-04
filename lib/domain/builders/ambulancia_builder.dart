import '../../models/ambulancia_model.dart';
import 'i_ambulancia_builder.dart';

class AmbulanciaBuilder implements IAmbulanciaBuilder {
  static const _estadosValidos = {'habilitada', 'enRuta', 'inactiva'};

  String? _placa;
  String? _codigoInterno;
  String? _entidadId;
  String? _email;
  String _estadoOperativo = 'habilitada';

  @override
  AmbulanciaBuilder placa(String valor) {
    _placa = valor.trim();
    return this;
  }

  @override
  AmbulanciaBuilder codigoInterno(String valor) {
    _codigoInterno = valor.trim();
    return this;
  }

  @override
  AmbulanciaBuilder entidad(String valor) {
    _entidadId = valor.trim().toUpperCase(); 
    return this;
  }

  @override
  AmbulanciaBuilder email(String valor) {
    _email = valor.trim();
    return this;
  }

  @override
  AmbulanciaBuilder estadoOperativo(String valor) {
    _estadoOperativo = valor.trim();
    return this;
  }

  @override
  AmbulanciaModel build({required String id}) {
    final placa = _placa ?? '';
    final codigo = _codigoInterno ?? '';
    final entidad = _entidadId ?? '';
    final email = _email ?? '';

    final problemas = <String>[
      if (placa.isEmpty) 'placa',
      if (codigo.isEmpty) 'código interno',
      if (entidad.isEmpty) 'entidad',
      if (email.isEmpty)
        'email'
      else if (!email.contains('@'))
        'email (formato inválido)',
      if (!_estadosValidos.contains(_estadoOperativo)) 'estado operativo',
    ];
    if (problemas.isNotEmpty) throw AmbulanciaInvalidaException(problemas);

    return AmbulanciaModel(
      id: id,
      email: email,
      placa: placa,
      codigoInterno: codigo,
      entidadId: entidad,
      estadoOperativo: _estadoOperativo,
    );
  }
}