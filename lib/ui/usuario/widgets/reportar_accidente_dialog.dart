import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/app_config.dart';
import '../../../controllers/alert_controller.dart';

/// Resultado del diálogo: descripción y fotos (en bytes) elegidas.
class ReporteAccidente {
  final String descripcion;
  final List<Uint8List> fotos;

  const ReporteAccidente({required this.descripcion, this.fotos = const []});
}

class ReportarAccidenteDialog extends StatefulWidget {
  const ReportarAccidenteDialog({super.key});

  @override
  State<ReportarAccidenteDialog> createState() =>
      _ReportarAccidenteDialogState();
}

class _ReportarAccidenteDialogState extends State<ReportarAccidenteDialog> {
  final _descripcion = TextEditingController();
  final _picker = ImagePicker();
  final List<Uint8List> _fotos = [];
  bool _cargando = false;
  String? _error;

  int get _cupo => AlertController.maxFotos - _fotos.length;

  @override
  void dispose() {
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _agregar(ImageSource origen) async {
    if (_cupo <= 0 || _cargando) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final List<XFile> elegidas;
      if (origen == ImageSource.camera) {
        final foto = await _picker.pickImage(
          source: origen,
          maxWidth: 1280,
          imageQuality: 75,
        );
        elegidas = foto == null ? [] : [foto];
      } else {
        elegidas = await _picker.pickMultiImage(
          maxWidth: 1280,
          imageQuality: 75,
        );
      }

      final nuevas = <Uint8List>[];
      for (final x in elegidas.take(_cupo)) {
        nuevas.add(await x.readAsBytes());
      }
      if (!mounted) return;
      setState(() => _fotos.addAll(nuevas));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error =
          'No se pudo obtener la foto. Verifica los permisos de cámara o galería.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _crear() {
    final texto = _descripcion.text.trim();
    Navigator.pop(
      context,
      ReporteAccidente(
        descripcion: texto.isEmpty ? 'Sin descripción' : texto,
        fotos: List.of(_fotos),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reportar Accidente'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _descripcion,
              decoration:
                  const InputDecoration(hintText: 'Descripción (opcional)'),
              maxLines: 3,
            ),
            if (AppConfig.fotosHabilitadas) ...[
              const SizedBox(height: 16),
              Text(
                'Fotos (${_fotos.length}/${AlertController.maxFotos})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _cupo > 0 && !_cargando
                        ? () => _agregar(ImageSource.camera)
                        : null,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Cámara'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _cupo > 0 && !_cargando
                        ? () => _agregar(ImageSource.gallery)
                        : null,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                ],
              ),
              if (_cargando) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              if (_fotos.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _fotos.length; i++)
                      _Miniatura(
                        bytes: _fotos[i],
                        onQuitar: () => setState(() => _fotos.removeAt(i)),
                      ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _cargando ? null : _crear,
          child: const Text('Crear'),
        ),
      ],
    );
  }
}

class _Miniatura extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onQuitar;

  const _Miniatura({required this.bytes, required this.onQuitar});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(bytes, width: 72, height: 72, fit: BoxFit.cover),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onQuitar,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}