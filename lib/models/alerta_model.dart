// lib/models/alerta_model.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum AlertState { activa, enProceso, atendida }

class AlertaModel {
  final String id;
  final String type;
  final String description;
  final LatLng position;
  final DateTime createdAt;
  final String creadaPorUsuarioId; // nombre completo (se mantiene por compatibilidad)
  final String? creadaPorUid; // uid real; las alertas antiguas no lo tienen
  final AlertState estado;
  final String? ambulanciaAsignada;
  final List<String> fotos; // URLs de descarga (máx. 3)

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
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'description': description,
        'lat': position.latitude,
        'lng': position.longitude,
        'createdAt': createdAt.toIso8601String(),
        'creadaPorUsuarioId': creadaPorUsuarioId,
        'creadaPorUid': creadaPorUid,
        'estado': estado.name,
        'ambulanciaAsignada': ambulanciaAsignada,
        'fotos': fotos,
      };

  factory AlertaModel.fromMap(String id, Map<String, dynamic> m) {
    final lat = (m['lat'] as num).toDouble();
    final lng = (m['lng'] as num).toDouble();
    return AlertaModel(
      id: id,
      type: m['type'] ?? '',
      description: m['description'] ?? '',
      position: LatLng(lat, lng),
      createdAt: m['createdAt'] != null
          ? DateTime.parse(m['createdAt'])
          : DateTime.now(),
      creadaPorUsuarioId: m['creadaPorUsuarioId'] ?? '',
      creadaPorUid: m['creadaPorUid'] as String?,
      estado: AlertState.values
          .firstWhere((e) => e.name == (m['estado'] ?? 'activa')),
      ambulanciaAsignada: m['ambulanciaAsignada'],
      fotos: (m['fotos'] as List?)?.whereType<String>().toList() ?? const [],
    );
  }
}