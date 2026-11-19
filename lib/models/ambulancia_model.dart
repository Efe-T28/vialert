// lib/models/ambulancia_model.dart
import 'fecha_utils.dart';

class AmbulanciaModel {
  final String id; // uid in Firebase Auth

  final String email;
  final String placa;
  final String codigoInterno;
  final String entidadId;

  /// 'habilitada' | 'enRuta' | 'enRutaHospital' | 'inactiva'
  ///
  /// Ojo: 'enRuta' tiene hoy dos significados (el equipo inició turno, o va
  /// hacia una alerta). Para saber si la unidad está de turno usar [enTurno].
  final String estadoOperativo;
  final String? currentConductorId;
  final String? currentParamedicoId;
  final String? currentAlertaId;

  /// `true` mientras hay un equipo a bordo (turno iniciado). Las ambulancias
  /// anteriores a esta versión no lo guardan: se deduce de si hay conductor
  /// o paramédico asignado.
  final bool enTurno;
  final DateTime? turnoIniciadoAt;

  /// Hora del servidor del último cambio de [estadoOperativo].
  final DateTime? ultimoCambioEstadoAt;

  AmbulanciaModel({
    required this.id,
    required this.email,
    required this.placa,
    required this.codigoInterno,
    required this.entidadId,
    this.estadoOperativo = 'habilitada',
    this.currentConductorId,
    this.currentParamedicoId,
    this.currentAlertaId,
    this.enTurno = false,
    this.turnoIniciadoAt,
    this.ultimoCambioEstadoAt,
  });

  Map<String, dynamic> toMap() => {
        'email': email,
        'placa': placa,
        'codigoInterno': codigoInterno,
        'entidadId': entidadId,
        'estadoOperativo': estadoOperativo,
        'currentConductorId': currentConductorId,
        'currentParamedicoId': currentParamedicoId,
        'currentAlertaId': currentAlertaId,
        'enTurno': enTurno,
        if (turnoIniciadoAt != null) 'turnoIniciadoAt': turnoIniciadoAt,
        if (ultimoCambioEstadoAt != null)
          'ultimoCambioEstadoAt': ultimoCambioEstadoAt,
      };

  factory AmbulanciaModel.fromMap(String id, Map<String, dynamic> m) {
    final conductor = m['currentConductorId'];
    final paramedico = m['currentParamedicoId'];
    return AmbulanciaModel(
      id: id,
      email: m['email'] ?? '',
      placa: m['placa'] ?? '',
      codigoInterno: m['codigoInterno'] ?? '',
      entidadId: m['entidadId'] ?? '',
      estadoOperativo: m['estadoOperativo'] ?? 'habilitada',
      currentConductorId: conductor,
      currentParamedicoId: paramedico,
      currentAlertaId: m['currentAlertaId'],
      enTurno: m['enTurno'] as bool? ?? (conductor != null || paramedico != null),
      turnoIniciadoAt: aFecha(m['turnoIniciadoAt']),
      ultimoCambioEstadoAt: aFecha(m['ultimoCambioEstadoAt']),
    );
  }
}
