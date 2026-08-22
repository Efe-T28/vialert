// lib/controllers/ambulancia_controller.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';
import '../models/ambulancia_model.dart';

class AmbulanciaController extends ChangeNotifier {
  final FirestoreService _fs;
  final List<AmbulanciaModel> ambulancias = [];

  AmbulanciaController(this._fs) {
    _fs.streamAmbulancias().listen((list) {
      ambulancias
        ..clear()
        ..addAll(list);
      notifyListeners();
    });
  }

  /// Asigna conductor y paramedico a la ambulancia de forma atómica:
  /// - marca fields en ambulancia
  /// - marca conductor/paramedico como ocupados (ambulanciaId)
  /// This method expects that availability reservation is already done via PersonalController
  Future<bool> asignarPersonalAtomico({
    required String ambulanciaId,
    String? conductorId,
    String? paramedicoId,
  }) async {
    final ambRef =
        FirebaseFirestore.instance.collection('ambulancias').doc(ambulanciaId);
    final conductorRef = conductorId != null
        ? FirebaseFirestore.instance
            .collection('personal')
            .doc('conductores')
            .collection('items')
            .doc(conductorId)
        : null;
    final paramRef = paramedicoId != null
        ? FirebaseFirestore.instance
            .collection('personal')
            .doc('paramedicos')
            .collection('items')
            .doc(paramedicoId)
        : null;

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final ambSnap = await tx.get(ambRef);
        if (!ambSnap.exists) throw Exception('Ambulancia no existe');

        final updateMap = <String, dynamic>{};
        if (conductorId != null) updateMap['currentConductorId'] = conductorId;
        if (paramedicoId != null) {
          updateMap['currentParamedicoId'] = paramedicoId;
        }
        updateMap['estadoOperativo'] = 'enRuta';

        tx.update(ambRef, updateMap);

        // Update personal docs if provided (assume they were reserved already but enforce)
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
      return false;
    }
  }

  /// Libera personal asignado y limpia la ambulancia (al cerrar sesion)
  Future<bool> liberarPersonalYResetAmbulancia(String ambulanciaId) async {
    final ambRef =
        FirebaseFirestore.instance.collection('ambulancias').doc(ambulanciaId);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final ambSnap = await tx.get(ambRef);
        if (!ambSnap.exists) return;
        final data = ambSnap.data()!;
        final currentConductorId = data['currentConductorId'] as String?;
        final currentParamedicoId = data['currentParamedicoId'] as String?;

        // Reset ambulancia fields
        tx.update(ambRef, {
          'currentConductorId': null,
          'currentParamedicoId': null,
          'currentAlertaId': null,
          'estadoOperativo': 'habilitada',
        });

        // Free conductor
        if (currentConductorId != null) {
          final conductorRef = FirebaseFirestore.instance
              .collection('personal')
              .doc('conductores')
              .collection('items')
              .doc(currentConductorId);
          tx.update(
              conductorRef, {'estado': 'disponible', 'ambulanciaId': null});
        }

        // Free paramedico
        if (currentParamedicoId != null) {
          final paramRef = FirebaseFirestore.instance
              .collection('personal')
              .doc('paramedicos')
              .collection('items')
              .doc(currentParamedicoId);
          tx.update(paramRef, {'estado': 'disponible', 'ambulanciaId': null});
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> setEstado(String ambulanceId, String estado) async {
    await _fs.updateAmbulancia(ambulanceId, {'estadoOperativo': estado});
  }
}
