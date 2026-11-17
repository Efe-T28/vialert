import 'package:cloud_firestore/cloud_firestore.dart';
import 'personal_repository_base.dart';

class ConductoresRepository extends PersonalRepositoryBase {
  ConductoresRepository(super.db);

  @override
  CollectionReference<Map<String, dynamic>> coleccion() =>
      db.collection('personal').doc('conductores').collection('items');
}
