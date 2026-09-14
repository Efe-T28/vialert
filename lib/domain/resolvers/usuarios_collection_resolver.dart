import 'package:cloud_firestore/cloud_firestore.dart';

import '../role_resolver.dart';

class UsuariosCollectionResolver implements RoleResolver {
  @override
  Future<String?> resolve(FirebaseFirestore db, String uid) async {
    final doc = await db.collection('usuarios').doc(uid).get();
    if (doc.exists) return doc.data()?['rol'] ?? 'usuario';
    return null;
  }
}