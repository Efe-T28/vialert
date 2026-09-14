import 'package:cloud_firestore/cloud_firestore.dart';

import '../role_resolver.dart';
class RolesCollectionResolver implements RoleResolver {
  @override
  Future<String?> resolve(FirebaseFirestore db, String uid) async {
    final doc = await db.collection('roles').doc(uid).get();
    if (doc.exists && doc.data()?['rol'] != null) {
      return doc.data()?['rol'] as String;
    }
    return null;
  }
}