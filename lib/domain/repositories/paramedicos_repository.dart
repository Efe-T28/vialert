import 'package:cloud_firestore/cloud_firestore.dart';
import '../personal_repository.dart';
class ParamedicosRepository implements PersonalRepository {
  final FirebaseFirestore _db;
  ParamedicosRepository(this._db);

  CollectionReference _col() =>
      _db.collection('personal').doc('paramedicos').collection('items');

  @override
  Future<bool> reservar({
    required String personalId,
    required String ambulanciaId,
  }) async {
    final ref = _col().doc(personalId);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      final data = snap.data() as Map<String, dynamic>;
      final estado = data['estado'] as String? ?? 'disponible';
      if (estado != 'disponible') return false;
      tx.update(ref, {'estado': 'ocupado', 'ambulanciaId': ambulanciaId});
      return true;
    });
  }

  @override
  Future<bool> liberar({required String personalId}) async {
    await _col().doc(personalId).update({
      'estado': 'disponible',
      'ambulanciaId': null,
    });
    return true;
  }
}