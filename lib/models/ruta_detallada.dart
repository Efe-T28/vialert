import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Un paso de navegación de la ruta (un tramo hasta el próximo giro).
class PasoRuta {
  final String instruccion; // texto plano, ej. "Dirígete hacia Calle 20"
  final String maniobra; // 'turn-right', 'turn-left', 'straight', '' si no hay
  final LatLng posicionFin;
  final int distanciaMetros;

  const PasoRuta({
    required this.instruccion,
    required this.maniobra,
    required this.posicionFin,
    required this.distanciaMetros,
  });
}

/// Ruta completa de Directions: polyline, duración/distancia reales y los
/// pasos de navegación. Reemplaza a los pares getRoute + getRouteSummary
/// cuando se necesita todo junto con una sola consulta.
class RutaDetallada {
  final List<LatLng> puntos;
  final int duracionSegundos;
  final int distanciaMetros;
  final String duracionTexto;
  final String distanciaTexto;
  final List<PasoRuta> pasos;

  const RutaDetallada({
    required this.puntos,
    required this.duracionSegundos,
    required this.distanciaMetros,
    required this.duracionTexto,
    required this.distanciaTexto,
    required this.pasos,
  });
}
