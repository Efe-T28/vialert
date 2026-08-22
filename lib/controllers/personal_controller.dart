// lib/controllers/personal_controller.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../services/firestore_service.dart';
import '../models/conductor_model.dart';
import '../models/paramedico_model.dart';

class PersonalController extends ChangeNotifier {
  final FirestoreService _fs;
  final List<ConductorModel> conductoresDisponibles = [];
  final List<ParamedicoModel> paramedicosDisponibles = [];
  final _uuid = const Uuid();

  PersonalController(this._fs) {
    _fs.streamConductoresDisponibles().listen((list) {
      conductoresDisponibles
        ..clear()
        ..addAll(list);
      notifyListeners();
    });
    _fs.streamParamedicosDisponibles().listen((list) {
      paramedicosDisponibles
        ..clear()
        ..addAll(list);
      notifyListeners();
    });
  }

  Future<void> crearConductor({
    required String nombre,
    required String apellido,
    required String cedula,
    required String entidadId,
  }) async {
    final id = _uuid.v4();
    final c = ConductorModel(
      id: id,
      nombre: nombre,
      apellido: apellido,
      cedula: cedula,
      entidadId: entidadId,
      estado: 'disponible',
    );
    await _fs.crearConductor(c);
  }

  Future<void> crearParamedico({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    required String entidadId,
  }) async {
    final id = _uuid.v4();
    final p = ParamedicoModel(
      id: id,
      nombre: nombre,
      apellido: apellido,
      cedula: cedula,
      telefono: telefono,
      entidadId: entidadId,
      estado: 'disponible',
    );
    await _fs.crearParamedico(p);
  }

  /// Marca conductor como ocupado con ambulanciaId usando transacción para evitar race-conditions.
  Future<bool> reservarConductor(
      String conductorId, String ambulanciaId) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('personal')
          .doc('conductores')
          .collection('items')
          .doc(conductorId);

      return await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return false;
        final data = snap.data()!;
        final estado = data['estado'] ?? 'disponible';
        if (estado != 'disponible') return false;
        tx.update(ref, {'estado': 'ocupado', 'ambulanciaId': ambulanciaId});
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> liberarConductor(String conductorId) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('personal')
          .doc('conductores')
          .collection('items')
          .doc(conductorId);

      await ref.update({'estado': 'disponible', 'ambulanciaId': null});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> reservarParamedico(
      String paramedicoId, String ambulanciaId) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('personal')
          .doc('paramedicos')
          .collection('items')
          .doc(paramedicoId);

      return await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return false;
        final data = snap.data()!;
        final estado = data['estado'] ?? 'disponible';
        if (estado != 'disponible') return false;
        tx.update(ref, {'estado': 'ocupado', 'ambulanciaId': ambulanciaId});
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> liberarParamedico(String paramedicoId) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('personal')
          .doc('paramedicos')
          .collection('items')
          .doc(paramedicoId);

      await ref.update({'estado': 'disponible', 'ambulanciaId': null});
      return true;
    } catch (e) {
      return false;
    }
  }
}
