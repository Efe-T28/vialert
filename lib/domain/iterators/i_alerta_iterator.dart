import '../../models/alerta_model.dart';

/// Iterator: recorre una colección de [AlertaModel] sin exponer si por
/// debajo está ordenada por fecha, por cercanía u otro criterio.
abstract class IAlertaIterator {
  bool hasNext();
  AlertaModel next();
}
