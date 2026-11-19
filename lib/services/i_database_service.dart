import '../models/alerta_model.dart';
import '../models/ambulancia_model.dart';
import '../models/conductor_model.dart';
import '../models/evento_alerta_model.dart';
import '../models/hospital_model.dart';
import '../models/paramedico_model.dart';
import '../models/personal_model.dart';
import '../models/usuario_model.dart';

abstract class IDatabaseService {

  //Alertas
  Stream<List<AlertaModel>> streamAlertas();
  Future<void> crearAlerta(AlertaModel alerta);
  Future<void> updateAlerta(String id, Map<String, dynamic> data);
  Future<AlertaModel?> getAlertaById(String id);
  Future<void> agregarFotosAAlerta(String id, List<String> urls);

  /// Reserva transaccional de una alerta: solo una ambulancia puede ganarla.
  Future<TomarAlertaResultado> tomarAlerta({
    required String alertaId,
    required String ambulanciaId,
  });

  /// Revierte una alerta tomada (vuelve a activa) y limpia currentAlertaId.
  Future<void> liberarAlerta({
    required String alertaId,
    required String ambulanciaId,
  });


  // ---- Instrumentación (hora del servidor) ----
  // Los controladores nunca escriben marcas de tiempo por su cuenta: usan
  // estos métodos, y cada implementación decide de dónde sale la hora
  // (Firestore: servidor; mock: reloj local).

  /// Agrega un hecho a `alertas/{id}/eventos` (registro de solo agregar).
  Future<void> registrarEvento({
    required String alertaId,
    required TipoEventoAlerta tipo,
    String? ambulanciaId,
    Map<String, dynamic> meta = const {},
  });

  /// Marca un hito de tiempo en la alerta, escribe [campos] adicionales
  /// (hospital, ETA...) y registra su evento, todo en una sola escritura.
  Future<void> marcarHitoAlerta({
    required String alertaId,
    required HitoAlerta hito,
    String? ambulanciaId,
    Map<String, dynamic> campos = const {},
    Map<String, dynamic> meta = const {},
  });

  /// Suma un recálculo de ruta por desvío a la alerta y registra su evento.
  Future<void> registrarRecalculoRuta({
    required String alertaId,
    String? ambulanciaId,
    Map<String, dynamic> meta = const {},
  });

  /// Cambia `estadoOperativo` y sella `ultimoCambioEstadoAt`.
  Future<void> cambiarEstadoOperativo(String ambulanciaId, String estado);


  //Usuarios
  Future<UsuarioModel?> getUsuarioByUid(String uid);
  Future<void> createUsuarioDoc(String uid, UsuarioModel u);

  //Personal
  Stream<List<ConductorModel>> streamConductoresDisponibles();
  Stream<List<ParamedicoModel>> streamParamedicosDisponibles();
  Future<void> guardarPersonal(PersonalModel p);
  Future<ConductorModel?> getConductorById(String id);
  Future<ParamedicoModel?> getParamedicoById(String id);
  Future<void> updateConductor(String id, Map<String, dynamic> data);
  Future<void> updateParamedico(String id, Map<String, dynamic> data);

  //Ambulancias
  Stream<List<AmbulanciaModel>> streamAmbulancias();
  Future<AmbulanciaModel?> getAmbulanciaById(String id);
  Future<void> crearAmbulanciaDoc(AmbulanciaModel a);
  Future<void> updateAmbulancia(String id, Map<String, dynamic> data);


  Future<bool> asignarPersonalAAmbulancia({
    required String ambulanciaId,
    String? conductorId,
    String? paramedicoId,
  });

  Future<bool> liberarPersonalYResetAmbulancia(String ambulanciaId);

  //Hospitales
  Stream<List<HospitalModel>> streamHospitales();
  Future<void> crearHospital(HospitalModel h);
  Future<void> updateHospital(String id, Map<String, dynamic> data);
  Future<void> deleteHospital(String id);
}