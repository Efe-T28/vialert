import 'dart:typed_data';

abstract class IStorageService {
  /// Sube una foto de una alerta y devuelve su URL de descarga.
  /// [indice] (0..2) define el nombre del archivo: alertas/{alertaId}/{indice}.jpg
  Future<String> subirFotoAlerta({
    required String alertaId,
    required int indice,
    required Uint8List bytes,
  });
}