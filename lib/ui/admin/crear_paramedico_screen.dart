import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/personal_controller.dart';
import '../../domain/factories/personal_factory.dart';

class CrearParamedicoScreen extends StatefulWidget {
  const CrearParamedicoScreen({super.key});
  @override
  State<CrearParamedicoScreen> createState() => _CrearParamedicoScreenState();
}

class _CrearParamedicoScreenState extends State<CrearParamedicoScreen> {
  final nombre = TextEditingController();
  final apellido = TextEditingController();
  final cedula = TextEditingController();
  final telefono = TextEditingController();
  final entidad = TextEditingController();
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<PersonalController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Paramedico')),
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
              controller: telefono,
              decoration: const InputDecoration(labelText: 'Teléfono')),
          TextField(
              controller: entidad,
              decoration: const InputDecoration(labelText: 'EntidadId')),
          const SizedBox(height: 16),
          loading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () async {
                    setState(() => loading = true);
                    await ctrl.crearPersonal(
                        TipoPersonal.paramedico,
                        nombre: nombre.text.trim(),
                        apellido: apellido.text.trim(),
                        cedula: cedula.text.trim(),
                        telefono: telefono.text.trim(),
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
