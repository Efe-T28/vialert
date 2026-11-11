import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';
import '../../controllers/atencion_alerta_controller.dart';
import '../../controllers/map_controller.dart';
import 'ambulancia_alertas_screen.dart';
import 'ambulancia_mapa_screen.dart';
import 'ambulancia_perfil_screen.dart';
import 'isla_navegacion_overlay.dart';

class AmbulanciaMapaHome extends StatefulWidget {
  const AmbulanciaMapaHome({super.key});

  @override
  State<AmbulanciaMapaHome> createState() => _AmbulanciaMapaHomeState();
}

class _AmbulanciaMapaHomeState extends State<AmbulanciaMapaHome>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _islaActiva = false;

  bool get _islaSoportada => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ocultarIsla();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_islaSoportada) return;
    if (state == AppLifecycleState.paused) {
      _mostrarIslaSiEnRuta();
    } else if (state == AppLifecycleState.resumed) {
      _ocultarIsla();
    }
  }

  Future<void> _mostrarIslaSiEnRuta() async {
    final atencion = context.read<AtencionAlertaController>();
    if (!atencion.isEnRuta) return;
    if (!await FlutterOverlayWindow.isPermissionGranted()) return;

    await FlutterOverlayWindow.showOverlay(
      width: IslaNavegacionTamanos.anchoCompacto,
      height: IslaNavegacionTamanos.altoCompacto,
      alignment: OverlayAlignment.topCenter,
      flag: OverlayFlag.defaultFlag,
      enableDrag: false,
      overlayTitle: 'Vialert en ruta',
      overlayContent: 'Navegación de emergencia activa',
    );
    _islaActiva = true;
    atencion.addListener(_sincronizarIsla);
    _sincronizarIsla();
  }

  Future<void> _ocultarIsla() async {
    if (!_islaActiva) return;
    _islaActiva = false;
    context.read<AtencionAlertaController>().removeListener(_sincronizarIsla);
    await FlutterOverlayWindow.closeOverlay();
  }

  /// Empuja el estado de la atención hacia la isla en cada cambio
  /// (countdown de cada segundo, recálculos de ruta, fin de atención).
  void _sincronizarIsla() {
    if (!_islaActiva) return;
    final atencion = context.read<AtencionAlertaController>();
    if (!atencion.isEnRuta) {
      _ocultarIsla();
      return;
    }
    final mapCtrl = context.read<MapController>();
    FlutterOverlayWindow.shareData({
      'restante': atencion.remainingSeconds,
      'total': atencion.duracionTotalSegundos,
      'instruccion': mapCtrl.proximoPaso?.instruccion ?? '',
      'maniobra': mapCtrl.proximoPaso?.maniobra ?? '',
      'esHospital': atencion.isEnRutaHospital,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantiene vivo el GoogleMap (polyline/cámara) al
      // cambiar de tab a mitad de una ruta.
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          AmbulanciaAlertasScreen(
            onIrAlMapa: () => setState(() => _selectedIndex = 1),
          ),
          const AmbulanciaMapaScreen(),
          const AmbulanciaPerfilScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            label: 'Alertas',
          ),
          NavigationDestination(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
