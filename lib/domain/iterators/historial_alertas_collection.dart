import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/alerta_model.dart';
import 'alerta_por_fecha_iterator.dart';
import 'alerta_por_ubicacion_iterator.dart';
import 'i_alerta_iterator.dart';
import 'i_historial_alertas.dart';

/// ConcreteAggregate: envuelve la lista de alertas atendidas y decide, bajo
/// pedido, qué [IAlertaIterator] concreto entregar. El llamador nunca
/// recorre la `List<AlertaModel>` directamente.
class HistorialAlertasCollection implements IHistorialAlertas {
  final List<AlertaModel> _alertas;

  HistorialAlertasCollection(this._alertas);

  @override
  IAlertaIterator porFecha({bool masRecientePrimero = true}) =>
      AlertaPorFechaIterator(_alertas, descendente: masRecientePrimero);

  @override
  IAlertaIterator porCercania(LatLng referencia) =>
      AlertaPorUbicacionIterator(_alertas, referencia);
}
