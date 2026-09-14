import 'package:cloud_firestore/cloud_firestore.dart';

import '../role_resolver.dart';
class AdminsCollectionResolver implements RoleResolver {
  @override
  Future<String?> resolve(FirebaseFirestore db, String uid) async {
    final doc = await db.collection('admins').doc(uid).get();
    if (doc.exists) return 'admin';
    return null;
  }
}