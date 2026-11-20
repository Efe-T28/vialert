// lib/controllers/ubicacion_publisher.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/ubicacion_model.dart';
import '../services/i_database_service.dart';
import '../services/i_location_service.dart';

/// Qué está haciendo la ambulancia ahora mismo. Lo entrega quien arma el
/// publicador (ver `main.dart`), para que esta clase no dependa de los
/// controladores de atención.
class ContextoUbicacion {
  /// Alerta que se está atendiendo, o `null` si está libre.
  final String? alertaId;

  /// 'habilitada' | 'enRuta' | 'enRutaHospital'.
  final String estadoOperativo;

  const ContextoUbicacion({this.alertaId, this.estadoOperativo = 'habilitada'});

  bool get enAtencion => alertaId != null;
}

/// Publica la posición de la ambulancia en `ubicaciones/{uid}`:
/// cada [intervaloAtencion] mientras atiende una alerta y cada [intervaloLibre]
/// cuando está de turno y libre. Fuera de turno no publica (se detiene).
///
/// Solo depende de [ILocationService] e [IDatabaseService]. Es "de mejor
/// esfuerzo": cualquier fallo queda en el log y nunca afecta la atención.
class UbicacionPublisher {
  UbicacionPublisher({
    required ILocationService locationService,
    required IDatabaseService db,
    required ContextoUbicacion Function() contexto,
    this.appVersion,
    this.intervaloAtencion = const Duration(seconds: 5),
    this.intervaloLibre = const Duration(seconds: 30),
    this.reintentoGps = const Duration(seconds: 30),
  })  : _location = locationService,
        _db = db,
        _contexto = contexto;

  final ILocationService _location;
  final IDatabaseService _db;
  final ContextoUbicacion Function() _contexto;
  final String? appVersion;
  final Duration intervaloAtencion;
  final Duration intervaloLibre;
  final Duration reintentoGps;

  String? _ambulanciaId;
  UbicacionModel? _ultima;
  DateTime? _ultimaPublicacion;
  StreamSubscription<UbicacionModel>? _sub;
  Timer? _latido;
  Timer? _reintento;
  bool _publicando = false;

  bool get activo => _ambulanciaId != null;

  /// Empieza a publicar para [ambulanciaId]. Es idempotente: si ya está
  /// activo con el mismo id no hace nada.
  void iniciar(String ambulanciaId) {
    if (_ambulanciaId == ambulanciaId) return;
    detener();
    _ambulanciaId = ambulanciaId;
    _suscribir();
    // El latido es la garantía: aunque el GPS no emita (unidad detenida) o el
    // sistema retrase los eventos, cada tick revisa si toca publicar.
    _latido = Timer.periodic(intervaloAtencion, (_) => _publicarSiToca());
    unawaited(_sembrar(ambulanciaId));
  }

  /// Deja de publicar. No borra el documento: eso lo hace el fin de turno
  /// (`liberarPersonalYResetAmbulancia`). Llamarlo ANTES de liberar el
  /// personal evita que una publicación tardía reviva el documento.
  void detener() {
    _sub?.cancel();
    _sub = null;
    _latido?.cancel();
    _latido = null;
    _reintento?.cancel();
    _reintento = null;
    _ambulanciaId = null;
    _ultima = null;
    _ultimaPublicacion = null;
  }

  /// Primera posición inmediata (y, de paso, dispara la petición de permiso
  /// de ubicación si aún no se concedió).
  Future<void> _sembrar(String id) async {
    try {
      final p = await _location.getCurrentLocation();
      if (_ambulanciaId != id || p == null) return;
      _ultima ??= UbicacionModel(lat: p.latitude, lng: p.longitude);
      _publicarSiToca();
    } catch (e) {
      debugPrint('[ubicacion] no se pudo obtener la posición inicial: $e');
    }
  }

  void _suscribir() {
    _sub?.cancel();
    _sub = null;
    final stream = _location.onPositionChanged(segundoPlano: true);
    if (stream == null) {
      _programarReintento();
      return;
    }
    _sub = stream.listen(
      (u) {
        _ultima = u;
        _publicarSiToca();
      },
      onError: (Object e) {
        debugPrint('[ubicacion] error del GPS: $e');
        _sub?.cancel();
        _sub = null;
        _programarReintento();
      },
      cancelOnError: true,
    );
  }

  void _programarReintento() {
    _reintento?.cancel();
    _reintento = Timer(reintentoGps, () {
      if (activo) _suscribir();
    });
  }

  void _publicarSiToca() {
    if (!activo || _ultima == null) return;
    final intervalo =
        _contexto().enAtencion ? intervaloAtencion : intervaloLibre;
    // Pequeña tolerancia: un tick que llega unos ms antes no debe saltarse
    // un ciclo entero.
    final tolerancia = Duration(milliseconds: intervaloAtencion.inMilliseconds ~/ 10);
    final ultima = _ultimaPublicacion;
    if (ultima == null ||
        DateTime.now().difference(ultima) + tolerancia >= intervalo) {
      unawaited(_publicar());
    }
  }

  Future<void> _publicar() async {
    final id = _ambulanciaId;
    final u = _ultima;
    if (id == null || u == null || _publicando) return;
    _publicando = true;
    _ultimaPublicacion = DateTime.now();
    try {
      final ctx = _contexto();
      final dato = u.conContexto(
        estadoOperativo: ctx.estadoOperativo,
        alertaId: ctx.alertaId,
        appVersion: appVersion,
      );
      // Sin red, Firestore deja la escritura en cola y el Future no termina;
      // el límite evita que una publicación pendiente bloquee las siguientes.
      await _db
          .publicarUbicacion(id, dato)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[ubicacion] no se pudo publicar: $e');
    } finally {
      _publicando = false;
    }
  }
}
