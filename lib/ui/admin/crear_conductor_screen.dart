import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/personal_controller.dart';
import '../../domain/factories/personal_factory.dart';
import '../app.dart';

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
      appBar: AppBar(
        title: Text('Crear Conductor', style: appSectionTitleStyle(context)),
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
                              TipoPersonal.conductor,
                              nombre: nombre.text.trim(),
                              apellido: apellido.text.trim(),
                              cedula: cedula.text.trim(),
                              entidadId: entidad.text.trim(),
                            );
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
