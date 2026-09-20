// lib/domain/factories/personal_factory.dart
import '../../models/personal_model.dart';

/// Creador abstracto: cada factory concreta decide qué modelo construir.
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