import 'package:firebase_auth/firebase_auth.dart';
import '../i_auth_service.dart';
import '../../domain/builders/i_ambulancia_builder.dart';

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
  Future<void> registerAmbulancia({
    required String email,
    required String password,
    required IAmbulanciaBuilder datos,
  }) async {
    datos.email(email);
    datos.build(id: 'mock-pendiente'); // valida igual que el servicio real
  }

  @override
  Future<void> logout() async {}

  @override
  Future<String?> getUserRole(String uid) async => 'usuario';
}