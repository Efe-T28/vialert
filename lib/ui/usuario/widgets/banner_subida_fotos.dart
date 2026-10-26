import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/alert_controller.dart';

/// Aviso flotante: progreso de subida de fotos y reintento si fallan.
class BannerSubidaFotos extends StatelessWidget {
  const BannerSubidaFotos({super.key});

  @override
  Widget build(BuildContext context) {
    final subidas = context.watch<AlertController>().subidasConAviso;
    if (subidas.isEmpty) return const SizedBox.shrink();

    final s = subidas.first;
    final controller = context.read<AlertController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Card(
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: s.enCurso
                ? Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Subiendo fotos (${s.subidas}/${s.total})…'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No se pudieron subir ${s.fallidas.length} foto(s). La alerta ya fue enviada.',
                        ),
                      ),
                      TextButton(
                        onPressed: () => controller.reintentarFotos(s.alertaId),
                        child: const Text('Reintentar'),
                      ),
                      TextButton(
                        onPressed: () =>
                            controller.descartarFotosFallidas(s.alertaId),
                        child: const Text('Descartar'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}