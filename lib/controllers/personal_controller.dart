import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';
import '../models/conductor_model.dart';
import '../models/paramedico_model.dart';
import '../domain/personal_repository.dart';

class PersonalController extends ChangeNotifier {
  final FirestoreService _fs;
  final PersonalRepository _conductoresRepo;
  final PersonalRepository _paramedicosRepo;
  final List<ConductorModel> conductoresDisponibles = [];
  final List<ParamedicoModel> paramedicosDisponibles = [];
  final _uuid = const Uuid();

  PersonalController(
    this._fs,
    this._conductoresRepo,
    this._paramedicosRepo,
  ) {
    _fs.streamConductoresDisponibles().listen((list) {
      conductoresDisponibles
        ..clear()
        ..addAll(list);
      notifyListeners();
    });
    _fs.streamParamedicosDisponibles().listen((list) {
      paramedicosDisponibles
        ..clear()
        ..addAll(list);
      notifyListeners();
    });
  }

  Future<void> crearConductor({
    required String nombre,
    required String apellido,
    required String cedula,
    required String entidadId,
  }) async {
    final id = _uuid.v4();
    final c = ConductorModel(
      id: id,
      nombre: nombre,
      apellido: apellido,
      cedula: cedula,
      entidadId: entidadId,
      estado: 'disponible',
    );
    await _fs.crearConductor(c);
  }

  Future<void> crearParamedico({
    required String nombre,
    required String apellido,
    required String cedula,
    required String telefono,
    required String entidadId,
  }) async {
    final id = _uuid.v4();
    final p = ParamedicoModel(
      id: id,
      nombre: nombre,
      apellido: apellido,
      cedula: cedula,
      telefono: telefono,
      entidadId: entidadId,
      estado: 'disponible',
    );
    await _fs.crearParamedico(p);
  }

  Future<bool> reservarConductor(String conductorId, String ambulanciaId) {
    return _conductoresRepo.reservar(
      personalId: conductorId,
      ambulanciaId: ambulanciaId,
    );
  }

  Future<bool> liberarConductor(String conductorId) {
    return _conductoresRepo.liberar(personalId: conductorId);
  }

  Future<bool> reservarParamedico(String paramedicoId, String ambulanciaId) {
    return _paramedicosRepo.reservar(
      personalId: paramedicoId,
      ambulanciaId: ambulanciaId,
    );
  }

  Future<bool> liberarParamedico(String paramedicoId) {
    return _paramedicosRepo.liberar(personalId: paramedicoId);
  }
}