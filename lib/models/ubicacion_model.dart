// lib/models/ubicacion_model.dart
class UbicacionModel {
  final double lat;
  final double lng;
  final DateTime timestamp;

  UbicacionModel({required this.lat, required this.lng, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp.toIso8601String(),
      };

  factory UbicacionModel.fromMap(Map<String, dynamic> m) {
    return UbicacionModel(
      lat: (m['lat'] as num).toDouble(),
      lng: (m['lng'] as num).toDouble(),
      timestamp: m['timestamp'] != null
          ? DateTime.parse(m['timestamp'])
          : DateTime.now(),
    );
  }
}
