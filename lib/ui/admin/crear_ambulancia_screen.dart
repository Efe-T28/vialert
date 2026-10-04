import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/builders/ambulancia_builder.dart';
import '../../domain/builders/ambulancia_director.dart';
import '../../domain/builders/i_ambulancia_builder.dart';
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

  bool loading = false;

  @override
  void dispose() {
    placa.dispose();
    codigo.dispose();
    entidad.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final authService = context.read<IAuthService>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => loading = true);
    try {
      // Director + Builder arman los datos de la ambulancia.
      final IAmbulanciaBuilder builder = AmbulanciaBuilder();
      AmbulanciaDirector(builder).construirEstandar(
        placa: placa.text,
        codigoInterno: codigo.text,
        entidadId: entidad.text,
      );

      await authService.registerAmbulancia(
        email: email.text.trim(),
        password: password.text.trim(),
        datos: builder,
      );

      messenger.showSnackBar(
        const SnackBar(content: Text('Ambulancia creada correctamente')),
      );
      if (mounted) navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('ERROR: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _crear,
                    child: const Text('Crear Ambulancia'),
                  ),
          ],
        ),
      ),
    );
  }
}