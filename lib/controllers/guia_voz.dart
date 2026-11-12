import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../domain/geo_math.dart';
import '../models/ruta_detallada.dart';
import '../services/i_location_service.dart';
import '../services/i_tts_service.dart';
import 'atencion_alerta_controller.dart';
import 'map_controller.dart';

/// Guía de voz de navegación: anuncia el inicio de ruta, cada maniobra
/// ("gira a la derecha…"), el aviso anticipado antes del giro, los
/// recálculos y las llegadas, usando el TTS del dispositivo. La activa el
/// shell de la ambulancia en servicio; el botón de altavoz de la píldora
/// la silencia.
class GuiaVoz extends ChangeNotifier {
  final AtencionAlertaController _atencion;
  final MapController _mapa;
  final ILocationService _ubicacion;
  final ITtsService _tts;

  GuiaVoz(this._atencion, this._mapa, this._ubicacion, this._tts);

  /// A esta distancia del final del tramo se anuncia el giro que viene.
  static const double metrosAvisoAnticipado = 120;

  bool activada = true;
  bool _corriendo = false;

  bool _estabaEnRuta = false;
  bool _estabaEnRutaHospital = false;
  bool _esperabaHospital = false;
  RutaDetallada? _rutaVista;
  PasoRuta? _pasoVisto;
  PasoRuta? _pasoAnticipado;
  StreamSubscription<LatLng>? _posSub;

  Future<void> iniciar() async {
    if (_corriendo) return;
    _corriendo = true;
    await _tts.init();
    _estabaEnRuta = _atencion.isEnRuta;
    _estabaEnRutaHospital = _atencion.isEnRutaHospital;
    _esperabaHospital = _atencion.esperandoConfirmacionHospital;
    _rutaVista = _mapa.rutaActual;
    _pasoVisto = _mapa.proximoPaso;
    _atencion.addListener(_onAtencionCambio);
    _mapa.addListener(_onMapaCambio);
    _posSub = _ubicacion.onLocationChanged()?.listen(_onPosicion);
  }

  void detener() {
    if (!_corriendo) return;
    _corriendo = false;
    _atencion.removeListener(_onAtencionCambio);
    _mapa.removeListener(_onMapaCambio);
    _posSub?.cancel();
    _posSub = null;
    _tts.callar();
  }

  void alternar() {
    activada = !activada;
    if (!activada) _tts.callar();
    notifyListeners();
  }

  void _hablar(String texto) {
    if (!activada || texto.isEmpty) return;
    _tts.decir(texto);
  }

  void _onAtencionCambio() {
    final enRuta = _atencion.isEnRuta;
    final enHospital = _atencion.isEnRutaHospital;
    final esperando = _atencion.esperandoConfirmacionHospital;

    if (enRuta && !_estabaEnRuta) {
      final instruccion = _mapa.proximoPaso?.instruccion;
      _hablar(instruccion == null
          ? 'Iniciando ruta hacia la alerta.'
          : 'Iniciando ruta. $instruccion');
    }
    if (esperando && !_esperabaHospital) {
      _hablar('Has llegado al lugar del accidente.');
    }
    if (enHospital && !_estabaEnRutaHospital) {
      final nombre = _atencion.hospitalDestino?.nombre ?? 'más cercano';
      _hablar('Iniciando traslado al hospital $nombre.');
    }
    if (!enHospital &&
        _estabaEnRutaHospital &&
        _atencion.lastError == null) {
      _hablar('Has llegado al hospital.');
    }

    _estabaEnRuta = enRuta;
    _estabaEnRutaHospital = enHospital;
    _esperabaHospital = esperando;
  }

  void _onMapaCambio() {
    final ruta = _mapa.rutaActual;
    final paso = _mapa.proximoPaso;
    final cambioRuta = !identical(ruta, _rutaVista);
    final cambioPaso = !identical(paso, _pasoVisto);
    // Si la ruta cambia porque arranca el traslado al hospital, el aviso
    // lo da _onAtencionCambio ("Iniciando traslado..."), no un "recalculada".
    final transicionHospital =
        _atencion.isEnRutaHospital != _estabaEnRutaHospital;

    if (cambioRuta) {
      if (_atencion.isEnRuta &&
          !transicionHospital &&
          _rutaVista != null &&
          ruta != null) {
        _hablar('Ruta recalculada. ${paso?.instruccion ?? ''}');
      }
    } else if (cambioPaso && paso != null && _atencion.isEnRuta) {
      // Se completó un tramo: anunciar la instrucción vigente.
      _hablar(paso.instruccion);
    }

    if (cambioRuta || cambioPaso) _pasoAnticipado = null;
    _rutaVista = ruta;
    _pasoVisto = paso;
  }

  void _onPosicion(LatLng posicion) {
    if (!_atencion.isEnRuta) return;
    final ruta = _mapa.rutaActual;
    final paso = _mapa.proximoPaso;
    if (ruta == null || paso == null) return;
    if (identical(_pasoAnticipado, paso)) return;

    // El giro que viene es la instrucción del PASO SIGUIENTE.
    final idx = ruta.pasos.indexOf(paso);
    if (idx < 0 || idx + 1 >= ruta.pasos.length) return;

    if (distanciaMetros(posicion, paso.posicionFin) < metrosAvisoAnticipado) {
      _pasoAnticipado = paso;
      _hablar('En cien metros, ${ruta.pasos[idx + 1].instruccion}');
    }
  }

  @override
  void dispose() {
    detener();
    super.dispose();
  }
}
