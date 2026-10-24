import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/personal_controller.dart';
import '../../domain/factories/personal_factory.dart';
import '../app.dart';

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
      appBar: AppBar(
        title: Text('Crear Paramédico', style: appSectionTitleStyle(context)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                      controller: nombre,
                      decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person_outline))),
                  const SizedBox(height: 16),
                  TextField(
                      controller: apellido,
                      decoration: const InputDecoration(
                          labelText: 'Apellido',
                          prefixIcon: Icon(Icons.person_outline))),
                  const SizedBox(height: 16),
                  TextField(
                      controller: cedula,
                      decoration: const InputDecoration(
                          labelText: 'Cédula',
                          prefixIcon: Icon(Icons.badge_outlined))),
                  const SizedBox(height: 16),
                  TextField(
                      controller: telefono,
                      decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon: Icon(Icons.phone_outlined))),
                  const SizedBox(height: 16),
                  TextField(
                      controller: entidad,
                      decoration: const InputDecoration(
                          labelText: 'EntidadId',
                          prefixIcon: Icon(Icons.business_outlined))),
                  const SizedBox(height: 28),
                  loading
                      ? const Center(child: CircularProgressIndicator())
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
