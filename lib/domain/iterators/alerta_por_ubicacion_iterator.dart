import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/alerta_model.dart';
import '../geo_math.dart';
import 'i_alerta_iterator.dart';

/// ConcreteIterator: recorre las alertas ordenadas por cercanía a
/// [referencia] (la más próxima primero), usando [distanciaMetros].
class AlertaPorUbicacionIterator implements IAlertaIterator {
  final List<AlertaModel> _ordenadas;
  int _indice = 0;

  AlertaPorUbicacionIterator(List<AlertaModel> alertas, LatLng referencia)
      : _ordenadas = List<AlertaModel>.of(alertas)
          ..sort((a, b) => distanciaMetros(referencia, a.position)
              .compareTo(distanciaMetros(referencia, b.position)));

  @override
  bool hasNext() => _indice < _ordenadas.length;

  @override
  AlertaModel next() => _ordenadas[_indice++];
}
