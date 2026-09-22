import '../models/alerta_model.dart';
import '../models/ambulancia_model.dart';
import '../models/conductor_model.dart';
import '../models/paramedico_model.dart';
import '../models/personal_model.dart';
import '../models/usuario_model.dart';

abstract class IDatabaseService {

  //Alertas
  Stream<List<AlertaModel>> streamAlertas();
  Future<void> crearAlerta(AlertaModel alerta);
  Future<void> updateAlerta(String id, Map<String, dynamic> data);
  Future<AlertaModel?> getAlertaById(String id);


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
}