// lib/models/fecha_utils.dart

/// Convierte a [DateTime] cualquier representación de fecha que pueda traer
/// un documento: `Timestamp` de Firestore, texto ISO-8601 o `DateTime`.
///
/// Se evita importar `cloud_firestore` a propósito: así los modelos siguen
/// desacoplados de Firebase y funcionan igual con el servicio simulado.
/// Devuelve `null` si el valor es nulo o no se puede interpretar (por ejemplo,
/// un `serverTimestamp` que todavía no fue confirmado por el servidor).
DateTime? aFecha(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v.toLocal();
  if (v is String) return DateTime.tryParse(v)?.toLocal();
  try {
    final d = (v as dynamic).toDate(); // Timestamp de Firestore
    if (d is DateTime) return d.toLocal();
  } catch (_) {}
  return null;
}
