import 'builders/i_ambulancia_builder.dart';

class PlantillasFlota {
  final Map<String, IAmbulanciaBuilder> _plantillas = {};

  static String normalizar(String entidadId) => entidadId.trim().toUpperCase();

  List<String> get entidades => _plantillas.keys.toList()..sort();

  void registrar(String entidadId, IAmbulanciaBuilder base) {
    _plantillas[normalizar(entidadId)] = base.clone();
  }

  /// Entrega un clon listo para completar. Nunca entrega el original.
  IAmbulanciaBuilder nueva(String entidadId) {
    final base = _plantillas[normalizar(entidadId)];
    if (base == null) {
      throw StateError('No hay plantilla para la entidad $entidadId');
    }
    return base.clone();
  }
}