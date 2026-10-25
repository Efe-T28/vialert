import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../controllers/hospital_controller.dart';
import '../../models/hospital_model.dart';
import '../app.dart';

class AdminHospitalesScreen extends StatefulWidget {
  const AdminHospitalesScreen({super.key});

  @override
  State<AdminHospitalesScreen> createState() => _AdminHospitalesScreenState();
}

class _AdminHospitalesScreenState extends State<AdminHospitalesScreen> {
  final nombre = TextEditingController();
  LatLng? posicionElegida;
  HospitalModel? _editando;
  bool loading = false;

  @override
  void dispose() {
    nombre.dispose();
    super.dispose();
  }

  void _aviso(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _editar(HospitalModel h) {
    setState(() {
      _editando = h;
      nombre.text = h.nombre;
      posicionElegida = h.position;
    });
  }

  void _cancelarEdicion() {
    setState(() {
      _editando = null;
      nombre.clear();
      posicionElegida = null;
    });
  }

  Future<void> _guardar() async {
    if (nombre.text.trim().isEmpty) {
      _aviso('Ingresa un nombre para el hospital');
      return;
    }
    if (posicionElegida == null) {
      _aviso('Toca el mapa para elegir la ubicación del hospital');
      return;
    }

    final hospitales = context.read<HospitalController>();
    setState(() => loading = true);
    try {
      if (_editando != null) {
        await hospitales.actualizarHospital(
          _editando!.id,
          nombre.text.trim(),
          posicionElegida!,
        );
        _aviso('Hospital actualizado');
      } else {
        await hospitales.crearHospital(nombre.text.trim(), posicionElegida!);
        _aviso('Hospital creado');
      }
      _cancelarEdicion();
    } catch (e) {
      _aviso('Error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _eliminar(HospitalModel h) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar hospital'),
        content: Text('¿Eliminar "${h.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;
    await context.read<HospitalController>().eliminarHospital(h.id);
    if (_editando?.id == h.id) _cancelarEdicion();
  }

  @override
  Widget build(BuildContext context) {
    final hospitales = context.watch<HospitalController>().hospitales;

    final Set<Marker> markers = {
      if (posicionElegida != null)
        Marker(
          markerId: const MarkerId('elegido'),
          position: posicionElegida!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet),
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestionar Hospitales', style: appSectionTitleStyle(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editando != null ? 'Editar hospital' : 'Nuevo hospital',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nombre,
                decoration: const InputDecoration(
                  labelText: 'Nombre del hospital',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Toca el mapa para elegir la ubicación',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 260,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: posicionElegida ??
                          const LatLng(10.4742, -73.2436),
                      zoom: 13,
                    ),
                    markers: markers,
                    onTap: (pos) => setState(() => posicionElegida = pos),
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer()),
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_editando != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelarEdicion,
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _guardar,
                            child: Text(
                                _editando != null ? 'Guardar cambios' : 'Crear hospital'),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Hospitales registrados',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (hospitales.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No hay hospitales registrados todavía.'),
                )
              else
                ...hospitales.map(
                  (h) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_hospital, color: Colors.purple),
                      title: Text(h.nombre),
                      subtitle: Text(
                          '${h.position.latitude.toStringAsFixed(5)}, ${h.position.longitude.toStringAsFixed(5)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editar(h),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminar(h),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
