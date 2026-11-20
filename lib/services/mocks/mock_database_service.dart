import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/alerta_model.dart';
import '../../models/ambulancia_model.dart';
import '../../models/conductor_model.dart';
import '../../models/evento_alerta_model.dart';
import '../../models/ubicacion_model.dart';
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
  final Map<String, List<EventoAlertaModel>> _eventos = {};
  final Map<String, UbicacionModel> _ubicaciones = {};
  int _seqEvento = 0;
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

  /// Eventos registrados para una alerta, en orden cronológico (para pruebas).
  List<EventoAlertaModel> eventosDe(String alertaId) =>
      List.unmodifiable(_eventos[alertaId] ?? const []);

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
    _alertas[alerta.id] = AlertaModel.fromMap(
        alerta.id, {...alerta.toMap(), 'createdAtServer': DateTime.now()});
    _notificar();
    await registrarEvento(
      alertaId: alerta.id,
      tipo: TipoEventoAlerta.creada,
      meta: {if (alerta.prioridad != null) 'prioridad': alerta.prioridad},
    );
  }

  @override
  Future<void> updateAlerta(String id, Map<String, dynamic> data) async {
    final actual = _alertas[id];
    if (actual == null) return;
    _alertas[id] = AlertaModel.fromMap(id, {...actual.toMap(), ...data});
    _notificar();
  }

    @override
  Future<void> agregarFotosAAlerta(String id, List<String> urls) async {
    final actual = _alertas[id];
    if (actual == null) return;
    await updateAlerta(id, {
      'fotos': [
        ...actual.fotos,
        ...urls.where((u) => !actual.fotos.contains(u)),
      ],
    });
  }

  @override
  Future<AlertaModel?> getAlertaById(String id) async => _alertas[id];

  @override
  Future<TomarAlertaResultado> tomarAlerta({
    required String alertaId,
    required String ambulanciaId,
  }) async {
    final alerta = _alertas[alertaId];
    if (alerta == null ||
        alerta.estado != AlertState.activa ||
        alerta.ambulanciaAsignada != null) {
      return TomarAlertaResultado.yaTomada;
    }

    final amb = _ambulancias[ambulanciaId];
    if (amb != null && amb.currentAlertaId != null) {
      return TomarAlertaResultado.ambulanciaOcupada;
    }

    await updateAlerta(alertaId, {
      'estado': AlertState.enProceso.name,
      'ambulanciaAsignada': ambulanciaId,
      'tomadaAt': DateTime.now(),
      if (amb?.currentConductorId != null)
        'conductorId': amb!.currentConductorId,
      if (amb?.currentParamedicoId != null)
        'paramedicoId': amb!.currentParamedicoId,
    });
    await updateAmbulancia(ambulanciaId, {'currentAlertaId': alertaId});
    await registrarEvento(
      alertaId: alertaId,
      tipo: TipoEventoAlerta.tomada,
      ambulanciaId: ambulanciaId,
      meta: {
        if (amb?.currentConductorId != null)
          'conductorId': amb!.currentConductorId,
        if (amb?.currentParamedicoId != null)
          'paramedicoId': amb!.currentParamedicoId,
      },
    );
    return TomarAlertaResultado.ok;
  }

  @override
  Future<void> liberarAlerta({
    required String alertaId,
    required String ambulanciaId,
  }) async {
    final alerta = _alertas[alertaId];
    // Solo revierte si sigue tomada por esta ambulancia; si ya fue
    // atendida no se toca.
    if (alerta != null &&
        alerta.estado == AlertState.enProceso &&
        alerta.ambulanciaAsignada == ambulanciaId) {
      await updateAlerta(alertaId, {
        'estado': AlertState.activa.name,
        'ambulanciaAsignada': null,
        'liberaciones': alerta.liberaciones + 1,
        'tomadaAt': null,
        'rutaIniciadaAt': null,
        'etaInicialSeg': null,
        'distanciaInicialM': null,
        'conductorId': null,
        'paramedicoId': null,
      });
      await registrarEvento(
        alertaId: alertaId,
        tipo: TipoEventoAlerta.liberada,
        ambulanciaId: ambulanciaId,
      );
    }
    await updateAmbulancia(ambulanciaId, {'currentAlertaId': null});
  }

  // ---------- Ubicación en vivo ----------
  @override
  Future<void> publicarUbicacion(
      String ambulanciaId, UbicacionModel ubicacion) async {
    _ubicaciones[ambulanciaId] = UbicacionModel.fromMap(
        {...ubicacion.toMap(), 'actualizadoAt': DateTime.now()},
        id: ambulanciaId);
    _notificar();
  }

  @override
  Stream<List<UbicacionModel>> streamUbicaciones() =>
      _observar(() => _ubicaciones.values.toList());

  // ---------- Instrumentación ----------
  @override
  Future<void> registrarEvento({
    required String alertaId,
    required TipoEventoAlerta tipo,
    String? ambulanciaId,
    Map<String, dynamic> meta = const {},
  }) async {
    (_eventos[alertaId] ??= []).add(EventoAlertaModel(
      id: 'evt-${_seqEvento++}',
      tipo: tipo,
      ts: DateTime.now(),
      ambulanciaId: ambulanciaId,
      meta: Map<String, dynamic>.from(meta),
    ));
  }

  @override
  Future<void> marcarHitoAlerta({
    required String alertaId,
    required HitoAlerta hito,
    String? ambulanciaId,
    Map<String, dynamic> campos = const {},
    Map<String, dynamic> meta = const {},
  }) async {
    await updateAlerta(alertaId, {hito.campo: DateTime.now(), ...campos});
    await registrarEvento(
      alertaId: alertaId,
      tipo: hito.evento,
      ambulanciaId: ambulanciaId,
      meta: meta,
    );
  }

  @override
  Future<void> registrarRecalculoRuta({
    required String alertaId,
    String? ambulanciaId,
    Map<String, dynamic> meta = const {},
  }) async {
    final actual = _alertas[alertaId];
    if (actual != null) {
      await updateAlerta(alertaId, {'recalculos': actual.recalculos + 1});
    }
    await registrarEvento(
      alertaId: alertaId,
      tipo: TipoEventoAlerta.recalculo,
      ambulanciaId: ambulanciaId,
      meta: meta,
    );
  }

  @override
  Future<void> cambiarEstadoOperativo(String ambulanciaId, String estado) =>
      updateAmbulancia(ambulanciaId, {
        'estadoOperativo': estado,
        'ultimoCambioEstadoAt': DateTime.now(),
      });

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
      'enTurno': true,
      'turnoIniciadoAt': DateTime.now(),
      'ultimoCambioEstadoAt': DateTime.now(),
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
      'enTurno': false,
      'turnoIniciadoAt': null,
      'ultimoCambioEstadoAt': DateTime.now(),
    });
    _ubicaciones.remove(ambulanciaId);
    _notificar();
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