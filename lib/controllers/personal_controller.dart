import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/i_database_service.dart';
import '../models/conductor_model.dart';
import '../models/paramedico_model.dart';
import '../domain/personal_repository.dart';
import '../domain/factories/personal_factory.dart';

class PersonalController extends ChangeNotifier {
  final IDatabaseService _fs;
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

  /// Crea un conductor o paramédico usando la factory correspondiente.
  /// Reemplaza a crearConductor() y crearParamedico().
  Future<void> crearPersonal(
    TipoPersonal tipo, {
    required String nombre,
    required String apellido,
    required String cedula,
    required String entidadId,
    String? telefono,
  }) async {
    final factory = personalFactoryPara(tipo);
    final personal = factory.crear(
      id: _uuid.v4(),
      nombre: nombre,
      apellido: apellido,
      cedula: cedula,
      entidadId: entidadId,
      telefono: telefono,
    );
    await _fs.guardarPersonal(personal);
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