import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/flota_controller.dart';
import '../../domain/plantillas_flota.dart';

/// Controladores de una fila (una ambulancia) del formulario.
class _FilaCtrl {
  final placa = TextEditingController();
  final codigo = TextEditingController();
  final email = TextEditingController();

  bool get vacia =>
      placa.text.trim().isEmpty &&
      codigo.text.trim().isEmpty &&
      email.text.trim().isEmpty;

  void dispose() {
    placa.dispose();
    codigo.dispose();
    email.dispose();
  }
}

class CrearFlotaScreen extends StatefulWidget {
  const CrearFlotaScreen({super.key});

  @override
  State<CrearFlotaScreen> createState() => _CrearFlotaScreenState();
}

class _CrearFlotaScreenState extends State<CrearFlotaScreen> {
  final _entidadCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final List<_FilaCtrl> _filas = [_FilaCtrl()];
  String _estadoPlantilla = 'habilitada';
  String? _entidadElegida;

  @override
  void initState() {
    super.initState();
    context.read<FlotaController>().limpiarResultados();
  }

  @override
  void dispose() {
    _entidadCtrl.dispose();
    _passwordCtrl.dispose();
    for (final f in _filas) {
      f.dispose();
    }
    super.dispose();
  }

  void _aviso(String mensaje) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _agregarFila() => setState(() => _filas.add(_FilaCtrl()));

  void _quitarFilas(List<_FilaCtrl> quitar) {
    setState(() {
      _filas.removeWhere(quitar.contains);
      if (_filas.isEmpty) _filas.add(_FilaCtrl());
    });
    // Se liberan después del frame: los TextField aún usan estos controllers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final f in quitar) {
        f.dispose();
      }
    });
  }

  void _guardarPlantilla() {
    final error = context.read<FlotaController>().definirPlantilla(
          _entidadCtrl.text,
          estadoOperativo: _estadoPlantilla,
        );
    if (error != null) {
      _aviso(error);
      return;
    }
    setState(() {
      _entidadElegida = PlantillasFlota.normalizar(_entidadCtrl.text);
    });
  }

  Future<void> _crearFlota() async {
    final flota = context.read<FlotaController>();
    final entidad = _entidadElegida;
    final password = _passwordCtrl.text.trim();

    if (entidad == null) {
      _aviso('Guarda o elige una plantilla primero');
      return;
    }
    if (password.isEmpty) {
      _aviso('Escribe la contraseña inicial');
      return;
    }
    final enviadas = _filas.where((f) => !f.vacia).toList();
    if (enviadas.isEmpty) {
      _aviso('Agrega al menos una ambulancia');
      return;
    }

    final resultados = await flota.crearFlota(entidad, [
      for (final f in enviadas)
        FilaFlota(
          placa: f.placa.text,
          codigoInterno: f.codigo.text,
          email: f.email.text.trim(),
          password: password,
        ),
    ]);

    // Las creadas salen del formulario; quedan solo las que fallaron.
    if (!mounted || resultados.length != enviadas.length) return;
    _quitarFilas([
      for (var i = 0; i < enviadas.length; i++)
        if (resultados[i].exito) enviadas[i],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final flota = context.watch<FlotaController>();
    final plantillas = flota.entidadesConPlantilla;
    final titulo = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Flota')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('1. Plantilla', style: titulo),
          const SizedBox(height: 8),
          TextField(
            controller: _entidadCtrl,
            decoration: const InputDecoration(
                labelText: 'EntidadId (hospital o supervisor)'),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'habilitada', label: Text('Habilitada')),
              ButtonSegment(
                  value: 'inactiva', label: Text('Fuera de servicio')),
            ],
            selected: {_estadoPlantilla},
            onSelectionChanged: (s) =>
                setState(() => _estadoPlantilla = s.first),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _guardarPlantilla,
            child: const Text('Guardar plantilla'),
          ),
          const SizedBox(height: 12),
          if (plantillas.isEmpty)
            const Text('Aún no hay plantillas guardadas.')
          else
            Wrap(
              spacing: 8,
              children: [
                for (final e in plantillas)
                  ChoiceChip(
                    label: Text(e),
                    selected: e == _entidadElegida,
                    onSelected: (_) => setState(() => _entidadElegida = e),
                  ),
              ],
            ),
          const Divider(height: 32),
          Text('2. Ambulancias de la flota', style: titulo),
          const SizedBox(height: 8),
          for (final fila in _filas)
            _FilaWidget(
              key: ObjectKey(fila),
              fila: fila,
              onQuitar: () => _quitarFilas([fila]),
            ),
          TextButton.icon(
            onPressed: _agregarFila,
            icon: const Icon(Icons.add),
            label: const Text('Agregar ambulancia'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: 'Contraseña inicial (igual para toda la flota)'),
          ),
          const SizedBox(height: 16),
          if (flota.creando) ...[
            LinearProgressIndicator(
              value: flota.total == 0 ? null : flota.procesadas / flota.total,
            ),
            const SizedBox(height: 8),
            Text('Procesadas ${flota.procesadas} de ${flota.total}'),
          ] else
            ElevatedButton(
              onPressed: _crearFlota,
              child: const Text('Crear flota'),
            ),
          if (flota.resultados.isNotEmpty) ...[
            const Divider(height: 32),
            Text(
              'Resultado: ${flota.resultados.where((r) => r.exito).length} '
              'creadas, ${flota.resultados.where((r) => !r.exito).length} '
              'con error',
              style: titulo,
            ),
            for (final r in flota.resultados)
              ListTile(
                dense: true,
                leading: Icon(
                  r.exito ? Icons.check_circle : Icons.error,
                  color: r.exito ? Colors.green : Colors.red,
                ),
                title: Text(r.fila.placa),
                subtitle: Text(r.exito ? r.fila.email : r.error!),
              ),
          ],
        ],
      ),
    );
  }
}

class _FilaWidget extends StatelessWidget {
  final _FilaCtrl fila;
  final VoidCallback onQuitar;

  const _FilaWidget({super.key, required this.fila, required this.onQuitar});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: fila.placa,
                    decoration: const InputDecoration(labelText: 'Placa'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: fila.codigo,
                    decoration:
                        const InputDecoration(labelText: 'Código interno'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Quitar',
                  onPressed: onQuitar,
                ),
              ],
            ),
            TextField(
              controller: fila.email,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  const InputDecoration(labelText: 'Email de la ambulancia'),
            ),
          ],
        ),
      ),
    );
  }
}