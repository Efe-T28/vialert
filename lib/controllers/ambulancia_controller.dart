// lib/controllers/ambulancia_controller.dart
import 'package:flutter/material.dart';

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

  Future<bool> asignarPersonalAtomico({
    required String ambulanciaId,
    String? conductorId,
    String? paramedicoId,
  }) {
    return _fs.asignarPersonalAAmbulancia(
      ambulanciaId: ambulanciaId,
      conductorId: conductorId,
      paramedicoId: paramedicoId,
    );
  }

  Future<bool> liberarPersonalYResetAmbulancia(String ambulanciaId) {
    return _fs.liberarPersonalYResetAmbulancia(ambulanciaId);
  }

  Future<void> setEstado(String ambulanceId, String estado) async {
    await _fs.updateAmbulancia(ambulanceId, {'estadoOperativo': estado});
  }
}