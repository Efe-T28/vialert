import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/role_resolver.dart';
import '../domain/resolvers/roles_collection_resolver.dart';
import '../domain/resolvers/usuarios_collection_resolver.dart';
import '../domain/resolvers/ambulancias_collection_resolver.dart';
import '../domain/resolvers/admins_collection_resolver.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final List<RoleResolver> _roleResolvers;

  AuthService({
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


  Stream<User?> authStateChanges() => _auth.authStateChanges();


  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }


  Future<User?> registerUsuarioNormal({
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

    return user;
  }

  Future<void> registerAmbulanciaPreservandoAdmin({
    required String adminEmail,
    required String adminPassword,
    required String email,
    required String password,
    required String placa,
    required String codigoInterno,
    required String entidadId,
  }) async {

    final adminUser = _auth.currentUser;
    if (adminUser == null) {
      throw Exception("No hay admin autenticado");
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final ambUid = cred.user!.uid;

    await _db.collection('ambulancias').doc(ambUid).set({
      'email': email,
      'placa': placa,
      'codigoInterno': codigoInterno,
      'entidadId': entidadId,
      'conductorId': null,
      'paramedicoId': null,
      'estadoOperativo': 'habilitada',
      'sesionActiva': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('roles').doc(ambUid).set({
      'rol': 'ambulancia',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _auth.signOut();

    await _auth.signInWithEmailAndPassword(
      email: adminEmail,
      password: adminPassword,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

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