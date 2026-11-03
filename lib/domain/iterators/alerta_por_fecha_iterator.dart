import '../../models/alerta_model.dart';
import 'i_alerta_iterator.dart';

/// ConcreteIterator: recorre las alertas ordenadas por [AlertaModel.createdAt].
class AlertaPorFechaIterator implements IAlertaIterator {
  final List<AlertaModel> _ordenadas;
  int _indice = 0;

  AlertaPorFechaIterator(List<AlertaModel> alertas, {bool descendente = true})
      : _ordenadas = List<AlertaModel>.of(alertas)
          ..sort((a, b) => descendente
              ? b.createdAt.compareTo(a.createdAt)
              : a.createdAt.compareTo(b.createdAt));

  @override
  bool hasNext() => _indice < _ordenadas.length;

  @override
  AlertaModel next() => _ordenadas[_indice++];
}
