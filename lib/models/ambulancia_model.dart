// lib/models/ambulancia_model.dart
class AmbulanciaModel {
  final String id; // uid in Firebase Auth
  final String email;
  final String placa;
  final String codigoInterno;
  final String entidadId;
  final String estadoOperativo; // 'habilitada' | 'enRuta' | 'inactiva'
  final String? currentConductorId;
  final String? currentParamedicoId;
  final String? currentAlertaId;

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
      };

  factory AmbulanciaModel.fromMap(String id, Map<String, dynamic> m) {
    return AmbulanciaModel(
      id: id,
      email: m['email'] ?? '',
      placa: m['placa'] ?? '',
      codigoInterno: m['codigoInterno'] ?? '',
      entidadId: m['entidadId'] ?? '',
      estadoOperativo: m['estadoOperativo'] ?? 'habilitada',
      currentConductorId: m['currentConductorId'],
      currentParamedicoId: m['currentParamedicoId'],
      currentAlertaId: m['currentAlertaId'],
    );
  }
}
