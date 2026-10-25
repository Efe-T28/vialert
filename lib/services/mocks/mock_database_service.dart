import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/alerta_model.dart';
import '../../models/ambulancia_model.dart';
import '../../models/conductor_model.dart';
import '../../models/hospital_model.dart';
import '../../models/paramedico_model.dart';
import '../../models/personal_model.dart';
import '../../models/usuario_model.dart';
import '../i_database_service.dart';

/// Base de datos en memoria. Los streams emiten el estado actual y
/// vuelven a emitir cada vez que algo cambia.
class MockDatabaseService implements IDatabaseService {
  final Map<String, AlertaModel> _alertas = {};
  final Map<String, UsuarioModel> _usuarios = {};
  final Map<String, ConductorModel> _conductores = {};
  final Map<String, ParamedicoModel> _paramedicos = {};
  final Map<String, AmbulanciaModel> _ambulancias = {};
  final Map<String, HospitalModel> _hospitales = {
    'hospital-mock-1': HospitalModel(
      id: 'hospital-mock-1',
      nombre: 'Hospital Rosario Pumarejo de López',
      position: const LatLng(10.4598, -73.2512),
    ),
    'hospital-mock-2': HospitalModel(
      id: 'hospital-mock-2',
      nombre: 'Clínica Valledupar',
      position: const LatLng(10.4680, -73.2550),
    ),
  };

  final StreamController<void> _cambios = StreamController<void>.broadcast();

  void _notificar() => _cambios.add(null);

  Stream<List<T>> _observar<T>(List<T> Function() leer) async* {
    yield leer();
    await for (final _ in _cambios.stream) {
      yield leer();
    }
  }

  // ---------- Alertas ----------
  @override
  Stream<List<AlertaModel>> streamAlertas() =>
      _observar(() => _alertas.values.toList());

  @override
  Future<void> crearAlerta(AlertaModel alerta) async {
    _alertas[alerta.id] = alerta;
    _notificar();
  }

  @override
  Future<void> updateAlerta(String id, Map<String, dynamic> data) async {
    final actual = _alertas[id];
    if (actual == null) return;
    _alertas[id] = AlertaModel.fromMap(id, {...actual.toMap(), ...data});
    _notificar();
  }

  @override
  Future<AlertaModel?> getAlertaById(String id) async => _alertas[id];

  // ---------- Usuarios ----------
  @override
  Future<UsuarioModel?> getUsuarioByUid(String uid) async => _usuarios[uid];

  @override
  Future<void> createUsuarioDoc(String uid, UsuarioModel u) async {
    _usuarios[uid] = u;
  }

  // ---------- Personal ----------
  @override
  Stream<List<ConductorModel>> streamConductoresDisponibles() => _observar(() =>
      _conductores.values.where((c) => c.estado == 'disponible').toList());

  @override
  Stream<List<ParamedicoModel>> streamParamedicosDisponibles() => _observar(() =>
      _paramedicos.values.where((p) => p.estado == 'disponible').toList());

  @override
  Future<void> guardarPersonal(PersonalModel p) async {
    if (p is ConductorModel) {
      _conductores[p.id] = p;
    } else if (p is ParamedicoModel) {
      _paramedicos[p.id] = p;
    }
    _notificar();
  }

  @override
  Future<ConductorModel?> getConductorById(String id) async =>
      _conductores[id];

  @override
  Future<ParamedicoModel?> getParamedicoById(String id) async =>
      _paramedicos[id];

  @override
  Future<void> updateConductor(String id, Map<String, dynamic> data) async {
    final actual = _conductores[id];
    if (actual == null) return;
    _conductores[id] = ConductorModel.fromMap(id, {...actual.toMap(), ...data});
    _notificar();
  }

  @override
  Future<void> updateParamedico(String id, Map<String, dynamic> data) async {
    final actual = _paramedicos[id];
    if (actual == null) return;
    _paramedicos[id] =
        ParamedicoModel.fromMap(id, {...actual.toMap(), ...data});
    _notificar();
  }

  // ---------- Ambulancias ----------
  @override
  Stream<List<AmbulanciaModel>> streamAmbulancias() =>
      _observar(() => _ambulancias.values.toList());

  @override
  Future<AmbulanciaModel?> getAmbulanciaById(String id) async =>
      _ambulancias[id];

  @override
  Future<void> crearAmbulanciaDoc(AmbulanciaModel a) async {
    _ambulancias[a.id] = a;
    _notificar();
  }

  @override
  Future<void> updateAmbulancia(String id, Map<String, dynamic> data) async {
    final actual = _ambulancias[id];
    if (actual == null) return;
    _ambulancias[id] = AmbulanciaModel.fromMap(id, {...actual.toMap(), ...data});
    _notificar();
  }

  @override
  Future<bool> asignarPersonalAAmbulancia({
    required String ambulanciaId,
    String? conductorId,
    String? paramedicoId,
  }) async {
    if (!_ambulancias.containsKey(ambulanciaId)) {
      throw Exception('Ambulancia no existe');
    }
    await updateAmbulancia(ambulanciaId, {
      if (conductorId != null) 'currentConductorId': conductorId,
      if (paramedicoId != null) 'currentParamedicoId': paramedicoId,
      'estadoOperativo': 'enRuta',
    });
    if (conductorId != null) {
      await updateConductor(
          conductorId, {'estado': 'ocupado', 'ambulanciaId': ambulanciaId});
    }
    if (paramedicoId != null) {
      await updateParamedico(
          paramedicoId, {'estado': 'ocupado', 'ambulanciaId': ambulanciaId});
    }
    return true;
  }

  @override
  Future<bool> liberarPersonalYResetAmbulancia(String ambulanciaId) async {
    final amb = _ambulancias[ambulanciaId];
    if (amb == null) return true;

    final conductorId = amb.currentConductorId;
    final paramedicoId = amb.currentParamedicoId;

    await updateAmbulancia(ambulanciaId, {
      'currentConductorId': null,
      'currentParamedicoId': null,
      'currentAlertaId': null,
      'estadoOperativo': 'habilitada',
    });
    if (conductorId != null) {
      await updateConductor(
          conductorId, {'estado': 'disponible', 'ambulanciaId': null});
    }
    if (paramedicoId != null) {
      await updateParamedico(
          paramedicoId, {'estado': 'disponible', 'ambulanciaId': null});
    }
    return true;
  }

  // ---------- Hospitales ----------
  @override
  Stream<List<HospitalModel>> streamHospitales() =>
      _observar(() => _hospitales.values.toList());

  @override
  Future<void> crearHospital(HospitalModel h) async {
    _hospitales[h.id] = h;
    _notificar();
  }

  @override
  Future<void> updateHospital(String id, Map<String, dynamic> data) async {
    final actual = _hospitales[id];
    if (actual == null) return;
    _hospitales[id] = HospitalModel.fromMap(id, {...actual.toMap(), ...data});
    _notificar();
  }

  @override
  Future<void> deleteHospital(String id) async {
    _hospitales.remove(id);
    _notificar();
  }
}