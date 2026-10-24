import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../domain/role_resolver.dart';
import '../domain/resolvers/roles_collection_resolver.dart';
import '../domain/resolvers/usuarios_collection_resolver.dart';
import '../domain/resolvers/ambulancias_collection_resolver.dart';
import '../domain/resolvers/admins_collection_resolver.dart';
import '../domain/builders/i_ambulancia_builder.dart';
import '../models/auth_user.dart';
import './i_auth_service.dart';

/// ADAPTER: adapta FirebaseAuth (Adaptee) a IAuthService (Target),
/// traduciendo el User de Firebase al AuthUser propio de la app.
class FirebaseAuthAdapter implements IAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final List<RoleResolver> _roleResolvers;

  FirebaseAuthAdapter({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    List<RoleResolver>? roleResolvers,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _roleResolvers = roleResolvers ??
            [
              RolesCollectionResolver(),
              UsuariosCollectionResolver(),
              AmbulanciasCollectionResolver(),
              AdminsCollectionResolver(),
            ];

  AuthUser? _adaptar(User? u) =>
      u == null ? null : AuthUser(uid: u.uid, email: u.email);

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.authStateChanges().map(_adaptar);

  @override
  Future<AuthUser?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _adaptar(cred.user);
  }

  @override
  Future<AuthUser?> registerUsuarioNormal({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user!;
    final uid = user.uid;

    try {
      await _db.collection('usuarios').doc(uid).set({
        'nombre': nombre,
        'apellido': apellido,
        'cedula': cedula,
        'telefono': telefono,
        'email': email,
        'rol': 'usuario',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('roles').doc(uid).set({
        'rol': 'usuario',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await user.delete();
      rethrow;
    }

    return _adaptar(user);
  }

  /// Nombre de la segunda instancia de Firebase usada para crear ambulancias
  /// sin cerrar la sesión del admin.
  static const String _nombreAppSecundaria = 'registro';

  /// Segunda instancia de Firebase (mismo proyecto, sesión independiente).
  /// Se reutiliza si ya existe: initializeApp con el mismo nombre falla.
  Future<FirebaseApp> _appSecundaria() async {
    for (final app in Firebase.apps) {
      if (app.name == _nombreAppSecundaria) return app;
    }
    return Firebase.initializeApp(
      name: _nombreAppSecundaria,
      options: Firebase.app().options,
    );
  }

  @override
  Future<void> registerAmbulancia({
    required String email,
    required String password,
    required IAmbulanciaBuilder datos,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('No hay admin autenticado');
    }
    datos.email(email);
    datos.build(id: 'pendiente');

    final authSec = FirebaseAuth.instanceFor(app: await _appSecundaria());
    UserCredential? cred;
    try {
      cred = await authSec.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final ambulancia = datos.build(id: cred.user!.uid);
      final batch = _db.batch();
      batch.set(_db.collection('ambulancias').doc(ambulancia.id), {
        ...ambulancia.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(_db.collection('roles').doc(ambulancia.id), {
        'rol': 'ambulancia',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } catch (_) {
      try {
        await cred?.user?.delete(); // rollback: no dejar cuentas huérfanas
      } catch (_) {}
      rethrow;
    } finally {
      await authSec.signOut();
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<String?> getUserRole(String uid) async {
    try {
      for (final resolver in _roleResolvers) {
        final rol = await resolver.resolve(_db, uid);
        if (rol != null) return rol;
      }
      return null;
    } catch (e) {
      print("Error en getUserRole: $e");
      return null;
    }
  }
}