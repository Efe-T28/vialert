import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/i_maps_service.dart';
import '../services/i_location_service.dart';
import '../services/maps_service.dart';
import '../services/location_service.dart';
import 'package:flutter/material.dart';

class MapController extends ChangeNotifier {
  GoogleMapController? _googleController;
  final IMapsService _mapsService;
  final ILocationService _locationService;
  Set<Polyline> polylines = {};
  LatLng? lastTappedPosition;

  MapController({
    IMapsService? mapsService,
    ILocationService? locationService,
  })  : _mapsService = mapsService ?? MapsService(),
        _locationService = locationService ?? LocationService();

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

  void clearRoute() {
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
}