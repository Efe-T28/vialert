import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import './i_storage_service.dart';

/// ADAPTER: adapta Firebase Storage (Adaptee) a IStorageService (Target).
class FirebaseStorageAdapter implements IStorageService {
  final FirebaseStorage? _inyectado;

  FirebaseStorageAdapter({FirebaseStorage? storage}) : _inyectado = storage;

  // Se resuelve de forma perezosa: no toca Firebase hasta la primera subida.
  FirebaseStorage get _storage => _inyectado ?? FirebaseStorage.instance;

  static const Duration _tiempoMaximo = Duration(seconds: 45);

  @override
  Future<String> subirFotoAlerta({
    required String alertaId,
    required int indice,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref('alertas/$alertaId/$indice.jpg');
    final tarea = ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    try {
      await tarea.timeout(_tiempoMaximo);
    } on TimeoutException {
      await tarea.cancel();
      rethrow;
    }
    return ref.getDownloadURL();
  }
}