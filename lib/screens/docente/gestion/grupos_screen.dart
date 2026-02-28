import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/gestion_service.dart';
import '../../../models/semestre_model.dart';
import '../../../models/grupo_model.dart';

class GruposScreen extends StatelessWidget {
  final Semestre semestre;
  const GruposScreen({super.key, required this.semestre});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final gestionService = GestionService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Grupos — ${semestre.nombre}'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Grupo>>(
        stream: gestionService.getGrupos(semestre.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final grupos = snapshot.data ?? [];

          if (grupos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.group_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay grupos en este semestre',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Toca el botón + para agregar uno',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grupos.length,
            itemBuilder: (context, index) {
              final grupo = grupos[index];
              return _GrupoCard(
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
        label: const Text('Nuevo grupo'),
      ),
    );
  }

  void _mostrarDialogoCrear(
      BuildContext context, String docenteId, GestionService gestionService) {
    final nombreController = TextEditingController();
    String gradoSeleccionado = '1';
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo Grupo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: 'Nombre del grupo',
                  hintText: 'Ej: 2°B',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: gradoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Grado',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ['1', '2', '3', '4', '5', '6']
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text('$g° Semestre'),
                        ))
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (val) => setState(() => gradoSeleccionado = val ?? '1'),
              ),
            ],
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
                            content:
                                Text('Escribe el nombre del grupo'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      await gestionService.crearGrupo(
                        Grupo(
                          id: '',
                          nombre: nombreController.text.trim(),
                          grado: gradoSeleccionado,
                          semestreId: semestre.id,
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

class _GrupoCard extends StatelessWidget {
  final Grupo grupo;
  final GestionService gestionService;

  const _GrupoCard({
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
            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.group_rounded,
              color: Color(0xFF1565C0)),
        ),
        title: Text(grupo.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${grupo.grado}° Semestre'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmarEliminar(context),
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
          title: const Text('Eliminar grupo'),
          content: Text('¿Eliminar el grupo "${grupo.nombre}"?'),
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
                      await gestionService.eliminarGrupo(grupo.id);
                      if (context.mounted) Navigator.pop(context);
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
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