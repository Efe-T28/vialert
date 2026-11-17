import 'package:cloud_firestore/cloud_firestore.dart';
import 'personal_repository_base.dart';

class ParamedicosRepository extends PersonalRepositoryBase {
  ParamedicosRepository(super.db);

  @override
  CollectionReference<Map<String, dynamic>> coleccion() =>
      db.collection('personal').doc('paramedicos').collection('items');
}
