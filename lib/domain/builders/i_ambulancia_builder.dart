import '../../models/ambulancia_model.dart';

abstract class IAmbulanciaBuilder {
  IAmbulanciaBuilder placa(String valor);
  IAmbulanciaBuilder codigoInterno(String valor);
  IAmbulanciaBuilder entidad(String valor);
  IAmbulanciaBuilder email(String valor);
  IAmbulanciaBuilder estadoOperativo(String valor);

 
  AmbulanciaModel build({required String id});
}

/// Se lanza cuando faltan datos o son inválidos al construir.
class AmbulanciaInvalidaException implements Exception {
  final List<String> problemas;
  AmbulanciaInvalidaException(this.problemas);

  @override
  String toString() =>
      'Datos de ambulancia inválidos: ${problemas.join(', ')}';
}