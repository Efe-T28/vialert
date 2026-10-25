import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import '../services/i_database_service.dart';
import '../models/hospital_model.dart';
import '../domain/hospital_locator.dart';

class HospitalController extends ChangeNotifier {
  final IDatabaseService _fs;
  final List<HospitalModel> hospitales = [];
  final _uuid = const Uuid();

  HospitalController(this._fs) {
    _fs.streamHospitales().listen((list) {
      hospitales
        ..clear()
        ..addAll(list);
      notifyListeners();
    });
  }

  Future<void> crearHospital(String nombre, LatLng position) async {
    final id = _uuid.v4();
    await _fs.crearHospital(
      HospitalModel(id: id, nombre: nombre, position: position),
    );
  }

  Future<void> actualizarHospital(
    String id,
    String nombre,
    LatLng position,
  ) async {
    await _fs.updateHospital(id, {
      'nombre': nombre,
      'lat': position.latitude,
      'lng': position.longitude,
    });
  }

  Future<void> eliminarHospital(String id) async {
    await _fs.deleteHospital(id);
  }

  HospitalModel? masCercanoA(LatLng origen) {
    return hospitalMasCercano(origen, hospitales);
  }
}
