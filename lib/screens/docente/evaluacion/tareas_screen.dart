import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/tarea_service.dart';
import '../../../services/rubrica_service.dart';
import '../../../models/tarea_model.dart';
import '../../../models/materia_model.dart';
import '../../../models/grupo_model.dart';
import '../../../models/rubrica_model.dart';
import 'entregas_screen.dart';

class TareasScreen extends StatelessWidget {
  final Materia materia;
  final Grupo grupo;

  const TareasScreen({
    super.key,
    required this.materia,
    required this.grupo,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final tareaService = TareaService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(materia.nombre),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _mostrarDialogoCrear(context, authService, tareaService),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarea'),
      ),
      body: StreamBuilder<List<Tarea>>(
        stream: tareaService.getTareas(materia.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tareas = snapshot.data ?? [];

          if (tareas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Sin tareas creadas',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Toca + para crear la primera tarea',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: tareas.length,
            itemBuilder: (context, index) {
              final tarea = tareas[index];
              return _TareaCard(
                tarea: tarea,
                tareaService: tareaService,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EntregasScreen(
                      tarea: tarea,
                      materia: materia,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _mostrarDialogoCrear(
      BuildContext context, AuthService authService, TareaService tareaService) {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final rubricaService = RubricaService();

    String? rubricaIdSeleccionada;
    String? rubricaNombreSeleccionada;

    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nueva Tarea'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la tarea',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descripcionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Instrucciones (opcional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),

                StreamBuilder<List<Rubrica>>(
                  stream: rubricaService.getRubricas(materia.id),
                  builder: (context, snapshot) {
                    final rubricas = snapshot.data ?? [];

                    if (rubricas.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Text(
                          'No hay rúbricas en esta materia. '
                          'Crea una primero en el módulo de Rúbricas.',
                          style: TextStyle(fontSize: 12),
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: rubricaIdSeleccionada,
                      decoration: InputDecoration(
                        labelText: 'Rúbrica de evaluación',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      items: rubricas
                          .map((r) => DropdownMenuItem<String>(
                                value: r.id,
                                child: Text(r.nombre,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (id) {
                        if (id == null) return;
                        final rubrica =
                            rubricas.firstWhere((r) => r.id == id);
                        setState(() {
                          rubricaIdSeleccionada = id;
                          rubricaNombreSeleccionada = rubrica.nombre;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading ||
                      nombreController.text.isEmpty ||
                      rubricaIdSeleccionada == null
                  ? null
                  : () async {
                      setState(() => isLoading = true);

                      await tareaService.crearTarea(
                        Tarea(
                          id: '',
                          nombre: nombreController.text.trim(),
                          descripcion:
                              descripcionController.text.trim(),
                          materiaId: materia.id,
                          grupoId: grupo.id,
                          docenteId: authService.currentUser!.uid,
                          rubricaId: rubricaIdSeleccionada!,
                          rubricaNombre: rubricaNombreSeleccionada!,
                          fechaCreacion: DateTime.now(),
                        ),
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TareaCard extends StatelessWidget {
  final Tarea tarea;
  final TareaService tareaService;
  final VoidCallback onTap;

  const _TareaCard({
    required this.tarea,
    required this.tareaService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.assignment_rounded,
              color: Color(0xFF6A1B9A)),
        ),
        title: Text(
          tarea.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.checklist_rounded,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  tarea.rubricaNombre,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${tarea.fechaCreacion.day}/${tarea.fechaCreacion.month}/${tarea.fechaCreacion.year}',
              style:
                  const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}