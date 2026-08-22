import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nombre = TextEditingController();
  final apellido = TextEditingController();
  final cedula = TextEditingController();
  final telefono = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Registro Usuario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(
              controller: nombre,
              decoration: const InputDecoration(labelText: 'Nombre')),
          TextField(
              controller: apellido,
              decoration: const InputDecoration(labelText: 'Apellido')),
          TextField(
              controller: cedula,
              decoration: const InputDecoration(labelText: 'Cédula')),
          TextField(
              controller: telefono,
              decoration: const InputDecoration(labelText: 'Teléfono')),
          TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email')),
          TextField(
              controller: password,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true),
          const SizedBox(height: 16),
          loading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () async {
                    setState(() => loading = true);
                    final err = await auth.registerUsuario(
                      nombre: nombre.text.trim(),
                      apellido: apellido.text.trim(),
                      cedula: cedula.text.trim(),
                      telefono: telefono.text.trim(),
                      email: email.text.trim(),
                      password: password.text.trim(),
                    );
                    setState(() => loading = false);
                    if (err != null) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(err)));
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Crear cuenta'),
                ),
        ]),
      ),
    );
  }
}
