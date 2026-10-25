import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  static const double _desviacionMaximaMetros = 30.0;
  static const Duration _intervaloMinimoRecalculo = Duration(seconds: 10);

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
    final points = await _mapsService.getRoute(origin, destination);
    if (points == null) return;
    polylines.clear();
    polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      points: points,
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
    if (_recalculando) return;

    final ahora = DateTime.now();
    if (_ultimoRecalculo != null &&
        ahora.difference(_ultimoRecalculo!) < _intervaloMinimoRecalculo) {
      return;
    }

    final ruta = polylines.first.points;
    final desviado = _distanciaMinimaARuta(posicion, ruta) > _desviacionMaximaMetros;
    if (!desviado) return;

    _recalculando = true;
    _ultimoRecalculo = ahora;
    await createRoute(posicion, _destinoActual!);
    _recalculando = false;
  }

  double _distanciaMinimaARuta(LatLng punto, List<LatLng> ruta) {
    double minDistancia = double.infinity;
    for (final p in ruta) {
      final distancia = Geolocator.distanceBetween(
        punto.latitude,
        punto.longitude,
        p.latitude,
        p.longitude,
      );
      if (distancia < minDistancia) minDistancia = distancia;
    }
    return minDistancia;
  }

  void clearRoute() {
    _positionSub?.cancel();
    _positionSub = null;
    _destinoActual = null;
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
