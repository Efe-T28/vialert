import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/personal_controller.dart';
import '../../controllers/ambulancia_controller.dart';
import '../../controllers/auth_controller.dart';
import 'ambulancia_mapa_home.dart';

class AmbulanciaHome extends StatefulWidget {
  const AmbulanciaHome({super.key});

  @override
  State<AmbulanciaHome> createState() => _AmbulanciaHomeState();
}

class _AmbulanciaHomeState extends State<AmbulanciaHome> {
  String? selectedConductor;
  String? selectedParamedico;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final personal = context.watch<PersonalController>();
    final ambCtrl = context.read<AmbulanciaController>();
    final auth = context.read<AuthController>();
    final myUid = auth.uid;

    // ✅ VALIDACIÓN: Si no hay personal disponible, mostrar mensaje
    final conductoresDisponibles = personal.conductoresDisponibles;
    final paramedicosDisponibles = personal.paramedicosDisponibles;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ambulancia - Asignar Personal"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selecciona el personal para iniciar servicio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // ✅ CONDUCTOR
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Conductor",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    conductoresDisponibles.isEmpty
                        ? const Text(
                            'No hay conductores disponibles',
                            style: TextStyle(color: Colors.grey),
                          )
                        : DropdownButtonFormField<String>(
                            initialValue: conductoresDisponibles.any((c) => c.id == selectedConductor) 
                                ? selectedConductor 
                                : null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Selecciona un conductor',
                            ),
                            items: conductoresDisponibles
                                .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text("${c.nombre} ${c.apellido}"),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => selectedConductor = v),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ PARAMÉDICO
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Paramédico",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    paramedicosDisponibles.isEmpty
                        ? const Text(
                            'No hay paramédicos disponibles',
                            style: TextStyle(color: Colors.grey),
                          )
                        : DropdownButtonFormField<String>(
                            initialValue: paramedicosDisponibles.any((p) => p.id == selectedParamedico) 
                                ? selectedParamedico 
                                : null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Selecciona un paramédico',
                            ),
                            items: paramedicosDisponibles
                                .map((p) => DropdownMenuItem(
                                      value: p.id,
                                      child: Text("${p.nombre} ${p.apellido}"),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => selectedParamedico = v),
                          ),
                  ],
                ),
              ),
            ),
            const Spacer(),

            // ✅ BOTÓN CON VALIDACIÓN
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: (selectedConductor != null &&
                            selectedParamedico != null &&
                            myUid != null)
                        ? () async {
                            setState(() => _loading = true);

                            // Reservar personal
                            final reservedC = await personal.reservarConductor(
                                selectedConductor!, myUid);
                            final reservedP = await personal.reservarParamedico(
                                selectedParamedico!, myUid);

                            if (!reservedC || !reservedP) {
                              if (reservedC) {
                                await personal
                                    .liberarConductor(selectedConductor!);
                              }
                              if (reservedP) {
                                await personal
                                    .liberarParamedico(selectedParamedico!);
                              }
                              setState(() => _loading = false);

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Error reservando personal.")),
                              );
                              return;
                            }

                            // Asignar a ambulancia
                            final ok = await ambCtrl.asignarPersonalAtomico(
                              ambulanciaId: myUid,
                              conductorId: selectedConductor,
                              paramedicoId: selectedParamedico,
                            );

                            setState(() => _loading = false);

                            if (!ok) {
                              await personal
                                  .liberarConductor(selectedConductor!);
                              await personal
                                  .liberarParamedico(selectedParamedico!);

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Error asignando personal.")),
                              );
                              return;
                            }

                            // ✅ NAVEGAR CON pushReplacement PARA EVITAR VOLVER ATRÁS
                            if (!mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AmbulanciaMapaHome(),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.check_circle),
                    label: const Text("Iniciar servicio"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}