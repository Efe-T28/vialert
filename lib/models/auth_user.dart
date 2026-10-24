/// Usuario autenticado, independiente de cualquier proveedor (Firebase, etc.).
class AuthUser {
  final String uid;
  final String? email;

  const AuthUser({required this.uid, this.email});
}