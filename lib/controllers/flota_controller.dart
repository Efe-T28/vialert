import 'package:flutter/foundation.dart';
import '../domain/builders/ambulancia_builder.dart';
import '../domain/builders/ambulancia_director.dart';
import '../domain/plantillas_flota.dart';
import '../services/i_auth_service.dart';

/// Datos propios de cada unidad de la flota.
class FilaFlota {
  final String placa;
  final String codigoInterno;
  final String email;
  final String password;

  const FilaFlota({
    required this.placa,
    required this.codigoInterno,
    required this.email,
    required this.password,
  });
}

/// Resultado de procesar una fila: error == null significa creada.
class ResultadoFila {
  final FilaFlota fila;
  final String? error;

  const ResultadoFila(this.fila, {this.error});

  bool get exito => error == null;
}

class FlotaController extends ChangeNotifier {
  final IAuthService _auth;
  final PlantillasFlota _plantillas;

  FlotaController(this._auth, {PlantillasFlota? plantillas})
      : _plantillas = plantillas ?? PlantillasFlota();

  bool creando = false;
  int procesadas = 0;
  int total = 0;
  List<ResultadoFila> resultados = const [];

  List<String> get entidadesConPlantilla => _plantillas.entidades;

  /// Define (o reemplaza) la plantilla de una entidad.
  /// Devuelve un mensaje de error, o null si todo salió bien.
  String? definirPlantilla(
    String entidadId, {
    String estadoOperativo = 'habilitada',
  }) {
    if (entidadId.trim().isEmpty) return 'La entidad no puede estar vacía';

    final base = AmbulanciaBuilder();
    AmbulanciaDirector(base).construirPlantilla(
      entidadId: entidadId,
      estadoOperativo: estadoOperativo,
    );
    _plantillas.registrar(entidadId, base);
    notifyListeners();
    return null;
  }

  /// Se llama al abrir la pantalla. No notifica: aún no se ha construido.
  void limpiarResultados() {
    if (creando) return;
    resultados = const [];
  }

  /// Crea una ambulancia por fila, en secuencia. Un error en una fila no
  /// detiene las demás; el resultado de cada una queda en la lista devuelta.
  Future<List<ResultadoFila>> crearFlota(
    String entidadId,
    List<FilaFlota> filas,
  ) async {
    if (creando) return const [];

    creando = true;
    procesadas = 0;
    total = filas.length;
    resultados = const [];
    notifyListeners();

    final salida = <ResultadoFila>[];
    for (final fila in filas) {
      try {
        final datos = _plantillas.nueva(entidadId); // Prototype: clon
        AmbulanciaDirector(datos).completarUnidad(
          placa: fila.placa,
          codigoInterno: fila.codigoInterno,
        );
        await _auth.registerAmbulancia(
          email: fila.email,
          password: fila.password,
          datos: datos,
        );
        salida.add(ResultadoFila(fila));
      } catch (e) {
        salida.add(ResultadoFila(fila, error: e.toString()));
      }
      procesadas++;
      notifyListeners();
    }

    resultados = salida;
    creando = false;
    notifyListeners();
    return salida;
  }
}