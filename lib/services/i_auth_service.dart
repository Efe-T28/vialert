// Nota: se mantiene el tipo `User` de firebase_auth por ahora.
// Esto es deuda técnica intencional para la fase de mejoras.
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> registerAmbulanciaPreservandoAdmin({
    required String adminEmail,
    required String adminPassword,
    required String email,
    required String password,
    required String placa,
    required String codigoInterno,
    required String entidadId,
  });

  Future<void> logout();

  Future<String?> getUserRole(String uid);
}