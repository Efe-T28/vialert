import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'i_alerta_iterator.dart';

/// Aggregate: declara cómo obtener un [IAlertaIterator] a partir de una
/// colección de alertas, sin que el llamador sepa qué estructura concreta
/// hay por debajo.
abstract class IHistorialAlertas {
  IAlertaIterator porFecha({bool masRecientePrimero = true});
  IAlertaIterator porCercania(LatLng referencia);
}
