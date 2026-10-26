import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import '../services/i_database_service.dart';
import '../services/i_storage_service.dart';
import '../models/alerta_model.dart';

/// Estado en memoria de la subida de fotos de una alerta.
class SubidaFotos {
  final String alertaId;
  int total;
  int subidas = 0;
  bool enCurso = false;

  /// Fotos que fallaron (índice -> bytes), guardadas para poder reintentar.
  final Map<int, Uint8List> fallidas = {};

  SubidaFotos(this.alertaId, {this.total = 0});
}

class AlertController extends ChangeNotifier {
  static const int maxFotos = 3;

  final IDatabaseService _fs;
  final IStorageService _storage;
  final List<AlertaModel> alerts = [];
  final _uuid = const Uuid();
  final Map<String, SubidaFotos> _subidas = {};

  AlertController(this._fs, this._storage) {
    _fs.streamAlertas().listen((list) {
      alerts
        ..clear()
        ..addAll(list);
      notifyListeners();
    });
  }

  /// Subidas en curso o con fotos fallidas (las completadas se eliminan).
  List<SubidaFotos> get subidasConAviso => _subidas.values.toList();

  /// Crea la alerta y devuelve su id. La alerta NUNCA espera a las fotos:
  /// se crea primero y las fotos se suben en segundo plano.
  Future<String> crearAlerta({
    required String type,
    required String description,
    required LatLng position,
    required String creadaPorUsuarioId,
    String? creadaPorUid,
    List<Uint8List> fotos = const [],
  }) async {
    final id = _uuid.v4();
    final alerta = AlertaModel(
      id: id,
      type: type,
      description: description,
      position: position,
      createdAt: DateTime.now(),
      creadaPorUsuarioId: creadaPorUsuarioId,
      creadaPorUid: creadaPorUid,
    );
    await _fs.crearAlerta(alerta);

    if (fotos.isNotEmpty) {
      final mapa = <int, Uint8List>{
        for (var i = 0; i < fotos.length && i < maxFotos; i++) i: fotos[i],
      };
      unawaited(_subirFotos(id, mapa));
    }
    return id;
  }

  Future<void> _subirFotos(
    String alertaId,
    Map<int, Uint8List> fotos, {
    bool esReintento = false,
  }) async {
    final estado = _subidas.putIfAbsent(alertaId, () => SubidaFotos(alertaId));
    if (estado.enCurso) return;

    estado.enCurso = true;
    if (!esReintento) {
      estado.total = fotos.length;
      estado.subidas = 0;
    }
    estado.fallidas.clear();
    notifyListeners();

    final urls = <int, String>{};
    await Future.wait(fotos.entries.map((e) async {
      try {
        urls[e.key] = await _storage.subirFotoAlerta(
          alertaId: alertaId,
          indice: e.key,
          bytes: e.value,
        );
        estado.subidas++;
      } catch (_) {
        estado.fallidas[e.key] = e.value;
      }
      notifyListeners();
    }));

    if (urls.isNotEmpty) {
      try {
        // Una sola actualización del documento con todas las URLs.
        await _fs.agregarFotosAAlerta(alertaId, urls.values.toList());
      } catch (_) {
        // Se subieron pero no se vincularon: se tratan como fallidas.
        for (final i in urls.keys) {
          estado.fallidas[i] = fotos[i]!;
          estado.subidas--;
        }
      }
    }

    estado.enCurso = false;
    if (estado.fallidas.isEmpty) _subidas.remove(alertaId);
    notifyListeners();
  }

  Future<void> reintentarFotos(String alertaId) async {
    final estado = _subidas[alertaId];
    if (estado == null || estado.enCurso || estado.fallidas.isEmpty) return;
    await _subirFotos(alertaId, Map.of(estado.fallidas), esReintento: true);
  }

  void descartarFotosFallidas(String alertaId) {
    final estado = _subidas[alertaId];
    if (estado == null || estado.enCurso) return;
    _subidas.remove(alertaId);
    notifyListeners();
  }

  Future<void> asignarAmbulanciaAAlerta(
      String alertaId, String ambulanciaId) async {
    await _fs.updateAlerta(alertaId, {
      'estado': AlertState.enProceso.name,
      'ambulanciaAsignada': ambulanciaId,
    });
  }

  Future<void> marcarComoAtendida(String alertaId) async {
    await _fs.updateAlerta(alertaId, {
      'estado': AlertState.atendida.name,
    });
  }

  List<AlertaModel> getAlertasByUsuario(String usuarioId) {
    return alerts.where((a) => a.creadaPorUsuarioId == usuarioId).toList();
  }

  List<AlertaModel> getAlertasAtendidasByAmbulancia(String ambulanciaId) {
    return alerts
        .where((a) =>
            a.ambulanciaAsignada == ambulanciaId &&
            a.estado == AlertState.atendida)
        .toList();
  }

  List<AlertaModel> getAlertasActivas() {
    return alerts.where((a) => a.estado == AlertState.activa).toList();
  }
}