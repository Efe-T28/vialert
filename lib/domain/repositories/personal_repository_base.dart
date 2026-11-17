import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import '../personal_repository.dart';

abstract class PersonalRepositoryBase implements PersonalRepository {
  @protected
  final FirebaseFirestore db;

  PersonalRepositoryBase(this.db);

  @override
  @nonVirtual
  Future<bool> reservar({
    required String personalId,
    required String ambulanciaId,
  }) {
    final ref = coleccion().doc(personalId);
    return db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      if (!puedeReservar(snap.data() ?? {})) return false;
      tx.update(ref, datosReserva(ambulanciaId));
      return true;
    });
  }

  @override
  @nonVirtual
  Future<bool> liberar({required String personalId}) async {
    await coleccion().doc(personalId).update(datosLiberacion());
    return true;
  }

  @protected
  CollectionReference<Map<String, dynamic>> coleccion();

  @protected
  bool puedeReservar(Map<String, dynamic> data) =>
      (data['estado'] as String? ?? 'disponible') == 'disponible';

  @protected
  Map<String, dynamic> datosReserva(String ambulanciaId) => {
        'estado': 'ocupado',
        'ambulanciaId': ambulanciaId,
      };

  @protected
  Map<String, dynamic> datosLiberacion() => {
        'estado': 'disponible',
        'ambulanciaId': null,
      };
}
