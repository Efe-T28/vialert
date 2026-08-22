import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';
import '../models/alerta_model.dart';

class AlertController extends ChangeNotifier {
  final FirestoreService _fs;
  final List<AlertaModel> alerts = [];
  final _uuid = const Uuid();

  AlertController(this._fs) {
    _fs.streamAlertas().listen((list) {
      alerts
        ..clear()
        ..addAll(list);
      notifyListeners();
    });
  }

  Future<void> crearAlerta({
    required String type,
    required String description,
    required LatLng position,
    required String creadaPorUsuarioId, // ✅ Ahora será el nombre
  }) async {
    final id = _uuid.v4();
    final alerta = AlertaModel(
      id: id,
      type: type,
      description: description,
      position: position,
      createdAt: DateTime.now(),
      creadaPorUsuarioId: creadaPorUsuarioId,
    );
    await _fs.crearAlerta(alerta);
  }

  Future<void> asignarAmbulanciaAAlerta(
      String alertaId, String ambulanciaId) async {
    await _fs.updateAlerta(alertaId, {
      'estado': AlertState.enProceso.name,
      'ambulanciaAsignada': ambulanciaId,
    });
  }

  Future<void> marcarComoAtendida(String alertaId) async {
    await _fs.updateAlerta(alertaId, {
      'estado': AlertState.atendida.name,
    });
  }

  /// Alertas creadas por un usuario específico
  List<AlertaModel> getAlertasByUsuario(String usuarioId) {
    return alerts.where((a) => a.creadaPorUsuarioId == usuarioId).toList();
  }

  /// Alertas atendidas por una ambulancia específica
  List<AlertaModel> getAlertasAtendidasByAmbulancia(String ambulanciaId) {
    return alerts
        .where((a) =>
            a.ambulanciaAsignada == ambulanciaId &&
            a.estado == AlertState.atendida)
        .toList();
  }

  /// Alertas activas (no atendidas)
  List<AlertaModel> getAlertasActivas() {
    return alerts.where((a) => a.estado == AlertState.activa).toList();
  }
}
