import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/alerta_model.dart';
import 'i_marcador.dart';

/// ConcreteFlyweight: guarda el estado INTRÍNSECO (el icono), compartido.
class MarcadorFlyweight implements IMarcador {
  final BitmapDescriptor icono;

  const MarcadorFlyweight._(this.icono);

  @override
  Marker dibujar({
    required String id,
    required LatLng posicion,
    VoidCallback? onTap,
  }) {
    return Marker(
      markerId: MarkerId(id),
      position: posicion,
      icon: icono,
      onTap: onTap,
    );
  }
}

/// Flyweight Factory: una sola instancia por apariencia visual.
class MarcadorFactory {
  MarcadorFactory._();

  static final Map<String, IMarcador> _pool = {};

  static IMarcador _obtener(String clave, double hue) {
    return _pool.putIfAbsent(
      clave,
      () => MarcadorFlyweight._(BitmapDescriptor.defaultMarkerWithHue(hue)),
    );
  }

  /// [seleccionada] y enProceso comparten la apariencia naranja.
  static IMarcador porEstado(
    AlertState estado, {
    bool seleccionada = false,
  }) {
    if (seleccionada) return _obtener('naranja', BitmapDescriptor.hueOrange);

    switch (estado) {
      case AlertState.activa:
        return _obtener('rojo', BitmapDescriptor.hueRed);
      case AlertState.enProceso:
        return _obtener('naranja', BitmapDescriptor.hueOrange);
      case AlertState.atendida:
        return _obtener('verde', BitmapDescriptor.hueGreen);
    }
  }

  static IMarcador posicionElegida() =>
      _obtener('azul', BitmapDescriptor.hueAzure);

  /// Cantidad de flyweights creados (máximo 4).
  static int get totalCreados => _pool.length;
}