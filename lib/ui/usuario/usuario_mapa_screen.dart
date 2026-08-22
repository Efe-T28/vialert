import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../controllers/alert_controller.dart';
import '../../controllers/map_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/alerta_model.dart';

class UsuarioMapaScreen extends StatefulWidget {
  const UsuarioMapaScreen({super.key});

  @override
  State<UsuarioMapaScreen> createState() => _UsuarioMapaScreenState();
}

class _UsuarioMapaScreenState extends State<UsuarioMapaScreen> {
  late final MapController mapController;
  late final AlertController alertController;
  AlertaModel? _selectedAlerta; // ✅ Para mostrar info de alerta

  @override
  void initState() {
    super.initState();
    mapController = context.read<MapController>();
    alertController = context.read<AlertController>();
    _initLocation();
  }

  Future<void> _initLocation() async {
    // Solicita el permiso de ubicación y centra el mapa si se concede.
    final pos = await mapController.getMyLocation();
    if (pos != null) {
      mapController.moveCamera(pos, zoom: 15);
    }
  }

  Future<void> _reportarEnMiUbicacion() async {
    final pos = await mapController.getMyLocation();
    if (pos == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No se pudo obtener tu ubicación. Verifica que el GPS esté activado y el permiso concedido.')),
      );
      return;
    }
    mapController.moveCamera(pos, zoom: 17);
    await _crearAlertaEnPosicion(pos);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController.setMapController(controller);
  }

  Future<void> _crearAlertaEnPosicion(LatLng pos) async {
    final desc = await _showDescriptionDialog();
    if (desc == null) {
      return;
    }

    final auth = context.read<AuthController>();

    final nombreUsuario = auth.usuario != null
        ? '${auth.usuario!.nombre} ${auth.usuario!.apellido}'
        : 'Usuario Anónimo';

    await alertController.crearAlerta(
      type: 'Accidente',
      description: desc,
      position: pos,
      creadaPorUsuarioId: nombreUsuario,
    );

    mapController.setLastTapped(null);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alerta creada correctamente')),
    );
  }

  Future<String?> _showDescriptionDialog() {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reportar Accidente'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: 'Descripción (opcional)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              c.text.trim().isEmpty ? 'Sin descripción' : c.text.trim(),
            ),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  // ✅ Cuando se toca un marcador de alerta
  void _onAlertaMarkerTapped(AlertaModel alerta) {
    setState(() {
      _selectedAlerta = alerta;
    });
    mapController.moveCamera(alerta.position, zoom: 17);
  }

  // ✅ Obtener color según estado
  Color _getEstadoColor(AlertState estado) {
    switch (estado) {
      case AlertState.activa:
        return Colors.orange;
      case AlertState.enProceso:
        return Colors.blue;
      case AlertState.atendida:
        return Colors.green;
    }
  }

  // ✅ Obtener icono según estado
  IconData _getEstadoIcon(AlertState estado) {
    switch (estado) {
      case AlertState.activa:
        return Icons.warning_amber_rounded;
      case AlertState.enProceso:
        return Icons.local_shipping;
      case AlertState.atendida:
        return Icons.check_circle;
    }
  }

  // ✅ Obtener texto según estado
  String _getEstadoTexto(AlertState estado) {
    switch (estado) {
      case AlertState.activa:
        return 'Esperando atención';
      case AlertState.enProceso:
        return 'Ambulancia en camino';
      case AlertState.atendida:
        return 'Atendida exitosamente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();

    final nombreUsuario = auth.usuario != null
        ? '${auth.usuario!.nombre} ${auth.usuario!.apellido}'
        : '';

    final alerts = context.watch<AlertController>().alerts;
    final lastTapped = context.watch<MapController>().lastTappedPosition;

    // ✅ Marcadores de alertas del usuario
    final Set<Marker> markers = alerts
        .where((a) => a.creadaPorUsuarioId == nombreUsuario)
        .map((a) => Marker(
              markerId: MarkerId(a.id),
              position: a.position,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                a.estado == AlertState.activa
                    ? BitmapDescriptor.hueRed
                    : a.estado == AlertState.enProceso
                        ? BitmapDescriptor.hueOrange
                        : BitmapDescriptor.hueGreen,
              ),
              onTap: () => _onAlertaMarkerTapped(a), // ✅ Tap personalizado
            ))
        .toSet();

    // Marcador de posición seleccionada para crear alerta
    if (lastTapped != null && _selectedAlerta == null) {
      markers.add(Marker(
        markerId: const MarkerId('selected'),
        position: lastTapped,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
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
            myLocationEnabled: true,
            onTap: (pos) {
              // ✅ Limpiar selección de alerta al tocar el mapa
              setState(() {
                _selectedAlerta = null;
              });
              mapController.setLastTapped(pos);
            },
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer()),
            },
          ),

          // ✅ CARD: CREAR ALERTA (cuando se selecciona un punto)
          if (lastTapped != null && _selectedAlerta == null)
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
                    children: [
                      const Text(
                        'Punto seleccionado',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () =>
                                _crearAlertaEnPosicion(lastTapped),
                            icon: const Icon(Icons.add_alert),
                            label: const Text('Crear Alerta'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              mapController.setLastTapped(null);
                            },
                            child: const Text('Cancelar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ✅ CARD: INFORMACIÓN DE ALERTA SELECCIONADA
          if (_selectedAlerta != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                elevation: 8,
                color:Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getEstadoColor(_selectedAlerta!.estado),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getEstadoIcon(_selectedAlerta!.estado),
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedAlerta!.type,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedAlerta!.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedAlerta = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      // ✅ ESTADO DE LA ALERTA
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getEstadoColor(_selectedAlerta!.estado)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getEstadoColor(_selectedAlerta!.estado),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: _getEstadoColor(_selectedAlerta!.estado),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estado actual',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getEstadoTexto(_selectedAlerta!.estado),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _getEstadoColor(
                                          _selectedAlerta!.estado),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // // ✅ Botón para ver más detalles
                      // SizedBox(
                      //   width: double.infinity,
                      //   child: OutlinedButton.icon(
                      //     onPressed: () {
                      //       Navigator.pushNamed(
                      //         context,
                      //         '/detalle-alerta',
                      //         arguments: _selectedAlerta,
                      //       );
                      //     },
                      //     icon: const Icon(Icons.visibility),
                      //     label: const Text('Ver detalles completos'),
                      //     style: OutlinedButton.styleFrom(
                      //       padding: const EdgeInsets.symmetric(vertical: 12),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'recentrar',
            onPressed: _initLocation,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'reportarAqui',
            onPressed: _reportarEnMiUbicacion,
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_alert),
          ),
        ],
      ),
    );
  }
}
