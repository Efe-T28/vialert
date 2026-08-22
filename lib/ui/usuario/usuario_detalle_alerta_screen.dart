import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/alerta_model.dart';

class UsuarioDetalleAlertaScreen extends StatelessWidget {
  final AlertaModel alerta;

  const UsuarioDetalleAlertaScreen({super.key, required this.alerta});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Alerta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              icon: Icons.car_crash,
              title: 'Tipo',
              content: alerta.type,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.description,
              title: 'Descripción',
              content: alerta.description,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'Estado',
              content: alerta.estado.name,
              color: alerta.estado == AlertState.activa
                  ? Colors.orange
                  : Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.calendar_today,
              title: 'Fecha de creación',
              content: dateFormat.format(alerta.createdAt),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ubicación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: alerta.position,
                    zoom: 16,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId(alerta.id),
                      position: alerta.position,
                    ),
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    Color? color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color ?? Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}