import 'dart:async';
import 'package:flutter/foundation.dart';
import 'alert_controller.dart';
import 'ambulancia_controller.dart';
import 'map_controller.dart';
import 'hospital_controller.dart';
import '../models/alerta_model.dart';
import '../models/hospital_model.dart';
class AtencionAlertaController extends ChangeNotifier {
  final AlertController _alertController;
  final AmbulanciaController _ambulanciaController;
  final MapController _mapController;
  final HospitalController _hospitalController;

  AtencionAlertaController(
    this._alertController,
    this._ambulanciaController,
    this._mapController,
    this._hospitalController,
  );

  static const int duracionSimulacionSegundos = 15;
  static const int duracionTrasladoHospitalSegundos = 15;

  String? selectedAlertaId;
  int remainingSeconds = 0;
  String? lastError;
  HospitalModel? hospitalPropuesto;
  HospitalModel? hospitalDestino;

  Timer? _countdownTimer;
  String? _uid;

  bool get isLoading => selectedAlertaId == 'loading';
  bool get isEnRuta =>
      selectedAlertaId != null && selectedAlertaId != 'loading';
  bool get isEnRutaHospital => hospitalDestino != null;
  bool get esperandoConfirmacionHospital => hospitalPropuesto != null;

  Future<void> atenderAlerta(AlertaModel alerta, String uid) async {
    selectedAlertaId = 'loading';
    lastError = null;
    _uid = uid;
    notifyListeners();

    try {
      await _alertController.asignarAmbulanciaAAlerta(alerta.id, uid);
      await _ambulanciaController.setEstado(uid, 'enRuta');

      // Generar ruta desde la ubicación GPS real, con recálculo automático
      final myLocation = await _mapController.getMyLocation();
      if (myLocation != null) {
        await _mapController.iniciarSeguimientoRuta(myLocation, alerta.position);
      }

      selectedAlertaId = alerta.id;
      remainingSeconds = duracionSimulacionSegundos;
      notifyListeners();

      _startCountdown(finalizarAtencion);
    } catch (e) {
      selectedAlertaId = null;
      remainingSeconds = 0;
      lastError = e.toString();
      notifyListeners();
    }
  }

  void _startCountdown(Future<void> Function() onFinish) {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingSeconds--;
      notifyListeners();

      if (remainingSeconds <= 0) {
        timer.cancel();
        onFinish();
      }
    });
  }

  Future<void> finalizarAtencion() async {
    if (selectedAlertaId == null || selectedAlertaId == 'loading') return;

    final alertaId = selectedAlertaId!;
    await _alertController.marcarComoAtendida(alertaId);
    _mapController.clearRoute();

    final miUbicacion = await _mapController.getMyLocation();
    final hospital =
        miUbicacion != null ? _hospitalController.masCercanoA(miUbicacion) : null;

    if (hospital != null) {
      hospitalPropuesto = hospital;
      remainingSeconds = 0;
      notifyListeners();
      return;
    }

    if (_uid != null) {
      await _ambulanciaController.setEstado(_uid!, 'habilitada');
    }

    selectedAlertaId = null;
    remainingSeconds = 0;
    _uid = null;
    notifyListeners();
  }

  Future<void> confirmarTrasladoHospital() async {
    if (hospitalPropuesto == null) return;

    final hospital = hospitalPropuesto!;
    hospitalDestino = hospital;
    hospitalPropuesto = null;

    if (_uid != null) {
      await _ambulanciaController.setEstado(_uid!, 'enRutaHospital');
    }

    final miUbicacion = await _mapController.getMyLocation();
    if (miUbicacion != null) {
      await _mapController.iniciarSeguimientoRuta(miUbicacion, hospital.position);
    }

    remainingSeconds = duracionTrasladoHospitalSegundos;
    notifyListeners();

    _startCountdown(_finalizarTrasladoHospital);
  }

  Future<void> rechazarTrasladoHospital() async {
    if (_uid != null) {
      await _ambulanciaController.setEstado(_uid!, 'habilitada');
    }

    hospitalPropuesto = null;
    hospitalDestino = null;
    selectedAlertaId = null;
    remainingSeconds = 0;
    _uid = null;
    notifyListeners();
  }

  Future<void> _finalizarTrasladoHospital() async {
    if (_uid != null) {
      await _ambulanciaController.setEstado(_uid!, 'habilitada');
    }

    _mapController.clearRoute();

    hospitalDestino = null;
    hospitalPropuesto = null;
    selectedAlertaId = null;
    remainingSeconds = 0;
    _uid = null;
    notifyListeners();
  }

  Future<void> finalizarManualmente() async {
    if (isEnRutaHospital) {
      _countdownTimer?.cancel();
      await _finalizarTrasladoHospital();
      return;
    }

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
    hospitalPropuesto = null;
    hospitalDestino = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
