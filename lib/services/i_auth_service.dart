import '../domain/builders/i_ambulancia_builder.dart';
import '../models/auth_user.dart';

abstract class IAuthService {
  Stream<AuthUser?> authStateChanges();

  Future<AuthUser?> login(String email, String password);

  Future<AuthUser?> registerUsuarioNormal({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    required String email,
    required String password,
  });

  /// Crea la cuenta de una ambulancia sin cerrar la sesión del admin.
  Future<void> registerAmbulancia({
    required String email,
    required String password,
    required IAmbulanciaBuilder datos,
  });

  Future<void> logout();

  Future<String?> getUserRole(String uid);
}