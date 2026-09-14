import 'dart:async';
import 'package:flutter/foundation.dart';
import 'alert_controller.dart';
import 'ambulancia_controller.dart';
import 'map_controller.dart';
import '../models/alerta_model.dart';
class AtencionAlertaController extends ChangeNotifier {
  final AlertController _alertController;
  final AmbulanciaController _ambulanciaController;
  final MapController _mapController;

  AtencionAlertaController(
    this._alertController,
    this._ambulanciaController,
    this._mapController,
  );

  static const int duracionSimulacionSegundos = 30;

  String? selectedAlertaId;
  int remainingSeconds = 0;
  String? lastError;

  Timer? _countdownTimer;
  String? _uid;

  bool get isLoading => selectedAlertaId == 'loading';
  bool get isEnRuta =>
      selectedAlertaId != null && selectedAlertaId != 'loading';
  Future<void> atenderAlerta(AlertaModel alerta, String uid) async {
    selectedAlertaId = 'loading';
    lastError = null;
    _uid = uid;
    notifyListeners();

    try {
      await _alertController.asignarAmbulanciaAAlerta(alerta.id, uid);
      await _ambulanciaController.setEstado(uid, 'enRuta');

      // Generar ruta
      final myLocation = await _mapController.getMyLocation();
      if (myLocation != null) {
        await _mapController.createRoute(myLocation, alerta.position);
      }

      selectedAlertaId = alerta.id;
      remainingSeconds = duracionSimulacionSegundos;
      notifyListeners();

      _startCountdown();
    } catch (e) {
      selectedAlertaId = null;
      remainingSeconds = 0;
      lastError = e.toString();
      notifyListeners();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingSeconds--;
      notifyListeners();

      if (remainingSeconds <= 0) {
        timer.cancel();
        finalizarAtencion();
      }
    });
  }

  Future<void> finalizarAtencion() async {
    if (selectedAlertaId == null || selectedAlertaId == 'loading') return;

    final alertaId = selectedAlertaId!;
    await _alertController.marcarComoAtendida(alertaId);

    if (_uid != null) {
      await _ambulanciaController.setEstado(_uid!, 'habilitada');
    }

    _mapController.clearRoute();

    selectedAlertaId = null;
    remainingSeconds = 0;
    _uid = null;
    notifyListeners();
  }

  Future<void> finalizarManualmente() async {
    if (selectedAlertaId == null || selectedAlertaId == 'loading') return;

    _countdownTimer?.cancel();
    await finalizarAtencion();
  }

  void cancelarRuta() {
    _countdownTimer?.cancel();
    _mapController.clearRoute();
    selectedAlertaId = null;
    remainingSeconds = 0;
    _uid = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}