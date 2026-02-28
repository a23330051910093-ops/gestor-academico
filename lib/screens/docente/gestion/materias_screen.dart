import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/gestion_service.dart';
import '../../../models/grupo_model.dart';
import '../../../models/materia_model.dart';
import 'alumnos_screen.dart';

class MateriasScreen extends StatelessWidget {
  final Grupo grupo;
  const MateriasScreen({super.key, required this.grupo});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final gestionService = GestionService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Materias — ${grupo.nombre}'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Materia>>(
        stream: gestionService.getMaterias(grupo.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final materias = snapshot.data ?? [];

          if (materias.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay materias en este grupo',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Toca el botón + para agregar una',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: materias.length,
            itemBuilder: (context, index) {
              final materia = materias[index];
              return _MateriaCard(
                materia: materia,
                grupo: grupo,
                gestionService: gestionService,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoCrear(
            context, authService.currentUser!.uid, gestionService),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva materia'),
      ),
    );
  }

  void _mostrarDialogoCrear(
      BuildContext context, String docenteId, GestionService gestionService) {
    final nombreController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nueva Materia'),
          content: TextField(
            controller: nombreController,
            enabled: !isLoading,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nombre de la materia',
              hintText: 'Ej: Programación Web',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nombreController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Escribe el nombre de la materia'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setState(() => isLoading = true);
                      await gestionService.crearMateria(
                        Materia(
                          id: '',
                          nombre: nombreController.text.trim(),
                          grupoId: grupo.id,
                          semestreId: grupo.semestreId,
                          docenteId: docenteId,
                        ),
                      );
                      if (context.mounted) Navigator.pop(context);
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
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MateriaCard extends StatelessWidget {
  final Materia materia;
  final Grupo grupo;
  final GestionService gestionService;

  const _MateriaCard({
    required this.materia,
    required this.grupo,
    required this.gestionService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.book_rounded, color: Color(0xFF6A1B9A)),
        ),
        title: Text(
          materia.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Grupo ${grupo.nombre}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.people_alt_rounded,
                  color: Color(0xFF1565C0)),
              tooltip: 'Ver alumnos',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlumnosScreen(
                    materia: materia,
                    grupo: grupo,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmarEliminar(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context) {
    bool isLoading = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Eliminar materia'),
          content: Text('¿Eliminar "${materia.nombre}"?'),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      await gestionService.eliminarMateria(materia.id);
                      if (context.mounted) Navigator.pop(context);
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Eliminar',
                      style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}