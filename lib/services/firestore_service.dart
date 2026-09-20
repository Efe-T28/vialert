import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/alerta_model.dart';
import '../models/ambulancia_model.dart';
import '../models/conductor_model.dart';
import '../models/paramedico_model.dart';
import '../models/usuario_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;


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

  Future<UsuarioModel?> getUsuarioByUid(String uid) async {
    final snap = await _db.collection('usuarios').doc(uid).get();
    if (!snap.exists) return null;
    return UsuarioModel.fromMap(snap.id, snap.data()!);
  }

  Future<void> createUsuarioDoc(String uid, UsuarioModel u) async {
    await _db.collection('usuarios').doc(uid).set(u.toMap());
  }

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
      rethrow;
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
      rethrow;
    }
  }

  Future<bool> asignarPersonalAAmbulancia({
    required String ambulanciaId,
    String? conductorId,
    String? paramedicoId,
  }) async {
    final ambRef = _db.collection('ambulancias').doc(ambulanciaId);
    final conductorRef = conductorId != null
        ? _conductoresCol().doc(conductorId)
        : null;
    final paramRef =
        paramedicoId != null ? _paramedicosCol().doc(paramedicoId) : null;

    try {
      await _db.runTransaction((tx) async {
        final ambSnap = await tx.get(ambRef);
        if (!ambSnap.exists) throw Exception('Ambulancia no existe');

        final updateMap = <String, dynamic>{};
        if (conductorId != null) updateMap['currentConductorId'] = conductorId;
        if (paramedicoId != null) {
          updateMap['currentParamedicoId'] = paramedicoId;
        }
        updateMap['estadoOperativo'] = 'enRuta';

        tx.update(ambRef, updateMap);

        if (conductorRef != null) {
          tx.update(conductorRef,
              {'estado': 'ocupado', 'ambulanciaId': ambulanciaId});
        }
        if (paramRef != null) {
          tx.update(
              paramRef, {'estado': 'ocupado', 'ambulanciaId': ambulanciaId});
        }
      });
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> liberarPersonalYResetAmbulancia(String ambulanciaId) async {
    final ambRef = _db.collection('ambulancias').doc(ambulanciaId);
    try {
      await _db.runTransaction((tx) async {
        final ambSnap = await tx.get(ambRef);
        if (!ambSnap.exists) return;
        final data = ambSnap.data()!;
        final currentConductorId = data['currentConductorId'] as String?;
        final currentParamedicoId = data['currentParamedicoId'] as String?;

        tx.update(ambRef, {
          'currentConductorId': null,
          'currentParamedicoId': null,
          'currentAlertaId': null,
          'estadoOperativo': 'habilitada',
        });

        if (currentConductorId != null) {
          tx.update(_conductoresCol().doc(currentConductorId),
              {'estado': 'disponible', 'ambulanciaId': null});
        }

        if (currentParamedicoId != null) {
          tx.update(_paramedicosCol().doc(currentParamedicoId),
              {'estado': 'disponible', 'ambulanciaId': null});
        }
      });
      return true;
    } catch (e) {
      rethrow;
    }
  }
}