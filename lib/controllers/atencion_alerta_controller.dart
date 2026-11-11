import 'dart:async';
import 'package:flutter/foundation.dart';
import 'alert_controller.dart';
import 'ambulancia_controller.dart';
import 'map_controller.dart';
import 'hospital_controller.dart';
import '../models/alerta_model.dart';
import '../models/hospital_model.dart';
import '../models/ruta_detallada.dart';
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
  ) {
    // Cuando la ruta se recalcula por desvío, el ETA real cambia.
    _mapController.addListener(_onRutaActualizada);
  }

  /// Respaldo si Directions no devuelve ruta (sin red / sin API key).
  static const int duracionSimulacionSegundos = 15;
  static const int duracionTrasladoHospitalSegundos = 15;

  String? selectedAlertaId;
  int remainingSeconds = 0;

  /// Duración total del tramo vigente (para la barra de progreso). Se
  /// resetea cuando la ruta se recalcula.
  int duracionTotalSegundos = duracionSimulacionSegundos;
  String? lastError;
  HospitalModel? hospitalPropuesto;
  HospitalModel? hospitalDestino;

  Timer? _countdownTimer;
  String? _uid;
  RutaDetallada? _rutaVista;

  /// Toma el ETA real de la ruta vigente; si no hay, usa el respaldo.
  void _adoptarEta(int respaldoSegundos) {
    _rutaVista = _mapController.rutaActual;
    remainingSeconds = _mapController.etaSegundos ?? respaldoSegundos;
    duracionTotalSegundos = remainingSeconds;
  }

  void _onRutaActualizada() {
    final ruta = _mapController.rutaActual;
    if (ruta == null || !isEnRuta) return;
    if (identical(ruta, _rutaVista)) return;

    // Ruta recalculada: refrescar el ETA sin tocar el resto del estado.
    _rutaVista = ruta;
    remainingSeconds = ruta.duracionSegundos;
    duracionTotalSegundos = ruta.duracionSegundos;
    notifyListeners();
  }

  bool get isLoading => selectedAlertaId == 'loading';
  bool get isEnRuta =>
      selectedAlertaId != null && selectedAlertaId != 'loading';
  bool get isEnRutaHospital => hospitalDestino != null;
  bool get esperandoConfirmacionHospital => hospitalPropuesto != null;

  /// Reserva la alerta para esta ambulancia (transaccional). No inicia
  /// ruta ni timer: eso ocurre recién en [iniciarAtencion].
  Future<TomarAlertaResultado> tomarAlerta(
      AlertaModel alerta, String uid) async {
    // Pre-guard local: lee el stream, así funciona incluso tras reiniciar
    // la app con una alerta ya tomada.
    if (_alertController.getAlertaTomadaPor(uid) != null) {
      return TomarAlertaResultado.ambulanciaOcupada;
    }
    return _alertController.tomarAlerta(alerta.id, uid);
  }

  /// Suelta una alerta tomada que nunca inició ruta (vuelve a activa).
  Future<void> soltarAlerta(AlertaModel alerta, String uid) =>
      _alertController.liberarAlerta(alerta.id, uid);

  Future<void> iniciarAtencion(AlertaModel alerta, String uid) async {
    // Solo se puede atender una alerta ya tomada por esta ambulancia.
    if (alerta.estado != AlertState.enProceso ||
        alerta.ambulanciaAsignada != uid) {
      return;
    }

    selectedAlertaId = 'loading';
    lastError = null;
    _uid = uid;
    notifyListeners();

    try {
      await _ambulanciaController.setEstado(uid, 'enRuta');

      // Generar ruta desde la ubicación GPS real, con recálculo automático
      final myLocation = await _mapController.getMyLocation();
      if (myLocation != null) {
        await _mapController.iniciarSeguimientoRuta(myLocation, alerta.position);
      }

      selectedAlertaId = alerta.id;
      _adoptarEta(duracionSimulacionSegundos);
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
    if (_uid != null) {
      await _ambulanciaController.limpiarAlertaActual(_uid!);
    }
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

    _adoptarEta(duracionTrasladoHospitalSegundos);
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

  Future<void> cancelarRuta() async {
    _countdownTimer?.cancel();
    _mapController.clearRoute();

    // Devuelve la alerta a activa para que reaparezca en Pendientes.
    if (isEnRuta && _uid != null) {
      await _alertController.liberarAlerta(selectedAlertaId!, _uid!);
      await _ambulanciaController.setEstado(_uid!, 'habilitada');
    }

    selectedAlertaId = null;
    remainingSeconds = 0;
    _uid = null;
    hospitalPropuesto = null;
    hospitalDestino = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _mapController.removeListener(_onRutaActualizada);
    _countdownTimer?.cancel();
    super.dispose();
  }
}
