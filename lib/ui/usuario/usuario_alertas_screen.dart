import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/alert_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../domain/iterators/historial_alertas_collection.dart';
import '../../models/alerta_model.dart';
import 'usuario_detalle_alerta_screen.dart';

class UsuarioAlertasScreen extends StatelessWidget {
  const UsuarioAlertasScreen({super.key});

  Color _colorEstado(AlertState estado) => switch (estado) {
        AlertState.activa => Colors.red,
        AlertState.enProceso => Colors.orange,
        AlertState.atendida => Colors.green,
      };

  String _textoEstado(AlertState estado) => switch (estado) {
        AlertState.activa => 'Activa',
        AlertState.enProceso => 'En proceso',
        AlertState.atendida => 'Atendida',
      };

  /// Ordena por fecha (más reciente primero) reutilizando el Iterator
  /// del historial de alertas.
  List<AlertaModel> _ordenarPorFecha(List<AlertaModel> alertas) {
    final it = HistorialAlertasCollection(alertas).porFecha();
    final ordenadas = <AlertaModel>[];
    while (it.hasNext()) {
      ordenadas.add(it.next());
    }
    return ordenadas;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();

    // ✅ CAMBIO: Comparar por nombre completo
    final nombreUsuario = auth.usuario != null
        ? '${auth.usuario!.nombre} ${auth.usuario!.apellido}'
        : '';

    final alertController = context.watch<AlertController>();
    final misAlertas =
        _ordenarPorFecha(alertController.getAlertasByUsuario(nombreUsuario));

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
                      color: _colorEstado(a.estado),
                    ),
                    title: Text(a.type),
                    subtitle: Text(
                      a.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Chip(
                      label: Text(_textoEstado(a.estado)),
                      backgroundColor:
                          _colorEstado(a.estado).withValues(alpha: 0.15),
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
