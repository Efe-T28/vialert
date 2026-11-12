import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/alert_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/atencion_alerta_controller.dart';
import '../../domain/iterators/historial_alertas_collection.dart';
import '../../domain/iterators/i_alerta_iterator.dart';
import '../../models/alerta_model.dart';
import '../../services/i_location_service.dart';
import '../widgets/galeria_fotos_alerta.dart';
import 'ambulancia_detalle_alerta_atendida_screen.dart';

enum _CriterioOrden { fecha, cercania }

/// Lista de alertas de la ambulancia: pendientes por tomar (realtime),
/// la alerta tomada actualmente y el historial de atendidas.
class AmbulanciaAlertasScreen extends StatefulWidget {
  const AmbulanciaAlertasScreen({super.key, required this.onIrAlMapa});

  /// Cambia al tab del mapa (lo maneja AmbulanciaMapaHome).
  final VoidCallback onIrAlMapa;

  @override
  State<AmbulanciaAlertasScreen> createState() =>
      _AmbulanciaAlertasScreenState();
}

class _AmbulanciaAlertasScreenState extends State<AmbulanciaAlertasScreen> {
  _CriterioOrden _criterio = _CriterioOrden.fecha;
  LatLng? _ubicacionActual;
  bool _buscandoUbicacion = false;
  bool _procesando = false;

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _timeFormat = DateFormat('HH:mm');

  Future<void> _seleccionarCercania() async {
    setState(() {
      _criterio = _CriterioOrden.cercania;
      _buscandoUbicacion = _ubicacionActual == null;
    });
    if (_ubicacionActual != null) return;
    final ubicacion =
        await context.read<ILocationService>().getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _ubicacionActual = ubicacion;
      _buscandoUbicacion = false;
    });
  }

  List<AlertaModel> _ordenar(List<AlertaModel> atendidas) {
    final historial = HistorialAlertasCollection(atendidas);
    final IAlertaIterator it;
    if (_criterio == _CriterioOrden.cercania && _ubicacionActual != null) {
      it = historial.porCercania(_ubicacionActual!);
    } else {
      it = historial.porFecha();
    }
    final ordenadas = <AlertaModel>[];
    while (it.hasNext()) {
      ordenadas.add(it.next());
    }
    return ordenadas;
  }

  void _mostrarSnack(String mensaje, Color color, IconData icono) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icono, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _tomarAlerta(AlertaModel alerta) async {
    final auth = context.read<AuthController>();
    final atencion = context.read<AtencionAlertaController>();
    if (auth.uid == null || _procesando) return;

    setState(() => _procesando = true);
    final resultado = await atencion.tomarAlerta(alerta, auth.uid!);
    if (!mounted) return;
    setState(() => _procesando = false);

    switch (resultado) {
      case TomarAlertaResultado.ok:
        _mostrarSnack('Alerta tomada. Ahora está en "Mis alertas".',
            Colors.green, Icons.check_circle);
      case TomarAlertaResultado.yaTomada:
        _mostrarSnack('Ya fue tomada por otra ambulancia.', Colors.orange,
            Icons.warning_amber_rounded);
      case TomarAlertaResultado.ambulanciaOcupada:
        _mostrarSnack('Ya tienes una alerta tomada sin atender.',
            Colors.orange, Icons.warning_amber_rounded);
    }
  }

  Future<void> _soltarAlerta(AlertaModel alerta) async {
    final auth = context.read<AuthController>();
    final atencion = context.read<AtencionAlertaController>();
    if (auth.uid == null || _procesando) return;

    setState(() => _procesando = true);
    await atencion.soltarAlerta(alerta, auth.uid!);
    if (!mounted) return;
    setState(() => _procesando = false);
    _mostrarSnack(
        'Alerta liberada, vuelve a Pendientes.', Colors.blueGrey, Icons.undo);
  }

  Future<void> _atenderAlerta(AlertaModel alerta) async {
    final auth = context.read<AuthController>();
    final atencion = context.read<AtencionAlertaController>();
    if (auth.uid == null || _procesando) return;

    setState(() => _procesando = true);
    await atencion.iniciarAtencion(alerta, auth.uid!);
    if (!mounted) return;
    setState(() => _procesando = false);

    if (atencion.lastError != null) {
      _mostrarSnack('Error: ${atencion.lastError}', Colors.red, Icons.error);
      return;
    }
    widget.onIrAlMapa();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final uid = auth.uid ?? '';
    final alertController = context.watch<AlertController>();
    final atencion = context.watch<AtencionAlertaController>();

    final pendientes = alertController.getAlertasPendientes();
    final tomada = alertController.getAlertaTomadaPor(uid);
    final atendidas =
        _ordenar(alertController.getAlertasAtendidasByAmbulancia(uid));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alertas'),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.notifications_active),
                text: 'Pendientes (${pendientes.length})',
              ),
              Tab(
                icon: const Icon(Icons.history),
                text: 'Atendidas (${atendidas.length})',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (tomada != null) _cardTomada(tomada, atencion),
                if (tomada == null && pendientes.isEmpty)
                  _mensajeVacio('No hay alertas pendientes en este momento'),
                ...pendientes.map(_cardPendiente),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (atendidas.isEmpty)
                  _mensajeVacio('Las alertas que atiendas aparecerán aquí')
                else ...[
                  _selectorOrden(),
                  ...atendidas.map(_cardAtendida),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mensajeVacio(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          texto,
          style: TextStyle(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _selectorOrden() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Text('Ordenar por: '),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Fecha'),
            selected: _criterio == _CriterioOrden.fecha,
            onSelected: (_) => setState(() => _criterio = _CriterioOrden.fecha),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Cercanía'),
            selected: _criterio == _CriterioOrden.cercania,
            onSelected: (_) => _seleccionarCercania(),
          ),
          if (_buscandoUbicacion) ...[
            const SizedBox(width: 12),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filaFechaReportante(AlertaModel a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              _dateFormat.format(a.createdAt),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(width: 20),
            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              _timeFormat.format(a.createdAt),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.person, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Reportada por: ${a.creadaPorUsuarioId}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cardPendiente(AlertaModel a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.type,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.description,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            GaleriaFotosAlerta(
              fotos: a.fotos,
              altura: 72,
              mostrarTitulo: false,
              padding: const EdgeInsets.only(top: 12),
            ),
            const Divider(height: 24),
            _filaFechaReportante(a),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _procesando ? null : () => _tomarAlerta(a),
                icon: const Icon(Icons.pan_tool_alt),
                label: const Text('Tomar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardTomada(AlertaModel a, AtencionAlertaController atencion) {
    final enRuta = atencion.isEnRuta && atencion.selectedAlertaId == a.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    enRuta ? Icons.directions_car : Icons.pan_tool_alt,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enRuta ? 'En ruta' : 'Tomada',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      Text(
                        a.type,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.description,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            GaleriaFotosAlerta(
              fotos: a.fotos,
              altura: 72,
              mostrarTitulo: false,
              padding: const EdgeInsets.only(top: 12),
            ),
            const Divider(height: 24),
            _filaFechaReportante(a),
            const SizedBox(height: 12),
            if (enRuta)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onIrAlMapa,
                  icon: const Icon(Icons.map),
                  label: const Text('Continuar en el mapa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _procesando ? null : () => _soltarAlerta(a),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _procesando ? null : () => _atenderAlerta(a),
                      icon: const Icon(Icons.local_hospital),
                      label: const Text('Atender'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _cardAtendida(AlertaModel a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AmbulanciaDetalleAlertaAtendidaScreen(alerta: a),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_circle,
                        color: Colors.green, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.type,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.description,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
              const Divider(height: 24),
              _filaFechaReportante(a),
            ],
          ),
        ),
      ),
    );
  }
}
