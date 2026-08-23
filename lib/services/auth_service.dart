import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream de cambios en autenticación
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Iniciar sesión
  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  /// Registrar usuario normal
  Future<User?> registerUsuarioNormal({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    required String email,
    required String password,
  }) async {
    // 1. Crear usuario en Auth
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user!;
    final uid = user.uid;

    try {
      // 2. Crear documento en la colección 'usuarios'
      await _db.collection('usuarios').doc(uid).set({
        'nombre': nombre,
        'apellido': apellido,
        'cedula': cedula,
        'telefono': telefono,
        'email': email,
        'rol': 'usuario',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Crear documento en 'roles'
      await _db.collection('roles').doc(uid).set({
        'rol': 'usuario',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Si falla la escritura en Firestore, no dejar un usuario huérfano
      // en Auth: lo eliminamos para que el registro se pueda reintentar
      // limpiamente con el mismo correo.
      await user.delete();
      rethrow;
    }

    return user;
  }

  /// Registrar ambulancia SIN perder la sesión del admin
  Future<void> registerAmbulanciaPreservandoAdmin({
    required String adminEmail,
    required String adminPassword,
    required String email,
    required String password,
    required String placa,
    required String codigoInterno,
    required String entidadId,
  }) async {
    // Admin actual
    final adminUser = _auth.currentUser;
    if (adminUser == null) {
      throw Exception("No hay admin autenticado");
    }

    // 1. Crear usuario ambulancia (esto LOGUEA como ambulancia)
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final ambUid = cred.user!.uid;

    // 2. Crear documento en colección 'ambulancias'
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

    // 3. Rol
    await _db.collection('roles').doc(ambUid).set({
      'rol': 'ambulancia',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 4. Cerrar sesión de ambulancia
    await _auth.signOut();

    // 5. VOLVER a iniciar sesión como admin
    await _auth.signInWithEmailAndPassword(
      email: adminEmail,
      password: adminPassword,
    );
  }

  /// Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<String?> getUserRole(String uid) async {
    try {
      final roleDoc = await _db.collection('roles').doc(uid).get();
      if (roleDoc.exists && roleDoc.data()?['rol'] != null) {
        return roleDoc['rol'] as String;
      }

      final u = await _db.collection('usuarios').doc(uid).get();
      if (u.exists) return u.data()?['rol'] ?? "usuario";

      final amb = await _db.collection('ambulancias').doc(uid).get();
      if (amb.exists) return "ambulancia";

      final adm = await _db.collection('admins').doc(uid).get();
      if (adm.exists) return "admin";

      return null;
    } catch (e) {
      print("Error en getUserRole: $e");
      return null;
    } 
  }
}