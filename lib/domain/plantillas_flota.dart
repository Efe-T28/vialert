import 'builders/i_ambulancia_builder.dart';

class PlantillasFlota {
  
  PlantillasFlota._();

  // La única instancia, creada una sola vez al cargar la clase.
  static final PlantillasFlota _instancia = PlantillasFlota._();

  // Siempre devuelve _instancia, nunca crea otra.
  factory PlantillasFlota() => _instancia;

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

  /// Vacía el registro (logout, pruebas).
  void reiniciar() => _plantillas.clear();
}