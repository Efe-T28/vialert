abstract class PersonalRepository {
  Future<bool> reservar({
    required String personalId,
    required String ambulanciaId,
  });

  /// Libera al personal, dejándolo disponible de nuevo.
  Future<bool> liberar({required String personalId});
}