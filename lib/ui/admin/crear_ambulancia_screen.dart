import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../services/i_auth_service.dart';

class CrearAmbulanciaScreen extends StatefulWidget {
  const CrearAmbulanciaScreen({super.key});

  @override
  State<CrearAmbulanciaScreen> createState() => _CrearAmbulanciaScreenState();
}

class _CrearAmbulanciaScreenState extends State<CrearAmbulanciaScreen> {
  final placa = TextEditingController();
  final codigo = TextEditingController();
  final entidad = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final adminPassword = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final authService = context.read<IAuthService>();
    final authController = context.read<AuthController>();

    final adminEmail = authController.firebaseUser!.email!;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Ambulancia')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
                controller: placa,
                decoration: const InputDecoration(labelText: 'Placa')),
            TextField(
                controller: codigo,
                decoration: const InputDecoration(labelText: 'Código Interno')),
            TextField(
                controller: entidad,
                decoration: const InputDecoration(labelText: 'EntidadId')),
            TextField(
                controller: email,
                decoration:
                    const InputDecoration(labelText: 'Email Ambulancia')),
            TextField(
                controller: password,
                decoration:
                    const InputDecoration(labelText: 'Password Ambulancia'),
                obscureText: true),
            const SizedBox(height: 24),
            TextField(
                controller: adminPassword,
                decoration:
                    const InputDecoration(labelText: 'Tu contraseña de admin'),
                obscureText: true),
            const SizedBox(height: 24),
            loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () async {
                      if (adminPassword.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Debes ingresar tu contraseña de admin")),
                        );
                        return;
                      }

                      setState(() => loading = true);

                      try {
                        await authService.registerAmbulanciaPreservandoAdmin(
                          adminEmail: adminEmail,
                          adminPassword: adminPassword.text.trim(),
                          email: email.text.trim(),
                          password: password.text.trim(),
                          placa: placa.text.trim(),
                          codigoInterno: codigo.text.trim(),
                          entidadId: entidad.text.trim(),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Ambulancia creada correctamente")),
                        );

                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("ERROR: $e")),
                        );
                      } finally {
                        setState(() => loading = false);
                      }
                    },
                    child: const Text('Crear Ambulancia'),
                  ),
          ],
        ),
      ),
    );
  }
}
