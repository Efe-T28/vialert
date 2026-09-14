import 'package:cloud_firestore/cloud_firestore.dart';
abstract class RoleResolver {
  Future<String?> resolve(FirebaseFirestore db, String uid);
}