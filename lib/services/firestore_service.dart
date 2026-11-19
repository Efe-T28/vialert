import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/alerta_model.dart';
import '../models/ambulancia_model.dart';
import '../models/conductor_model.dart';
import '../models/evento_alerta_model.dart';
import '../models/hospital_model.dart';
import '../models/paramedico_model.dart';
import '../models/usuario_model.dart';
import '../models/personal_model.dart';
import './i_database_service.dart';

class FirestoreService implements IDatabaseService{
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- Instrumentación: utilidades ----------

  /// Campos de la alerta que agrega la instrumentación (para el modo básico).
  static const _camposNuevosAlerta = {
    'createdAtServer', 'prioridad', 'tomadaAt', 'rutaIniciadaAt', 'llegadaAt',
    'atendidaAt', 'trasladoIniciadoAt', 'trasladoFinalizadoAt',
    'hospitalDestinoId', 'hospitalDestinoNombre', 'conductorId',
    'paramedicoId', 'etaInicialSeg', 'distanciaInicialM', 'recalculos',
    'liberaciones', 'simulada',
  };

  /// Ejecuta [completo] (con los campos nuevos). Si Firestore lo rechaza por
  /// permisos —normalmente porque las reglas aún no se actualizaron— repite
  /// la operación en modo [basico], con exactamente los campos de antes. Así
  /// una regla pendiente nunca impide tomar, liberar o crear una alerta.
  Future<T> _conRespaldo<T>(
    String nombre,
    Future<T> Function() completo,
    Future<T> Function() basico,
  ) async {
    try {
      return await completo();
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      debugPrint('[instrumentacion] $nombre: permiso denegado con los campos '
          'nuevos; se reintenta en modo básico. Revisa firestore.rules.');
      return basico();
    }
  }

  CollectionReference<Map<String, dynamic>> _eventosCol(String alertaId) =>
      _db.collection('alertas').doc(alertaId).collection('eventos');

  Map<String, dynamic> _datosEvento(
    TipoEventoAlerta tipo,
    String? ambulanciaId,
    Map<String, dynamic> meta,
  ) =>
      {
        'tipo': tipo.valor,
        'ts': FieldValue.serverTimestamp(),
        'ambulanciaId': ambulanciaId,
        'meta': meta,
      };

  //Alertas
  Stream<List<AlertaModel>> streamAlertas() {
    return _db.collection('alertas').snapshots().map((snap) => snap.docs
        .map((d) => AlertaModel.fromMap(d.id, d.data()))
        .toList());
  }

  Future<void> crearAlerta(AlertaModel alerta) async {
    final ref = _db.collection('alertas').doc(alerta.id);
    var instrumentada = true;
    await _conRespaldo<void>(
      'crearAlerta',
      () => ref.set({
        ...alerta.toMap(),
        'createdAtServer': FieldValue.serverTimestamp(),
      }),
      () {
        instrumentada = false;
        final basico = alerta.toMap()
          ..removeWhere((k, _) => _camposNuevosAlerta.contains(k));
        return ref.set(basico);
      },
    );
    if (instrumentada) {
      // No se espera: el evento nunca debe retrasar ni tumbar el reporte.
      unawaited(registrarEvento(
        alertaId: alerta.id,
        tipo: TipoEventoAlerta.creada,
        meta: {if (alerta.prioridad != null) 'prioridad': alerta.prioridad},
      ));
    }
  }

  Future<void> updateAlerta(String id, Map<String, dynamic> data) async {
    await _db.collection('alertas').doc(id).update(data);
  }

  Future<AlertaModel?> getAlertaById(String id) async {
    final s = await _db.collection('alertas').doc(id).get();
    if (!s.exists) return null;
    return AlertaModel.fromMap(s.id, s.data()!);
  }

  Future<void> agregarFotosAAlerta(String id, List<String> urls) async {
    if (urls.isEmpty) return;
    await _db
        .collection('alertas')
        .doc(id)
        .update({'fotos': FieldValue.arrayUnion(urls)});
  }

  Future<TomarAlertaResultado> tomarAlerta({
    required String alertaId,
    required String ambulanciaId,
  }) {
    return _conRespaldo(
      'tomarAlerta',
      () => _tomarAlertaTx(alertaId, ambulanciaId, instrumentar: true),
      () => _tomarAlertaTx(alertaId, ambulanciaId, instrumentar: false),
    );
  }

  Future<TomarAlertaResultado> _tomarAlertaTx(
    String alertaId,
    String ambulanciaId, {
    required bool instrumentar,
  }) async {
    final alertaRef = _db.collection('alertas').doc(alertaId);
    final ambRef = _db.collection('ambulancias').doc(ambulanciaId);

    return _db.runTransaction<TomarAlertaResultado>((tx) async {
      final alertaSnap = await tx.get(alertaRef);
      final ambSnap = await tx.get(ambRef);

      if (!alertaSnap.exists) return TomarAlertaResultado.yaTomada;
      final alerta = alertaSnap.data()!;
      if (alerta['estado'] != AlertState.activa.name ||
          alerta['ambulanciaAsignada'] != null) {
        return TomarAlertaResultado.yaTomada;
      }

      final amb = ambSnap.exists ? ambSnap.data()! : null;
      if (amb != null && amb['currentAlertaId'] != null) {
        return TomarAlertaResultado.ambulanciaOcupada;
      }

      // El personal a bordo se copia a la alerta: la ambulancia lo libera al
      // terminar y después no habría forma de saber quién atendió.
      final conductorId = amb?['currentConductorId'] as String?;
      final paramedicoId = amb?['currentParamedicoId'] as String?;

      tx.update(alertaRef, {
        'estado': AlertState.enProceso.name,
        'ambulanciaAsignada': ambulanciaId,
        if (instrumentar) 'tomadaAt': FieldValue.serverTimestamp(),
        if (instrumentar && conductorId != null) 'conductorId': conductorId,
        if (instrumentar && paramedicoId != null) 'paramedicoId': paramedicoId,
      });
      tx.update(ambRef, {'currentAlertaId': alertaId});
      if (instrumentar) {
        tx.set(
          _eventosCol(alertaId).doc(),
          _datosEvento(TipoEventoAlerta.tomada, ambulanciaId, {
            if (conductorId != null) 'conductorId': conductorId,
            if (paramedicoId != null) 'paramedicoId': paramedicoId,
          }),
        );
      }
      return TomarAlertaResultado.ok;
    });
  }

  Future<void> liberarAlerta({
    required String alertaId,
    required String ambulanciaId,
  }) {
    return _conRespaldo(
      'liberarAlerta',
      () => _liberarAlertaTx(alertaId, ambulanciaId, instrumentar: true),
      () => _liberarAlertaTx(alertaId, ambulanciaId, instrumentar: false),
    );
  }

  Future<void> _liberarAlertaTx(
    String alertaId,
    String ambulanciaId, {
    required bool instrumentar,
  }) async {
    final alertaRef = _db.collection('alertas').doc(alertaId);
    final ambRef = _db.collection('ambulancias').doc(ambulanciaId);

    await _db.runTransaction((tx) async {
      final alertaSnap = await tx.get(alertaRef);

      if (alertaSnap.exists) {
        final alerta = alertaSnap.data()!;
        // Solo revierte si la alerta sigue tomada por esta ambulancia;
        // si ya fue finalizada (atendida) no se toca.
        if (alerta['estado'] == AlertState.enProceso.name &&
            alerta['ambulanciaAsignada'] == ambulanciaId) {
          tx.update(alertaRef, {
            'estado': AlertState.activa.name,
            'ambulanciaAsignada': null,
            if (instrumentar) ...{
              'liberaciones': FieldValue.increment(1),
              // Se limpian los datos del intento anterior; el historial queda
              // en los eventos. `recalculos` se mantiene como acumulado.
              'tomadaAt': FieldValue.delete(),
              'rutaIniciadaAt': FieldValue.delete(),
              'etaInicialSeg': FieldValue.delete(),
              'distanciaInicialM': FieldValue.delete(),
              'conductorId': FieldValue.delete(),
              'paramedicoId': FieldValue.delete(),
            },
          });
          if (instrumentar) {
            tx.set(
              _eventosCol(alertaId).doc(),
              _datosEvento(TipoEventoAlerta.liberada, ambulanciaId, const {}),
            );
          }
        }
      }

      tx.update(ambRef, {'currentAlertaId': null});
    });
  }

  // ---------- Instrumentación: eventos e hitos ----------

  Future<void> registrarEvento({
    required String alertaId,
    required TipoEventoAlerta tipo,
    String? ambulanciaId,
    Map<String, dynamic> meta = const {},
  }) async {
    try {
      await _eventosCol(alertaId).add(_datosEvento(tipo, ambulanciaId, meta));
    } catch (e) {
      debugPrint('[instrumentacion] evento ${tipo.valor} no registrado: $e');
    }
  }

  Future<void> marcarHitoAlerta({
    required String alertaId,
    required HitoAlerta hito,
    String? ambulanciaId,
    Map<String, dynamic> campos = const {},
    Map<String, dynamic> meta = const {},
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('alertas').doc(alertaId), {
      hito.campo: FieldValue.serverTimestamp(),
      ...campos,
    });
    batch.set(_eventosCol(alertaId).doc(),
        _datosEvento(hito.evento, ambulanciaId, meta));
    await batch.commit();
  }

  Future<void> registrarRecalculoRuta({
    required String alertaId,
    String? ambulanciaId,
    Map<String, dynamic> meta = const {},
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('alertas').doc(alertaId),
        {'recalculos': FieldValue.increment(1)});
    batch.set(_eventosCol(alertaId).doc(),
        _datosEvento(TipoEventoAlerta.recalculo, ambulanciaId, meta));
    await batch.commit();
  }

  Future<void> cambiarEstadoOperativo(String ambulanciaId, String estado) {
    final ref = _db.collection('ambulancias').doc(ambulanciaId);
    return _conRespaldo<void>(
      'cambiarEstadoOperativo',
      () => ref.update({
        'estadoOperativo': estado,
        'ultimoCambioEstadoAt': FieldValue.serverTimestamp(),
      }),
      () => ref.update({'estadoOperativo': estado}),
    );
  }


  //Usuarios
  Future<UsuarioModel?> getUsuarioByUid(String uid) async {
    final snap = await _db.collection('usuarios').doc(uid).get();
    if (!snap.exists) return null;
    return UsuarioModel.fromMap(snap.id, snap.data()!);
  }

  Future<void> createUsuarioDoc(String uid, UsuarioModel u) async {
    await _db.collection('usuarios').doc(uid).set(u.toMap());
  }


  //Personal
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

  Future<void> guardarPersonal(PersonalModel p) async {
    final col = p is ConductorModel ? _conductoresCol() : _paramedicosCol();
    await col.doc(p.id).set(p.toMap());
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



  //Ambulancias
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

  Future<bool> asignarPersonalAAmbulancia({
    required String ambulanciaId,
    String? conductorId,
    String? paramedicoId,
  }) {
    return _conRespaldo(
      'asignarPersonal',
      () => _asignarPersonalTx(ambulanciaId, conductorId, paramedicoId,
          instrumentar: true),
      () => _asignarPersonalTx(ambulanciaId, conductorId, paramedicoId,
          instrumentar: false),
    );
  }

  Future<bool> _asignarPersonalTx(
    String ambulanciaId,
    String? conductorId,
    String? paramedicoId, {
    required bool instrumentar,
  }) async {
    final ambRef = _db.collection('ambulancias').doc(ambulanciaId);
    final conductorRef =
        conductorId != null ? _conductoresCol().doc(conductorId) : null;
    final paramRef =
        paramedicoId != null ? _paramedicosCol().doc(paramedicoId) : null;

    await _db.runTransaction((tx) async {
      final ambSnap = await tx.get(ambRef);
      if (!ambSnap.exists) throw Exception('Ambulancia no existe');

      final updateMap = <String, dynamic>{};
      if (conductorId != null) updateMap['currentConductorId'] = conductorId;
      if (paramedicoId != null) {
        updateMap['currentParamedicoId'] = paramedicoId;
      }
      updateMap['estadoOperativo'] = 'enRuta';
      if (instrumentar) {
        updateMap['enTurno'] = true;
        updateMap['turnoIniciadoAt'] = FieldValue.serverTimestamp();
        updateMap['ultimoCambioEstadoAt'] = FieldValue.serverTimestamp();
      }

      tx.update(ambRef, updateMap);

      if (conductorRef != null) {
        tx.update(
            conductorRef, {'estado': 'ocupado', 'ambulanciaId': ambulanciaId});
      }
      if (paramRef != null) {
        tx.update(
            paramRef, {'estado': 'ocupado', 'ambulanciaId': ambulanciaId});
      }
    });
    return true;
  }

  Future<bool> liberarPersonalYResetAmbulancia(String ambulanciaId) {
    return _conRespaldo(
      'liberarPersonal',
      () => _liberarPersonalTx(ambulanciaId, instrumentar: true),
      () => _liberarPersonalTx(ambulanciaId, instrumentar: false),
    );
  }

  Future<bool> _liberarPersonalTx(
    String ambulanciaId, {
    required bool instrumentar,
  }) async {
    final ambRef = _db.collection('ambulancias').doc(ambulanciaId);
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
        if (instrumentar) ...{
          'enTurno': false,
          'turnoIniciadoAt': FieldValue.delete(),
          'ultimoCambioEstadoAt': FieldValue.serverTimestamp(),
        },
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
  }

  //Hospitales
  Stream<List<HospitalModel>> streamHospitales() {
    return _db.collection('hospitales').snapshots().map((snap) => snap.docs
        .map((d) => HospitalModel.fromMap(d.id, d.data()))
        .toList());
  }

  Future<void> crearHospital(HospitalModel h) async {
    await _db.collection('hospitales').doc(h.id).set(h.toMap());
  }

  Future<void> updateHospital(String id, Map<String, dynamic> data) async {
    await _db.collection('hospitales').doc(id).update(data);
  }

  Future<void> deleteHospital(String id) async {
    await _db.collection('hospitales').doc(id).delete();
  }
}