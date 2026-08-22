import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/personal_controller.dart';

class CrearConductorScreen extends StatefulWidget {
  const CrearConductorScreen({super.key});
  @override
  State<CrearConductorScreen> createState() => _CrearConductorScreenState();
}

class _CrearConductorScreenState extends State<CrearConductorScreen> {
  final nombre = TextEditingController();
  final apellido = TextEditingController();
  final cedula = TextEditingController();
  final entidad = TextEditingController();
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<PersonalController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Conductor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
              controller: entidad,
              decoration: const InputDecoration(labelText: 'EntidadId')),
          const SizedBox(height: 16),
          loading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () async {
                    setState(() => loading = true);
                    await ctrl.crearConductor(
                        nombre: nombre.text.trim(),
                        apellido: apellido.text.trim(),
                        cedula: cedula.text.trim(),
                        entidadId: entidad.text.trim());
                    setState(() => loading = false);
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar'),
                ),
        ]),
      ),
    );
  }
}
