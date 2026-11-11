import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:intl/intl.dart';
import 'maniobra_icono.dart';

/// Tamaños (en dp) de la ventana overlay; los usa también el shell que
/// muestra la isla desde la app principal.
class IslaNavegacionTamanos {
  IslaNavegacionTamanos._();
  static const int anchoCompacto = 300;
  static const int altoCompacto = 64;
  static const int anchoExpandido = 360;
  static const int altoExpandido = 200;
}

/// Isla de navegación que se dibuja sobre otras apps (estilo Dynamic
/// Island). Solo informativa: muestra flecha, ETA e instrucción y se
/// expande al tocarla. Recibe su estado por [FlutterOverlayWindow.shareData]
/// y sigue descontando el tiempo con un timer propio aunque la app
/// principal deje de enviar datos.
class IslaNavegacionOverlay extends StatefulWidget {
  const IslaNavegacionOverlay({super.key});

  @override
  State<IslaNavegacionOverlay> createState() => _IslaNavegacionOverlayState();
}

class _IslaNavegacionOverlayState extends State<IslaNavegacionOverlay> {
  int _restante = 0;
  int _total = 1;
  String _instruccion = '';
  String _maniobra = '';
  bool _esHospital = false;
  bool _expandida = false;

  StreamSubscription? _datosSub;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _datosSub = FlutterOverlayWindow.overlayListener.listen((datos) {
      if (datos is! Map) return;
      setState(() {
        _restante = (datos['restante'] as num?)?.toInt() ?? _restante;
        _total = (datos['total'] as num?)?.toInt() ?? _total;
        _instruccion = datos['instruccion'] ?? _instruccion;
        _maniobra = datos['maniobra'] ?? _maniobra;
        _esHospital = datos['esHospital'] ?? _esHospital;
      });
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restante > 0) setState(() => _restante--);
    });
  }

  @override
  void dispose() {
    _datosSub?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _alternarExpansion() async {
    setState(() => _expandida = !_expandida);
    await FlutterOverlayWindow.resizeOverlay(
      _expandida
          ? IslaNavegacionTamanos.anchoExpandido
          : IslaNavegacionTamanos.anchoCompacto,
      _expandida
          ? IslaNavegacionTamanos.altoExpandido
          : IslaNavegacionTamanos.altoCompacto,
      false,
    );
  }

  String _formatoRestante(int segundos) {
    if (segundos < 60) return '$segundos s';
    return '${(segundos / 60).ceil()} min';
  }

  String get _horaLlegada => DateFormat('h:mm a')
      .format(DateTime.now().add(Duration(seconds: _restante)));

  @override
  Widget build(BuildContext context) {
    final colorAcento =
        _esHospital ? Colors.purpleAccent : Colors.orangeAccent;
    final icono = iconoManiobra(_maniobra);

    final cuerpo = _expandida
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icono, color: colorAcento, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Llegada: $_horaLlegada · ${_formatoRestante(_restante)}',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _instruccion.isEmpty
                              ? (_esHospital
                                  ? 'En camino al hospital'
                                  : 'En camino a la alerta')
                              : _instruccion,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.expand_less,
                      color: Colors.white54, size: 20),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 1 - _restante / (_total <= 0 ? 1 : _total),
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(colorAcento),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vuelve a Vialert para controlar la ruta',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, color: colorAcento, size: 24),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '${_formatoRestante(_restante)} · Llegada: $_horaLlegada',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _alternarExpansion,
        child: Container(
          padding: _expandida
              ? const EdgeInsets.all(14)
              : const EdgeInsets.symmetric(horizontal: 18),
          alignment: _expandida ? null : Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(_expandida ? 22 : 32),
          ),
          child: cuerpo,
        ),
      ),
    );
  }
}
