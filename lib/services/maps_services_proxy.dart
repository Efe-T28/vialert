import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'i_maps_service.dart';

/// PROXY: envuelve un [IMapsService] real (p. ej. GoogleDirectionsAdapter)
/// y cachea en memoria las respuestas por un tiempo limitado, para evitar
/// repetir la misma consulta a Google Directions cuando se pide la misma
/// ruta varias veces seguidas (reintentos, atenciones repetidas, etc.).
///
/// La clave de caché redondea las coordenadas a 4 decimales (~11 m), así
/// que pequeñas variaciones de GPS reusan la misma entrada. Los fallos
/// (`null`) no se cachean a propósito: una caída de la API sigue
/// reintentándose en cada llamada.
class _Entrada<T> {
  final T valor;
  final DateTime creadoEn;

  _Entrada(this.valor) : creadoEn = DateTime.now();

  bool vencida(Duration tiempoDeVida) =>
      DateTime.now().difference(creadoEn) > tiempoDeVida;
}

class MapsServicesProxy implements IMapsService {
  final IMapsService _real;
  final Duration _tiempoDeVida;

  MapsServicesProxy(
    this._real, {
    Duration tiempoDeVida = const Duration(minutes: 10),
  }) : _tiempoDeVida = tiempoDeVida;

  final Map<String, _Entrada<List<LatLng>>> _cacheRutas = {};
  final Map<String, _Entrada<Map<String, dynamic>>> _cacheResumenes = {};

  String _clave(LatLng origen, LatLng destino) {
    String r(double v) => v.toStringAsFixed(4);
    return '${r(origen.latitude)},${r(origen.longitude)}'
        '->${r(destino.latitude)},${r(destino.longitude)}';
  }

  @override
  Future<List<LatLng>?> getRoute(LatLng origin, LatLng destination) async {
    final clave = _clave(origin, destination);
    final entrada = _cacheRutas[clave];
    if (entrada != null && !entrada.vencida(_tiempoDeVida)) {
      return entrada.valor;
    }

    final resultado = await _real.getRoute(origin, destination);
    if (resultado != null) {
      _cacheRutas[clave] = _Entrada(resultado);
    }
    return resultado;
  }

  @override
  Future<Map<String, dynamic>?> getRouteSummary(
      LatLng origin, LatLng destination) async {
    final clave = _clave(origin, destination);
    final entrada = _cacheResumenes[clave];
    if (entrada != null && !entrada.vencida(_tiempoDeVida)) {
      return entrada.valor;
    }

    final resultado = await _real.getRouteSummary(origin, destination);
    if (resultado != null) {
      _cacheResumenes[clave] = _Entrada(resultado);
    }
    return resultado;
  }
}
