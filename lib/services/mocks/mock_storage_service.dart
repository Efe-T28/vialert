import 'dart:typed_data';
import '../i_storage_service.dart';

/// Almacenamiento simulado: no sube nada, devuelve una URL "mock://".
/// Permite forzar fallos para probar el reintento.
class MockStorageService implements IStorageService {
  final Duration demora;
  final Set<int> indicesQueFallan;
  bool fallarSiempre;

  MockStorageService({
    this.demora = const Duration(milliseconds: 800),
    Set<int>? indicesQueFallan,
    this.fallarSiempre = false,
  }) : indicesQueFallan = {...?indicesQueFallan};

  @override
  Future<String> subirFotoAlerta({
    required String alertaId,
    required int indice,
    required Uint8List bytes,
  }) async {
    await Future.delayed(demora);
    if (fallarSiempre || indicesQueFallan.contains(indice)) {
      throw Exception('Fallo simulado al subir la foto $indice');
    }
    return 'mock://alertas/$alertaId/$indice.jpg';
  }
}