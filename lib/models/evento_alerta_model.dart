// lib/models/evento_alerta_model.dart
import 'fecha_utils.dart';

/// Tipos de hecho que se registran en `alertas/{id}/eventos`.
/// [valor] es el texto que se guarda en Firestore (no cambiarlo: lo leerá
/// el panel web).
enum TipoEventoAlerta {
  creada('creada'),
  tomada('tomada'),
  liberada('liberada'),
  rutaIniciada('ruta_iniciada'),
  recalculo('recalculo'),
  llegada('llegada'),
  atendida('atendida'),
  trasladoPropuesto('traslado_propuesto'),
  trasladoIniciado('traslado_iniciado'),
  trasladoRechazado('traslado_rechazado'),
  trasladoFinalizado('traslado_finalizado');

  final String valor;
  const TipoEventoAlerta(this.valor);

  static TipoEventoAlerta? desdeValor(String? v) {
    for (final t in TipoEventoAlerta.values) {
      if (t.valor == v) return t;
    }
    return null;
  }
}

/// Hitos con marca de tiempo guardada como campo de la alerta. Cada hito
/// escribe además su evento correspondiente.
enum HitoAlerta {
  rutaIniciada('rutaIniciadaAt', TipoEventoAlerta.rutaIniciada),
  llegada('llegadaAt', TipoEventoAlerta.llegada),
  atendida('atendidaAt', TipoEventoAlerta.atendida),
  trasladoIniciado('trasladoIniciadoAt', TipoEventoAlerta.trasladoIniciado),
  trasladoFinalizado(
      'trasladoFinalizadoAt', TipoEventoAlerta.trasladoFinalizado);

  /// Nombre del campo en el documento de la alerta.
  final String campo;
  final TipoEventoAlerta evento;
  const HitoAlerta(this.campo, this.evento);
}

/// Un hecho puntual del ciclo de vida de una alerta (registro de solo agregar).
class EventoAlertaModel {
  final String id;
  final TipoEventoAlerta tipo;

  /// Hora del servidor. Puede ser `null` mientras el servidor no confirma
  /// la escritura.
  final DateTime? ts;
  final String? ambulanciaId;
  final Map<String, dynamic> meta;

  EventoAlertaModel({
    required this.id,
    required this.tipo,
    this.ts,
    this.ambulanciaId,
    this.meta = const {},
  });

  Map<String, dynamic> toMap() => {
        'tipo': tipo.valor,
        'ts': ts,
        'ambulanciaId': ambulanciaId,
        'meta': meta,
      };

  /// Devuelve `null` si el tipo no se reconoce (p. ej. un tipo agregado por
  /// una versión más nueva de la app).
  static EventoAlertaModel? fromMap(String id, Map<String, dynamic> m) {
    final tipo = TipoEventoAlerta.desdeValor(m['tipo'] as String?);
    if (tipo == null) return null;
    return EventoAlertaModel(
      id: id,
      tipo: tipo,
      ts: aFecha(m['ts']),
      ambulanciaId: m['ambulanciaId'] as String?,
      meta: (m['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
