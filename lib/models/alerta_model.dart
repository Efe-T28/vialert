// lib/models/alerta_model.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'fecha_utils.dart';

enum AlertState { activa, enProceso, atendida }

/// Resultado de intentar tomar (reservar) una alerta de forma transaccional.
enum TomarAlertaResultado { ok, yaTomada, ambulanciaOcupada }

class AlertaModel {
  final String id;
  final String type;
  final String description;
  final LatLng position;

  /// Hora del teléfono que creó la alerta (texto ISO). Se conserva por
  /// compatibilidad; para medir tiempos usar [createdAtServer].
  final DateTime createdAt;
  final String creadaPorUsuarioId; // nombre completo (se mantiene por compatibilidad)
  final String? creadaPorUid; // uid real; las alertas antiguas no lo tienen
  final AlertState estado;
  final String? ambulanciaAsignada;
  final List<String> fotos; // URLs de descarga (máx. 3)

  // ---- Instrumentación para el panel web ----
  // Todos opcionales: una alerta anterior a esta versión simplemente no los
  // trae, y el panel la trata como "sin dato" (no como cero).

  /// Hora del servidor al crear la alerta. Base confiable de todos los tiempos.
  final DateTime? createdAtServer;

  /// 'critica' | 'alta' | 'media' | 'baja'. La asigna la Fase 2 (selector).
  final String? prioridad;

  final DateTime? tomadaAt;
  final DateTime? rutaIniciadaAt;
  final DateTime? llegadaAt;
  final DateTime? atendidaAt;
  final DateTime? trasladoIniciadoAt;
  final DateTime? trasladoFinalizadoAt;

  final String? hospitalDestinoId;
  final String? hospitalDestinoNombre;

  /// Personal a bordo al tomar la alerta (se copia porque la ambulancia los
  /// libera al terminar).
  final String? conductorId;
  final String? paramedicoId;

  final int? etaInicialSeg;
  final int? distanciaInicialM;

  /// Recálculos de ruta por desvío (acumulado, aunque la alerta se libere).
  final int recalculos;

  /// Veces que la alerta volvió a la cola tras ser tomada.
  final int liberaciones;

  /// `true` si se creó o cerró con datos simulados (mocks o ETA de respaldo).
  /// El panel debe excluirlas de los KPI. Ausente = falso.
  final bool simulada;

  AlertaModel({
    required this.id,
    required this.type,
    required this.description,
    required this.position,
    required this.createdAt,
    required this.creadaPorUsuarioId,
    this.creadaPorUid,
    this.estado = AlertState.activa,
    this.ambulanciaAsignada,
    this.fotos = const [],
    this.createdAtServer,
    this.prioridad,
    this.tomadaAt,
    this.rutaIniciadaAt,
    this.llegadaAt,
    this.atendidaAt,
    this.trasladoIniciadoAt,
    this.trasladoFinalizadoAt,
    this.hospitalDestinoId,
    this.hospitalDestinoNombre,
    this.conductorId,
    this.paramedicoId,
    this.etaInicialSeg,
    this.distanciaInicialM,
    this.recalculos = 0,
    this.liberaciones = 0,
    this.simulada = false,
  });

  /// Los campos nuevos solo se incluyen cuando tienen valor, de modo que una
  /// alerta recién creada produce el mismo mapa que antes (más lo que se
  /// haya indicado explícitamente).
  Map<String, dynamic> toMap() => {
        'type': type,
        'description': description,
        'lat': position.latitude,
        'lng': position.longitude,
        // En UTC (con 'Z') para que se interprete igual en cualquier zona horaria.
        'createdAt': createdAt.toUtc().toIso8601String(),
        'creadaPorUsuarioId': creadaPorUsuarioId,
        'creadaPorUid': creadaPorUid,
        'estado': estado.name,
        'ambulanciaAsignada': ambulanciaAsignada,
        'fotos': fotos,
        if (createdAtServer != null) 'createdAtServer': createdAtServer,
        if (prioridad != null) 'prioridad': prioridad,
        if (tomadaAt != null) 'tomadaAt': tomadaAt,
        if (rutaIniciadaAt != null) 'rutaIniciadaAt': rutaIniciadaAt,
        if (llegadaAt != null) 'llegadaAt': llegadaAt,
        if (atendidaAt != null) 'atendidaAt': atendidaAt,
        if (trasladoIniciadoAt != null)
          'trasladoIniciadoAt': trasladoIniciadoAt,
        if (trasladoFinalizadoAt != null)
          'trasladoFinalizadoAt': trasladoFinalizadoAt,
        if (hospitalDestinoId != null) 'hospitalDestinoId': hospitalDestinoId,
        if (hospitalDestinoNombre != null)
          'hospitalDestinoNombre': hospitalDestinoNombre,
        if (conductorId != null) 'conductorId': conductorId,
        if (paramedicoId != null) 'paramedicoId': paramedicoId,
        if (etaInicialSeg != null) 'etaInicialSeg': etaInicialSeg,
        if (distanciaInicialM != null) 'distanciaInicialM': distanciaInicialM,
        if (recalculos > 0) 'recalculos': recalculos,
        if (liberaciones > 0) 'liberaciones': liberaciones,
        if (simulada) 'simulada': true,
      };

  factory AlertaModel.fromMap(String id, Map<String, dynamic> m) {
    final lat = (m['lat'] as num).toDouble();
    final lng = (m['lng'] as num).toDouble();
    return AlertaModel(
      id: id,
      type: m['type'] ?? '',
      description: m['description'] ?? '',
      position: LatLng(lat, lng),
      createdAt: aFecha(m['createdAt']) ?? DateTime.now(),
      creadaPorUsuarioId: m['creadaPorUsuarioId'] ?? '',
      creadaPorUid: m['creadaPorUid'] as String?,
      estado: AlertState.values.firstWhere(
          (e) => e.name == (m['estado'] ?? 'activa'),
          orElse: () => AlertState.activa),
      ambulanciaAsignada: m['ambulanciaAsignada'],
      fotos: (m['fotos'] as List?)?.whereType<String>().toList() ?? const [],
      createdAtServer: aFecha(m['createdAtServer']),
      prioridad: m['prioridad'] as String?,
      tomadaAt: aFecha(m['tomadaAt']),
      rutaIniciadaAt: aFecha(m['rutaIniciadaAt']),
      llegadaAt: aFecha(m['llegadaAt']),
      atendidaAt: aFecha(m['atendidaAt']),
      trasladoIniciadoAt: aFecha(m['trasladoIniciadoAt']),
      trasladoFinalizadoAt: aFecha(m['trasladoFinalizadoAt']),
      hospitalDestinoId: m['hospitalDestinoId'] as String?,
      hospitalDestinoNombre: m['hospitalDestinoNombre'] as String?,
      conductorId: m['conductorId'] as String?,
      paramedicoId: m['paramedicoId'] as String?,
      etaInicialSeg: (m['etaInicialSeg'] as num?)?.toInt(),
      distanciaInicialM: (m['distanciaInicialM'] as num?)?.toInt(),
      recalculos: (m['recalculos'] as num?)?.toInt() ?? 0,
      liberaciones: (m['liberaciones'] as num?)?.toInt() ?? 0,
      simulada: m['simulada'] == true,
    );
  }
}
