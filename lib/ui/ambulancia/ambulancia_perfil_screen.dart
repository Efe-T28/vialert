import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/ambulancia_controller.dart';
import '../../services/firestore_service.dart';
import '../../models/ambulancia_model.dart';
import '../../models/conductor_model.dart';
import '../../models/paramedico_model.dart';

class AmbulanciaPerfilScreen extends StatefulWidget {
  const AmbulanciaPerfilScreen({super.key});

  @override
  State<AmbulanciaPerfilScreen> createState() => _AmbulanciaPerfilScreenState();
}

class _AmbulanciaPerfilScreenState extends State<AmbulanciaPerfilScreen> {
  AmbulanciaModel? _ambulancia;
  ConductorModel? _conductor;
  ParamedicoModel? _paramedico;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthController>();
    final fs = context.read<FirestoreService>();

    if (auth.uid == null) return;

    try {
      final amb = await fs.getAmbulanciaById(auth.uid!);
      setState(() => _ambulancia = amb);

      if (amb?.currentConductorId != null) {
        final conductor = await fs.getConductorById(amb!.currentConductorId!);
        setState(() => _conductor = conductor);
      }

      if (amb?.currentParamedicoId != null) {
        final paramedico =
            await fs.getParamedicoById(amb!.currentParamedicoId!);
        setState(() => _paramedico = paramedico);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?\n\nEsto liberará al conductor y paramédico asignados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final auth = context.read<AuthController>();
    final ambCtrl = context.read<AmbulanciaController>();

    // ✅ LIBERAR PERSONAL ANTES DE CERRAR SESIÓN
    if (auth.uid != null) {
      await ambCtrl.liberarPersonalYResetAmbulancia(auth.uid!);
    }

    // ✅ CERRAR SESIÓN (AuthWrapper detectará el cambio automáticamente)
    await auth.logout();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil Ambulancia'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.red.shade100,
                child: const Icon(
                  Icons.local_hospital,
                  size: 50,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Información de la Ambulancia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.badge,
              title: 'Placa',
              content: _ambulancia?.placa ?? '---',
            ),
            const SizedBox(height: 8),
            _buildInfoCard(
              icon: Icons.numbers,
              title: 'Código Interno',
              content: _ambulancia?.codigoInterno ?? '---',
            ),
            const SizedBox(height: 8),
            _buildInfoCard(
              icon: Icons.business,
              title: 'Entidad',
              content: _ambulancia?.entidadId ?? '---',
            ),
            const SizedBox(height: 24),
            const Text(
              'Personal Asignado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.drive_eta,
              title: 'Conductor',
              content: _conductor != null
                  ? '${_conductor!.nombre} ${_conductor!.apellido}'
                  : 'No asignado',
            ),
            const SizedBox(height: 8),
            _buildInfoCard(
              icon: Icons.medical_services,
              title: 'Paramédico',
              content: _paramedico != null
                  ? '${_paramedico!.nombre} ${_paramedico!.apellido}'
                  : 'No asignado',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cerrarSesion,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}