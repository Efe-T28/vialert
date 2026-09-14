import 'package:cloud_firestore/cloud_firestore.dart';

import '../role_resolver.dart';

class AmbulanciasCollectionResolver implements RoleResolver {
  @override
  Future<String?> resolve(FirebaseFirestore db, String uid) async {
    final doc = await db.collection('ambulancias').doc(uid).get();
    if (doc.exists) return 'ambulancia';
    return null;
  }
}