import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/alert_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/alerta_model.dart';
import 'usuario_detalle_alerta_screen.dart';

class UsuarioAlertasScreen extends StatelessWidget {
  const UsuarioAlertasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();

    // ✅ CAMBIO: Comparar por nombre completo
    final nombreUsuario = auth.usuario != null
        ? '${auth.usuario!.nombre} ${auth.usuario!.apellido}'
        : '';

    final alertController = context.watch<AlertController>();
    final misAlertas = alertController.getAlertasByUsuario(nombreUsuario);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Alertas'),
      ),
      body: misAlertas.isEmpty
          ? const Center(
              child: Text('No has creado alertas aún'),
            )
          : ListView.builder(
              itemCount: misAlertas.length,
              itemBuilder: (ctx, i) {
                final a = misAlertas[i];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Icon(
                      Icons.car_crash,
                      color: a.estado == AlertState.activa
                          ? Colors.red
                          : Colors.green,
                    ),
                    title: Text(a.type),
                    subtitle: Text(
                      a.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Chip(
                      label: Text(a.estado.name),
                      backgroundColor: a.estado == AlertState.activa
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UsuarioDetalleAlertaScreen(alerta: a),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
