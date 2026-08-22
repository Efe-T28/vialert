import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'usuario/usuario_home.dart';
import 'ambulancia/ambulancia_home.dart';
import 'admin/admin_home.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vialert',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    // Inicializando
    if (auth.isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // No autenticado
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // Autenticado pero sin rol asignado en Firestore
    // (no reintentar en bucle: ya se resolvió el auth listener, esto es
    // un estado final, no una carga temporal)
    if (auth.role == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'No se encontró un rol asociado a esta cuenta.\n'
                  'Intenta registrarte de nuevo o contacta soporte.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => auth.logout(),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Navegación por rol
    switch (auth.role) {
      case 'usuario':
        return const UsuarioHome();
      case 'admin':
        return const AdminHome();
      case 'ambulancia':
        return const AmbulanciaHome();
      default:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Rol no reconocido'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => auth.logout(),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        );
    }
  }
}