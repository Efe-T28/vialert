import 'package:flutter/material.dart';
import 'ambulancia_mapa_screen.dart';
import 'ambulancia_atendidas_screen.dart';
import 'ambulancia_perfil_screen.dart';

class AmbulanciaMapaHome extends StatefulWidget {
  const AmbulanciaMapaHome({super.key});

  @override
  State<AmbulanciaMapaHome> createState() => _AmbulanciaMapaHomeState();
}

class _AmbulanciaMapaHomeState extends State<AmbulanciaMapaHome> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    AmbulanciaMapaScreen(),
    AmbulanciaAtendidasScreen(),
    AmbulanciaPerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map),
            label: 'Alertas',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Atendidas',
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