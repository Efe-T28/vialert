import 'package:firebase_auth/firebase_auth.dart';
import '../i_auth_service.dart';


class MockAuthService implements IAuthService {
  @override
  Stream<User?> authStateChanges() => Stream<User?>.value(null);

  @override
  Future<User?> login(String email, String password) async {
    throw UnsupportedError('MockAuthService no puede crear un User de Firebase');
  }

  @override
  Future<User?> registerUsuarioNormal({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    required String email,
    required String password,
  }) async {
    return null;
  }

  @override
  Future<void> registerAmbulanciaPreservandoAdmin({
    required String adminEmail,
    required String adminPassword,
    required String email,
    required String password,
    required String placa,
    required String codigoInterno,
    required String entidadId,
  }) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<String?> getUserRole(String uid) async => 'usuario';
}