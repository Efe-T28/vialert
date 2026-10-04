import 'i_ambulancia_builder.dart';

class AmbulanciaDirector {
  final IAmbulanciaBuilder _builder;
  AmbulanciaDirector(this._builder);

  /// Ambulancia lista para operar en una entidad.
  void construirEstandar({
    required String placa,
    required String codigoInterno,
    required String entidadId,
  }) {
    _builder
      ..placa(placa)
      ..codigoInterno(codigoInterno)
      ..entidad(entidadId)
      ..estadoOperativo('habilitada');
  }

  /// Ambulancia registrada pero fuera de servicio (p. ej. en mantenimiento).
  void construirFueraDeServicio({
    required String placa,
    required String codigoInterno,
    required String entidadId,
  }) {
    _builder
      ..placa(placa)
      ..codigoInterno(codigoInterno)
      ..entidad(entidadId)
      ..estadoOperativo('inactiva');
  }
}