import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/ubicacion_model.dart';

abstract class ILocationService {
  Future<LatLng?> getCurrentLocation();
  Stream<LatLng>? onLocationChanged();

  /// Igual que [onLocationChanged] pero con rumbo, velocidad y precisión.
  /// Con [segundoPlano] en `true` la posición sigue llegando con la pantalla
  /// bloqueada (en Android, mediante un servicio en primer plano con
  /// notificación fija). Lo usa el publicador de ubicación en vivo.
  Stream<UbicacionModel>? onPositionChanged({bool segundoPlano = false});
}
