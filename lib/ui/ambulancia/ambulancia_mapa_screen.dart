import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/alert_controller.dart';
import '../../controllers/map_controller.dart';
import '../../controllers/atencion_alerta_controller.dart';
import '../../controllers/guia_voz.dart';
import '../../models/alerta_model.dart';
import '../../models/ruta_detallada.dart';
import '../../domain/flyweight/marcador_flyweight.dart';
import 'maniobra_icono.dart';

/// Mapa de la ambulancia: solo muestra la ruta y la ubicación de la
/// alerta en atención (más el hospital de destino). Las alertas se
/// toman desde la pestaña Alertas.
class AmbulanciaMapaScreen extends StatefulWidget {
  const AmbulanciaMapaScreen({super.key});

  @override
  State<AmbulanciaMapaScreen> createState() => _AmbulanciaMapaScreenState();
}

class _AmbulanciaMapaScreenState extends State<AmbulanciaMapaScreen> {
  late final MapController mapController;
  late final AtencionAlertaController atencionController;

  bool _estabaEnRuta = false;
  bool _pildoraExpandida = false;

  @override
  void initState() {
    super.initState();
    mapController = context.read<MapController>();
    atencionController = context.read<AtencionAlertaController>();
    _estabaEnRuta = atencionController.isEnRuta;
    atencionController.addListener(_onAtencionChanged);
  }

  @override
  void dispose() {
    atencionController.removeListener(_onAtencionChanged);
    super.dispose();
  }

  void _onAtencionChanged() {
    final enRuta = atencionController.isEnRuta;
    final termino = _estabaEnRuta &&
        !enRuta &&
        !atencionController.isLoading &&
        atencionController.lastError == null;
    _estabaEnRuta = enRuta;
    if (!termino || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('¡Alerta atendida exitosamente!')),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController.setMapController(controller);
  }

  Future<void> _finalizarManualmente() async {
    final remaining = atencionController.remainingSeconds;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar atención'),
        content: Text(
            '¿Deseas finalizar la atención antes de tiempo?\n\nTiempo restante: $remaining segundos'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Sí, finalizar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    await atencionController.finalizarManualmente();
  }

  Future<void> _cancelarRuta() async {
    // Evita que el listener interprete la cancelación como atención exitosa.
    _estabaEnRuta = false;
    await atencionController.cancelarRuta();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alerta liberada, vuelve a Pendientes.'),
        backgroundColor: Colors.blueGrey,
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _formatoRestante(int segundos) {
    if (segundos < 60) return '$segundos s';
    return '${(segundos / 60).ceil()} min';
  }

  String _horaLlegada(int segundosRestantes) =>
      DateFormat('h:mm a').format(
          DateTime.now().add(Duration(seconds: segundosRestantes)));

  /// Píldora de navegación: compacta muestra flecha + ETA; al tocarla se
  /// expande con la instrucción, distancia, progreso y salir de navegación.
  Widget _pildoraNavegacion(
      AtencionAlertaController atencion, MapController mapCtrl) {
    final colorAcento =
        atencion.isEnRutaHospital ? Colors.purpleAccent : Colors.orangeAccent;
    final PasoRuta? paso = mapCtrl.proximoPaso;
    final iconoPaso = iconoManiobra(paso?.maniobra ?? '');
    final ruta = mapCtrl.rutaActual;

    final cuerpo = _pildoraExpandida
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(iconoPaso, color: colorAcento, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Llegada: ${_horaLlegada(atencion.remainingSeconds)}'
                          ' · ${_formatoRestante(atencion.remainingSeconds)}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          paso?.instruccion ??
                              (atencion.isEnRutaHospital
                                  ? 'Sigue la ruta hacia ${atencion.hospitalDestino!.nombre}'
                                  : 'Sigue la ruta hacia la alerta'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (ruta != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${ruta.distanciaTexto} · ${ruta.duracionTexto} en total',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.expand_less, color: Colors.white54),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 1 -
                      atencion.remainingSeconds /
                          (atencion.duracionTotalSegundos <= 0
                              ? 1
                              : atencion.duracionTotalSegundos),
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(colorAcento),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!atencion.isEnRutaHospital)
                    IconButton(
                      onPressed: _cancelarRuta,
                      tooltip: 'Salir de la navegación',
                      icon: Icon(Icons.close,
                          color: Colors.lightBlue.shade200, size: 28),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white10,
                      ),
                    ),
                  IconButton(
                    onPressed: () => context.read<GuiaVoz>().alternar(),
                    tooltip: context.watch<GuiaVoz>().activada
                        ? 'Silenciar guía de voz'
                        : 'Activar guía de voz',
                    icon: Icon(
                      context.watch<GuiaVoz>().activada
                          ? Icons.volume_up
                          : Icons.volume_off,
                      color: Colors.white70,
                      size: 28,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white10,
                    ),
                  ),
                  IconButton(
                    onPressed: _finalizarManualmente,
                    tooltip: 'Finalizar atención',
                    icon: const Icon(Icons.check_circle,
                        color: Colors.lightGreenAccent, size: 28),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white10,
                    ),
                  ),
                ],
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconoPaso, color: colorAcento, size: 26),
              const SizedBox(width: 10),
              Text(
                '${_formatoRestante(atencion.remainingSeconds)} · '
                'Llegada: ${_horaLlegada(atencion.remainingSeconds)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.expand_more, color: Colors.white54, size: 20),
            ],
          );

    return GestureDetector(
      onTap: () => setState(() => _pildoraExpandida = !_pildoraExpandida),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // El mismo maxWidth en ambos estados: interpolar entre un ancho
        // finito y uno infinito lanza una aserción de Flutter.
        constraints: const BoxConstraints(maxWidth: 420),
        padding: _pildoraExpandida
            ? const EdgeInsets.all(16)
            : const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(_pildoraExpandida ? 20 : 28),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: cuerpo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertas = context.watch<AlertController>().alerts;
    final mapCtrl = context.watch<MapController>();
    final polylines = mapCtrl.polylines;
    final atencion = context.watch<AtencionAlertaController>();

    // Único marcador de alerta: la que se está atendiendo. Desaparece al
    // quedar atendida (confirmación/ruta de hospital).
    final Set<Marker> markers = {};
    if (atencion.isEnRuta && !atencion.isEnRutaHospital) {
      for (final a in alertas) {
        if (a.id == atencion.selectedAlertaId &&
            a.estado != AlertState.atendida) {
          markers.add(
            MarcadorFactory.porEstado(AlertState.enProceso).dibujar(
              id: a.id,
              posicion: a.position,
            ),
          );
          break;
        }
      }
    }

    if (atencion.hospitalDestino != null) {
      markers.add(
        MarcadorFactory.hospital().dibujar(
          id: 'hospital',
          posicion: atencion.hospitalDestino!.position,
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(10.4742, -73.2436),
              zoom: 13,
            ),
            markers: markers,
            polylines: polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer()),
            },
          ),

          if (atencion.isEnRuta && atencion.remainingSeconds > 0)
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Center(
                  child: _pildoraNavegacion(atencion, mapCtrl),
                ),
              ),
            ),

          if (atencion.esperandoConfirmacionHospital)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_hospital,
                              color: Colors.purple, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '¿Trasladar al hospital más cercano?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  atencion.hospitalPropuesto!.nombre,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  atencionController.rechazarTrasladoHospital(),
                              child: const Text('No, finalizar aquí'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () => atencionController
                                  .confirmarTrasladoHospital(),
                              icon: const Icon(Icons.local_hospital),
                              label: const Text('Sí, trasladar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // LOADING
          if (atencion.isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Generando ruta...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (!atencion.isEnRuta && !atencion.isLoading)
            const Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blueGrey),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No estás atendiendo ninguna alerta. Ve a la pestaña Alertas para tomar una.',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
