import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/guia_voz.dart';
import '../../controllers/notificador_alertas.dart';
import '../../controllers/ubicacion_publisher.dart';
import 'ambulancia_alertas_screen.dart';
import 'ambulancia_mapa_screen.dart';
import 'ambulancia_perfil_screen.dart';

class AmbulanciaMapaHome extends StatefulWidget {
  const AmbulanciaMapaHome({super.key});

  @override
  State<AmbulanciaMapaHome> createState() => _AmbulanciaMapaHomeState();
}

class _AmbulanciaMapaHomeState extends State<AmbulanciaMapaHome> {
  int _selectedIndex = 0;
  late final NotificadorAlertas _notificador;
  late final GuiaVoz _guiaVoz;
  late final UbicacionPublisher _ubicacionPublisher;

  @override
  void initState() {
    super.initState();
    // Solo la ambulancia en servicio recibe avisos y guía de voz.
    _notificador = context.read<NotificadorAlertas>();
    _notificador.iniciar();
    _guiaVoz = context.read<GuiaVoz>();
    _guiaVoz.iniciar();
    // Publica la posición en ubicaciones/{uid} para la "Flota en vivo".
    _ubicacionPublisher = context.read<UbicacionPublisher>();
    final uid = context.read<AuthController>().uid;
    if (uid != null) _ubicacionPublisher.iniciar(uid);
  }

  @override
  void dispose() {
    _notificador.detener();
    _guiaVoz.detener();
    _ubicacionPublisher.detener();
    super.dispose();
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