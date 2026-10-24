import '../i_auth_service.dart';
import '../../domain/builders/i_ambulancia_builder.dart';
import '../../models/auth_user.dart';

class MockAuthService implements IAuthService {
  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(null);

  @override
  Future<AuthUser?> login(String email, String password) async =>
      AuthUser(uid: 'mock-uid', email: email);

  @override
  Future<AuthUser?> registerUsuarioNormal({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    required String email,
    required String password,
  }) async =>
      AuthUser(uid: 'mock-uid', email: email);

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