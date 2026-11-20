// lib/ui/admin/admin_flota_vivo_screen.dart
//
// PANTALLA TEMPORAL DE PRUEBA: muestra en un mapa las ambulancias que están
// publicando su ubicación. Sirve para comprobar de punta a punta (teléfono de
// la ambulancia -> Firestore -> reglas -> administrador) que la vista en vivo
// funciona, antes de construir el panel web. Cuando exista el panel se puede
// borrar: usa el mismo `streamUbicaciones()`.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/ambulancia_model.dart';
import '../../models/ubicacion_model.dart';
import '../../services/i_database_service.dart';

class AdminFlotaVivoScreen extends StatefulWidget {
  const AdminFlotaVivoScreen({super.key});

  @override
  State<AdminFlotaVivoScreen> createState() => _AdminFlotaVivoScreenState();
}

class _AdminFlotaVivoScreenState extends State<AdminFlotaVivoScreen> {
  /// Sin actualizar más de este tiempo = "sin señal".
  static const _sinSenal = Duration(seconds: 60);
  static const _centroInicial = LatLng(10.4631, -73.2532);

  late final Stream<List<UbicacionModel>> _ubicaciones;
  late final Stream<List<AmbulanciaModel>> _ambulancias;
  GoogleMapController? _mapa;
  Timer? _reloj;
  bool _encuadrado = false;
  List<LatLng> _posiciones = const [];

  @override
  void initState() {
    super.initState();
    final db = context.read<IDatabaseService>();
    _ubicaciones = db.streamUbicaciones();
    _ambulancias = db.streamAmbulancias();
    // La antigüedad cambia aunque no lleguen datos nuevos: se redibuja cada
    // 10 s para que una unidad pase a "sin señal" a tiempo.
    _reloj = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  double _tono(UbicacionModel u, bool sinSenal) {
    if (sinSenal) return BitmapDescriptor.hueViolet;
    switch (u.estadoOperativo) {
      case 'enRuta':
        return BitmapDescriptor.hueRed;
      case 'enRutaHospital':
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueGreen;
    }
  }

  Future<void> _encuadrar() async {
    final mapa = _mapa;
    if (mapa == null || _posiciones.isEmpty) return;
    if (_posiciones.length == 1) {
      await mapa.animateCamera(CameraUpdate.newLatLngZoom(_posiciones.first, 15));
      return;
    }
    var minLat = _posiciones.first.latitude, maxLat = minLat;
    var minLng = _posiciones.first.longitude, maxLng = minLng;
    for (final p in _posiciones) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    await mapa.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
          southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
      80,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<AmbulanciaModel>>(
        stream: _ambulancias,
        builder: (context, ambSnap) {
          final ambulancias = {
            for (final a in ambSnap.data ?? const <AmbulanciaModel>[]) a.id: a,
          };
          return StreamBuilder<List<UbicacionModel>>(
            stream: _ubicaciones,
            builder: (context, ubSnap) {
              if (ubSnap.hasError) {
                // Aquí se verá "permission-denied" si las reglas no dejan
                // leer `ubicaciones` al administrador.
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No se pudo leer la flota:\n${ubSnap.error}'),
                  ),
                );
              }

              final ahora = DateTime.now();
              final marcadores = <Marker>{};
              final posiciones = <LatLng>[];
              var sinSenal = 0;

              for (final u in ubSnap.data ?? const <UbicacionModel>[]) {
                final amb = ambulancias[u.ambulanciaId];
                // Una unidad fuera de turno no debe verse aunque quede un
                // documento viejo.
                if (amb != null && !amb.enTurno) continue;

                final edad = ahora.difference(u.timestamp);
                final perdida = edad > _sinSenal;
                if (perdida) sinSenal++;

                final pos = LatLng(u.lat, u.lng);
                posiciones.add(pos);
                final nombre = amb?.placa ?? u.ambulanciaId ?? '?';
                marcadores.add(Marker(
                  markerId: MarkerId(u.ambulanciaId ?? nombre),
                  position: pos,
                  icon: BitmapDescriptor.defaultMarkerWithHue(_tono(u, perdida)),
                  infoWindow: InfoWindow(
                    title: perdida ? '$nombre (sin señal)' : nombre,
                    snippet: '${u.estadoOperativo ?? '-'} · hace '
                        '${edad.inSeconds}s · '
                        '${u.velocidadKmh?.round() ?? 0} km/h · '
                        'v${u.appVersion ?? '?'}',
                  ),
                ));
              }

              _posiciones = posiciones;
              if (!_encuadrado && posiciones.isNotEmpty && _mapa != null) {
                _encuadrado = true;
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _encuadrar());
              }

              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition:
                        const CameraPosition(target: _centroInicial, zoom: 12),
                    markers: marcadores,
                    onMapCreated: (c) => _mapa = c,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Card(
                        margin: const EdgeInsets.all(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Text(
                            marcadores.isEmpty
                                ? 'Ninguna unidad publicando ubicación'
                                : 'Unidades: ${marcadores.length} · '
                                    'Sin señal: $sinSenal',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _encuadrar,
        tooltip: 'Ver toda la flota',
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }
}