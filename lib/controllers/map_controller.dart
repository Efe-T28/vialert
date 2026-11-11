import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../domain/geo_math.dart';
import '../domain/route_deviation.dart';
import '../models/ruta_detallada.dart';
import '../services/i_maps_service.dart';
import '../services/i_location_service.dart';
import 'package:flutter/material.dart';

class MapController extends ChangeNotifier {
  GoogleMapController? _googleController;
  final IMapsService _mapsService;
  final ILocationService _locationService;
  Set<Polyline> polylines = {};
  LatLng? lastTappedPosition;

  LatLng? _destinoActual;
  StreamSubscription<LatLng>? _positionSub;
  bool _recalculando = false;
  DateTime? _ultimoRecalculo;

  /// Última ruta entregada por Directions (polyline + duración + pasos).
  /// Se renueva en cada recálculo por desvío.
  RutaDetallada? rutaActual;
  int _pasoActualIdx = 0;

  static const double _desviacionMaximaMetros = 30.0;
  static const Duration _intervaloMinimoRecalculo = Duration(seconds: 10);
  static const double _metrosParaCompletarPaso = 25.0;

  /// Duración real estimada de la ruta vigente, en segundos.
  int? get etaSegundos => rutaActual?.duracionSegundos;

  /// Próximo giro/instrucción de navegación, o null si no hay ruta o ya
  /// se recorrieron todos los pasos.
  PasoRuta? get proximoPaso {
    final pasos = rutaActual?.pasos;
    if (pasos == null || _pasoActualIdx >= pasos.length) return null;
    return pasos[_pasoActualIdx];
  }

    MapController({
    required IMapsService mapsService,
    required ILocationService locationService,
  })  : _mapsService = mapsService,
        _locationService = locationService;

  void setMapController(GoogleMapController c) {
    _googleController = c;
  }

  Future<void> moveCamera(LatLng pos, {double zoom = 16.0}) async {
    if (_googleController != null) {
      await _googleController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: pos, zoom: zoom),
      ));
    }
  }

  Future<void> createRoute(LatLng origin, LatLng destination) async {
    final ruta = await _mapsService.getRutaDetallada(origin, destination);
    if (ruta == null) return;
    rutaActual = ruta;
    _pasoActualIdx = 0;
    polylines.clear();
    polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      points: ruta.puntos,
      width: 6,
      color: const Color(0xFF2196F3),
    ));
    notifyListeners();
  }

  /// Dibuja la ruta inicial hacia [destino] y queda escuchando la posición
  /// GPS para recalcularla automáticamente si el conductor se desvía.
  Future<void> iniciarSeguimientoRuta(LatLng origen, LatLng destino) async {
    _destinoActual = destino;
    await createRoute(origen, destino);
    _escucharPosicion();
  }

  void _escucharPosicion() {
    _positionSub?.cancel();
    final stream = _locationService.onLocationChanged();
    if (stream == null) return;
    _positionSub = stream.listen(_onPosicionActualizada);
  }

  Future<void> _onPosicionActualizada(LatLng posicion) async {
    if (_destinoActual == null || polylines.isEmpty) return;

    _avanzarPaso(posicion);

    if (_recalculando) return;

    final ahora = DateTime.now();
    if (_ultimoRecalculo != null &&
        ahora.difference(_ultimoRecalculo!) < _intervaloMinimoRecalculo) {
      return;
    }

    final ruta = polylines.first.points;
    final desviado = distanciaMinimaARuta(posicion, ruta) > _desviacionMaximaMetros;
    if (!desviado) return;

    _recalculando = true;
    _ultimoRecalculo = ahora;
    await createRoute(posicion, _destinoActual!);
    _recalculando = false;
  }

  /// Marca como completados los pasos cuyo final ya se alcanzó, para que
  /// [proximoPaso] apunte siempre a la instrucción vigente.
  void _avanzarPaso(LatLng posicion) {
    final pasos = rutaActual?.pasos;
    if (pasos == null) return;
    var avanzo = false;
    while (_pasoActualIdx < pasos.length &&
        distanciaMetros(posicion, pasos[_pasoActualIdx].posicionFin) <
            _metrosParaCompletarPaso) {
      _pasoActualIdx++;
      avanzo = true;
    }
    if (avanzo) notifyListeners();
  }

  void clearRoute() {
    _positionSub?.cancel();
    _positionSub = null;
    _destinoActual = null;
    rutaActual = null;
    _pasoActualIdx = 0;
    polylines.clear();
    notifyListeners();
  }

  void setLastTapped(LatLng? pos) {
    lastTappedPosition = pos;
    notifyListeners();
  }

  Future<LatLng?> getMyLocation() async {
    return await _locationService.getCurrentLocation();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
