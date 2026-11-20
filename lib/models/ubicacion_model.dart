// lib/models/ubicacion_model.dart
import 'fecha_utils.dart';

/// Posición de una ambulancia. Se usa tanto para lo que entrega el GPS
/// (solo coordenadas, rumbo, velocidad y precisión) como para lo que se
/// publica en `ubicaciones/{ambulanciaId}` (con el contexto operativo).
class UbicacionModel {
  /// Id del documento (= uid de la ambulancia). Solo se rellena al leer.
  final String? ambulanciaId;
  final double lat;
  final double lng;

  /// Grados 0-360, o `null` si el GPS no lo conoce.
  final double? rumbo;
  final double? velocidadKmh;

  /// Radio de error del GPS en metros.
  final double? precisionM;

  /// 'habilitada' (de turno y libre) | 'enRuta' (hacia una alerta) |
  /// 'enRutaHospital'. Se deduce de la atención en curso, así que aquí
  /// 'enRuta' NO se confunde con "inició turno".
  final String? estadoOperativo;
  final String? alertaId;
  final String? appVersion;

  /// Hora de la medición. En Firestore se reemplaza por la hora del servidor
  /// (`actualizadoAt`), que es la que sirve de latido.
  final DateTime timestamp;

  UbicacionModel({
    this.ambulanciaId,
    required this.lat,
    required this.lng,
    this.rumbo,
    this.velocidadKmh,
    this.precisionM,
    this.estadoOperativo,
    this.alertaId,
    this.appVersion,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Misma medición con el contexto operativo que añade el publicador.
  UbicacionModel conContexto({
    required String? estadoOperativo,
    required String? alertaId,
    required String? appVersion,
  }) =>
      UbicacionModel(
        ambulanciaId: ambulanciaId,
        lat: lat,
        lng: lng,
        rumbo: rumbo,
        velocidadKmh: velocidadKmh,
        precisionM: precisionM,
        estadoOperativo: estadoOperativo,
        alertaId: alertaId,
        appVersion: appVersion,
        timestamp: timestamp,
      );

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        if (rumbo != null) 'rumbo': rumbo,
        if (velocidadKmh != null) 'velocidadKmh': velocidadKmh,
        if (precisionM != null) 'precisionM': precisionM,
        if (estadoOperativo != null) 'estadoOperativo': estadoOperativo,
        // Explícito aunque sea nulo: indica "sin alerta asignada".
        'alertaId': alertaId,
        if (appVersion != null) 'appVersion': appVersion,
        'actualizadoAt': timestamp,
      };

  factory UbicacionModel.fromMap(Map<String, dynamic> m, {String? id}) {
    return UbicacionModel(
      ambulanciaId: id,
      lat: (m['lat'] as num).toDouble(),
      lng: (m['lng'] as num).toDouble(),
      rumbo: (m['rumbo'] as num?)?.toDouble(),
      velocidadKmh: (m['velocidadKmh'] as num?)?.toDouble(),
      precisionM: (m['precisionM'] as num?)?.toDouble(),
      estadoOperativo: m['estadoOperativo'] as String?,
      alertaId: m['alertaId'] as String?,
      appVersion: m['appVersion'] as String?,
      timestamp: aFecha(m['actualizadoAt'] ?? m['timestamp']) ?? DateTime.now(),
    );
  }
}
