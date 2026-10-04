import 'package:firebase_auth/firebase_auth.dart';
import '../domain/builders/i_ambulancia_builder.dart';

abstract class IAuthService {
  Stream<User?> authStateChanges();

  Future<User?> login(String email, String password);

  Future<User?> registerUsuarioNormal({
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