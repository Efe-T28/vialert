import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'usuario/usuario_home.dart';
import 'ambulancia/ambulancia_home.dart';
import 'admin/admin_home.dart';

/// Tema M3 compartido por toda la app: paleta azul/blanco (ColorScheme
/// generado desde un seed azul) + tipografía Inter, con los títulos en
/// negro para dar jerarquía frente al cuerpo de texto en gris oscuro.
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  );
  final baseTextTheme = GoogleFonts.interTextTheme();

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,
    textTheme: baseTextTheme.copyWith(
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        color: Colors.black,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      filled: true,
      // Mismo tono que usan las tarjetas de "Gestión de Personal"
      // (Card sin color explícito, tono M3 por defecto).
      fillColor: colorScheme.surfaceContainerLow,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

/// Estilo decorativo para el nombre de la app ("Vialert") en las pantallas
/// de autenticación: Inter Thin Italic, el acento elegante pedido para
/// diferenciar la marca del resto de la jerarquía tipográfica (negra,
/// peso medio/semibold).
TextStyle appBrandTextStyle(BuildContext context, {double fontSize = 40}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w100,
    fontStyle: FontStyle.italic,
    color: Theme.of(context).colorScheme.primary,
  );
}

/// Estilo para los títulos de AppBar de las pantallas "Crear X" del panel
/// de administración: Inter Italic en un peso legible (Light), más sutil
/// que el título semibold por defecto pero sin llegar al Thin 100 reservado
/// para la marca "Vialert".
TextStyle appSectionTitleStyle(BuildContext context, {double fontSize = 20}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w300,
    fontStyle: FontStyle.italic,
    color: Colors.black,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vialert',
      theme: buildAppTheme(),
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