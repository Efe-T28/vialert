import 'package:flutter/material.dart';

/// Tira horizontal de miniaturas; al tocar una abre el visor a pantalla completa.
class GaleriaFotosAlerta extends StatelessWidget {
  final List<String> fotos;
  final double altura;
  final bool mostrarTitulo;
  final EdgeInsets padding;

  const GaleriaFotosAlerta({
    super.key,
    required this.fotos,
    this.altura = 110,
    this.mostrarTitulo = true,
    this.padding = const EdgeInsets.only(top: 20),
  });

  @override
  Widget build(BuildContext context) {
    if (fotos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mostrarTitulo) ...[
            Text(
              'Fotos (${fotos.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: altura,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: fotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        VisorFotosAlerta(fotos: fotos, inicial: i),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: altura * 1.2,
                    height: altura,
                    child: FotoAlertaImagen(url: fotos[i]),
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

/// Imagen de red con estados de carga y error. Las URLs "mock://" muestran
/// un marcador de posición (almacenamiento simulado).
class FotoAlertaImagen extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const FotoAlertaImagen({super.key, required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('mock://')) {
      return Container(
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image, color: Colors.grey.shade600),
            const SizedBox(height: 4),
            Text('Foto simulada',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
        ),
      );
    }

    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progreso) {
        if (progreso == null) return child;
        return Container(
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stack) => Container(
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}

/// Visor a pantalla completa con zoom y paso entre fotos.
class VisorFotosAlerta extends StatefulWidget {
  final List<String> fotos;
  final int inicial;

  const VisorFotosAlerta({super.key, required this.fotos, this.inicial = 0});

  @override
  State<VisorFotosAlerta> createState() => _VisorFotosAlertaState();
}

class _VisorFotosAlertaState extends State<VisorFotosAlerta> {
  late final PageController _page =
      PageController(initialPage: widget.inicial);
  late int _actual = widget.inicial;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_actual + 1} / ${widget.fotos.length}'),
      ),
      body: PageView.builder(
        controller: _page,
        itemCount: widget.fotos.length,
        onPageChanged: (i) => setState(() => _actual = i),
        itemBuilder: (context, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: FotoAlertaImagen(url: widget.fotos[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}