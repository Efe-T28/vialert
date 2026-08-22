import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String id;
  final String nombre;
  final String apellido;
  final String cedula;
  final String telefono;
  final String email;
  final String rol;
  final DateTime createdAt;

  UsuarioModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.telefono,
    required this.email,
    this.rol = 'usuario',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'apellido': apellido,
        'cedula': cedula,
        'telefono': telefono,
        'email': email,
        'rol': rol,
        // Guarda como Timestamp si quieres, pero aquí lo dejamos como ISO
        'createdAt': createdAt.toIso8601String(),
      };

  factory UsuarioModel.fromMap(String id, Map<String, dynamic> m) {
    final created = m['createdAt'];

    DateTime parsedCreatedAt;

    if (created is Timestamp) {
      parsedCreatedAt = created.toDate(); // <-- CORRECCIÓN
    } else if (created is String) {
      parsedCreatedAt = DateTime.parse(created);
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return UsuarioModel(
      id: id,
      nombre: m['nombre'] ?? '',
      apellido: m['apellido'] ?? '',
      cedula: m['cedula'] ?? '',
      telefono: m['telefono'] ?? '',
      email: m['email'] ?? '',
      rol: m['rol'] ?? 'usuario',
      createdAt: parsedCreatedAt,
    );
  }
}
