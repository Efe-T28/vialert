  // lib/models/paramedico_model.dart
  class ParamedicoModel {
    final String id;
    final String nombre;
    final String apellido;
    final String cedula;
    final String telefono;
    final String entidadId;
    final String estado; // 'disponible' | 'ocupado'
    final String? ambulanciaId;

    ParamedicoModel({
      required this.id,
      required this.nombre,
      required this.apellido,
      required this.cedula,
      required this.telefono,
      required this.entidadId,
      this.estado = 'disponible',
      this.ambulanciaId,
    });

    Map<String, dynamic> toMap() => {
          'nombre': nombre,
          'apellido': apellido,
          'cedula': cedula,
          'telefono': telefono,
          'entidadId': entidadId,
          'estado': estado,
          'ambulanciaId': ambulanciaId,
        };

    factory ParamedicoModel.fromMap(String id, Map<String, dynamic> m) {
      return ParamedicoModel(
        id: id,
        nombre: m['nombre'] ?? '',
        apellido: m['apellido'] ?? '',
        cedula: m['cedula'] ?? '',
        telefono: m['telefono'] ?? '',
        entidadId: m['entidadId'] ?? '',
        estado: m['estado'] ?? 'disponible',
        ambulanciaId: m['ambulanciaId'],
      );
    }
  }
