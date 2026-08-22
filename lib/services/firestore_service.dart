// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/alerta_model.dart';
import '../models/ambulancia_model.dart';
import '../models/conductor_model.dart';
import '../models/paramedico_model.dart';
import '../models/usuario_model.dart';

/// Encapsula operaciones de Firestore.
/// Estructura recomendada:
/// - usuarios/{uid}
/// - admins/{uid}
/// - ambulancias/{uid}
/// - alertas/{id}
/// - personal/conductores/items/{id}
/// - personal/paramedicos/items/{id}
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------------
  // ALERTAS
  // -------------------------
  Stream<List<AlertaModel>> streamAlertas() {
    return _db.collection('alertas').snapshots().map((snap) => snap.docs
        .map((d) => AlertaModel.fromMap(d.id, d.data()))
        .toList());
  }

  Future<void> crearAlerta(AlertaModel alerta) async {
    await _db.collection('alertas').doc(alerta.id).set(alerta.toMap());
  }

  Future<void> updateAlerta(String id, Map<String, dynamic> data) async {
    await _db.collection('alertas').doc(id).update(data);
  }

  Future<AlertaModel?> getAlertaById(String id) async {
    final s = await _db.collection('alertas').doc(id).get();
    if (!s.exists) return null;
    return AlertaModel.fromMap(s.id, s.data()!);
  }

  // -------------------------
  // USUARIOS
  // -------------------------
  Future<UsuarioModel?> getUsuarioByUid(String uid) async {
    final snap = await _db.collection('usuarios').doc(uid).get();
    if (!snap.exists) return null;
    return UsuarioModel.fromMap(snap.id, snap.data()!);
  }

  Future<void> createUsuarioDoc(String uid, UsuarioModel u) async {
    await _db.collection('usuarios').doc(uid).set(u.toMap());
  }

  // -------------------------
  // PERSONAL (Opción 1: estado en cada personal)
  // -------------------------
  CollectionReference _conductoresCol() =>
      _db.collection('personal').doc('conductores').collection('items');

  CollectionReference _paramedicosCol() =>
      _db.collection('personal').doc('paramedicos').collection('items');

  Stream<List<ConductorModel>> streamConductoresDisponibles() {
    return _conductoresCol()
        .where('estado', isEqualTo: 'disponible')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                ConductorModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<ParamedicoModel>> streamParamedicosDisponibles() {
    return _paramedicosCol()
        .where('estado', isEqualTo: 'disponible')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                ParamedicoModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> crearConductor(ConductorModel c) async {
    await _conductoresCol().doc(c.id).set(c.toMap());
  }

  Future<void> crearParamedico(ParamedicoModel p) async {
    await _paramedicosCol().doc(p.id).set(p.toMap());
  }

  Future<ConductorModel?> getConductorById(String id) async {
    final snap = await _conductoresCol().doc(id).get();
    if (!snap.exists) return null;
    return ConductorModel.fromMap(snap.id, snap.data() as Map<String, dynamic>);
  }

  Future<ParamedicoModel?> getParamedicoById(String id) async {
    final snap = await _paramedicosCol().doc(id).get();
    if (!snap.exists) return null;
    return ParamedicoModel.fromMap(
        snap.id, snap.data() as Map<String, dynamic>);
  }

  Future<void> updateConductor(String id, Map<String, dynamic> data) async {
    await _conductoresCol().doc(id).update(data);
  }

  Future<void> updateParamedico(String id, Map<String, dynamic> data) async {
    await _paramedicosCol().doc(id).update(data);
  }

  // -------------------------
  // AMBULANCIAS
  // -------------------------
  Stream<List<AmbulanciaModel>> streamAmbulancias() {
    return _db.collection('ambulancias').snapshots().map((snap) => snap.docs
        .map((d) => AmbulanciaModel.fromMap(d.id, d.data()))
        .toList());
  }

  Future<AmbulanciaModel?> getAmbulanciaById(String id) async {
    final s = await _db.collection('ambulancias').doc(id).get();
    if (!s.exists) return null;
    return AmbulanciaModel.fromMap(s.id, s.data()!);
  }

  Future<void> crearAmbulanciaDoc(AmbulanciaModel a) async {
    await _db.collection('ambulancias').doc(a.id).set(a.toMap());
  }

  Future<void> updateAmbulancia(String id, Map<String, dynamic> data) async {
    await _db.collection('ambulancias').doc(id).update(data);
  }

  // -------------------------
  // UTILS: operaciones atómicas (transacciones)
  // -------------------------
  /// Reserva personal (conductor o paramedico) de forma transaccional:
  /// devuelve true si pudo reservar (estado -> 'ocupado' y ambulanciaId)
  Future<bool> reservarPersonal({
    required String tipo, // 'conductor' | 'paramedico'
    required String personalId,
    required String ambulanciaId,
  }) async {
    final col = tipo == 'conductor' ? _conductoresCol() : _paramedicosCol();
    final ref = col.doc(personalId);
    try {
      return await _db.runTransaction<bool>((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return false;
        final data = snap.data() as Map<String, dynamic>;
        final estado = data['estado'] as String? ?? 'disponible';
        if (estado != 'disponible') return false;
        tx.update(ref, {'estado': 'ocupado', 'ambulanciaId': ambulanciaId});
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  Future<bool> liberarPersonal({
    required String tipo,
    required String personalId,
  }) async {
    final col = tipo == 'conductor' ? _conductoresCol() : _paramedicosCol();
    final ref = col.doc(personalId);
    try {
      await ref.update({'estado': 'disponible', 'ambulanciaId': null});
      return true;
    } catch (_) {
      return false;
    }
  }
}
