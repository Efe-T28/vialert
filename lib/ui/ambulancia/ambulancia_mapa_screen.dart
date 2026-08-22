import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../controllers/alert_controller.dart';
import '../../controllers/map_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/ambulancia_controller.dart';
import '../../models/alerta_model.dart';

class AmbulanciaMapaScreen extends StatefulWidget {
  const AmbulanciaMapaScreen({super.key});

  @override
  State<AmbulanciaMapaScreen> createState() => _AmbulanciaMapaScreenState();
}

class _AmbulanciaMapaScreenState extends State<AmbulanciaMapaScreen> {
  late final MapController mapController;
  late final AlertController alertController;
  String? selectedAlertaId;
  AlertaModel? selectedAlerta;

  // ✅ Para el temporizador
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    mapController = context.read<MapController>();
    alertController = context.read<AlertController>();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController.setMapController(controller);
  }

  void _onAlertaTapped(AlertaModel alerta) {
    setState(() {
      selectedAlerta = alerta;
      selectedAlertaId = null;
      _remainingSeconds = 0;
    });

    mapController.moveCamera(alerta.position, zoom: 15);
  }

  // ✅ Atender alerta con simulación de tiempo
  Future<void> _atenderAlerta() async {
    if (selectedAlerta == null) return;

    final auth = context.read<AuthController>();
    final ambCtrl = context.read<AmbulanciaController>();

    if (auth.uid == null) return;

    setState(() => selectedAlertaId = 'loading');

    try {
      // Asignar ambulancia (marca como "enProceso")
      await alertController.asignarAmbulanciaAAlerta(
        selectedAlerta!.id,
        auth.uid!,
      );

      await ambCtrl.setEstado(auth.uid!, 'enRuta');

      // Generar ruta
      final myLocation = await mapController.getMyLocation();
      if (myLocation != null) {
        await mapController.createRoute(myLocation, selectedAlerta!.position);
      }

      if (!mounted) return;

      setState(() {
        selectedAlertaId = selectedAlerta!.id;
        _remainingSeconds = 30; // ✅ 30 segundos de simulación
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.directions_car, color: Colors.white),
              SizedBox(width: 12),
              Text('En camino hacia la alerta...'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      // ✅ INICIAR TEMPORIZADOR DE 30 SEGUNDOS
      _startCountdown();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        selectedAlerta = null;
        selectedAlertaId = null;
        _remainingSeconds = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ✅ Temporizador que cuenta hacia atrás
  void _startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });

      // ✅ Cuando llega a 0, marcar automáticamente como atendida
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _finalizarAtencion();
      }
    });
  }

  // ✅ Finalizar atención automáticamente
  Future<void> _finalizarAtencion() async {
    if (selectedAlertaId == null || selectedAlertaId == 'loading') return;

    final auth = context.read<AuthController>();
    final ambCtrl = context.read<AmbulanciaController>();

    await alertController.marcarComoAtendida(selectedAlertaId!);

    if (auth.uid != null) {
      await ambCtrl.setEstado(auth.uid!, 'habilitada');
    }

    mapController.clearRoute();

    if (!mounted) return;

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

    setState(() {
      selectedAlerta = null;
      selectedAlertaId = null;
      _remainingSeconds = 0;
    });
  }

  // ✅ Opción para finalizar manualmente
  Future<void> _finalizarManualmente() async {
    if (selectedAlertaId == null || selectedAlertaId == 'loading') return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar atención'),
        content: Text(
            '¿Deseas finalizar la atención antes de tiempo?\n\nTiempo restante: $_remainingSeconds segundos'),
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

    _countdownTimer?.cancel();
    await _finalizarAtencion();
  }

  void _cancelarSeleccion() {
    setState(() {
      selectedAlerta = null;
      selectedAlertaId = null;
      _remainingSeconds = 0;
    });
  }

  void _cancelarRuta() {
    _countdownTimer?.cancel();
    mapController.clearRoute();
    setState(() {
      selectedAlerta = null;
      selectedAlertaId = null;
      _remainingSeconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertas = context.watch<AlertController>().getAlertasActivas();
    final polylines = context.watch<MapController>().polylines;

    // ✅ Marcadores: alertas activas Y en proceso
    final Set<Marker> markers = {};

    for (var a in alertas) {
      // Mostrar todas las alertas ACTIVAS
      if (a.estado == AlertState.activa) {
        markers.add(Marker(
          markerId: MarkerId(a.id),
          position: a.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            selectedAlerta?.id == a.id
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueRed,
          ),
          onTap: () => _onAlertaTapped(a),
        ));
      }
      // ✅ Mostrar también la alerta EN PROCESO (durante los 30 segundos)
      else if (a.estado == AlertState.enProceso && a.id == selectedAlertaId) {
        markers.add(Marker(
          markerId: MarkerId(a.id),
          position: a.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Alertas'),
        actions: [
          if (selectedAlertaId != null &&
              selectedAlertaId != 'loading' &&
              _remainingSeconds > 0)
            IconButton(
              icon: const Icon(Icons.check_circle),
              tooltip: 'Finalizar atención',
              onPressed: _finalizarManualmente,
            ),
        ],
      ),
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

          // ✅ CARD: ALERTA SELECCIONADA (no en proceso)
          if (selectedAlerta != null && selectedAlertaId == null)
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
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedAlerta!.type,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  selectedAlerta!.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _cancelarSeleccion,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _cancelarSeleccion,
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _atenderAlerta,
                              icon: const Icon(Icons.local_hospital),
                              label: const Text('Atender'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
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

          // ✅ CARD: EN RUTA CON TEMPORIZADOR
          if (selectedAlertaId != null &&
              selectedAlertaId != 'loading' &&
              _remainingSeconds > 0)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.orange.shade100,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.directions_car,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'En ruta hacia la alerta',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sigue la línea azul en el mapa',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Cancelar',
                            onPressed: _cancelarRuta,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ✅ TEMPORIZADOR VISUAL
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'Tiempo estimado de llegada: $_remainingSeconds seg',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ✅ BARRA DE PROGRESO
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _remainingSeconds / 30,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.orange,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ✅ LOADING
          if (selectedAlertaId == 'loading')
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

          // ✅ NO HAY ALERTAS
          if (alertas.isEmpty && selectedAlertaId == null)
            const Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No hay alertas activas en este momento',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
