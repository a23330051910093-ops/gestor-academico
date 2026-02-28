import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/gestion_service.dart';
import '../../../models/materia_model.dart';
import '../../../models/grupo_model.dart';
import '../../../models/alumno_model.dart';

class AlumnosScreen extends StatelessWidget {
  final Materia materia;
  final Grupo grupo;

  const AlumnosScreen({
    super.key,
    required this.materia,
    required this.grupo,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final gestionService = GestionService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(materia.nombre),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Alumno>>(
        stream: gestionService.getAlumnosPorGrupo(grupo.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final alumnos = snapshot.data ?? [];

          if (alumnos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.person_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay alumnos registrados',
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

          return Column(
            children: [
              // Contador de alumnos
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: const Color(0xFF1565C0).withValues(alpha: 0.05),
                child: Text(
                  '${alumnos.length} alumno${alumnos.length != 1 ? 's' : ''} registrados',
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alumnos.length,
                  itemBuilder: (context, index) {
                    final alumno = alumnos[index];
                    return _AlumnoCard(
                      alumno: alumno,
                      gestionService: gestionService,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoCrear(
            context, authService.currentUser!.uid, gestionService),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo alumno'),
      ),
    );
  }

  void _mostrarDialogoCrear(
      BuildContext context, String docenteId, GestionService gestionService) {
    final nombreController = TextEditingController();
    final matriculaController = TextEditingController();
    final correoController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo Alumno'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  enabled: !isLoading,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: matriculaController,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Matrícula',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: correoController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
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
                      // Validación de campos vacíos
                      if (nombreController.text.isEmpty ||
                          matriculaController.text.isEmpty ||
                          correoController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Completa todos los campos'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      // Verificar matrícula duplicada
                      final existe = await gestionService.existeMatricula(
                        matriculaController.text.trim(),
                        grupo.id,
                      );

                      if (existe) {
                        if (context.mounted) {
                          setState(() => isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Ya existe un alumno con esa matrícula en este grupo'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      await gestionService.crearAlumno(
                        Alumno(
                          id: '',
                          nombre: nombreController.text.trim(),
                          matricula: matriculaController.text.trim(),
                          correo: correoController.text.trim(),
                          docenteId: docenteId,
                          grupoIds: [grupo.id],
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
                  : const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlumnoCard extends StatelessWidget {
  final Alumno alumno;
  final GestionService gestionService;

  const _AlumnoCard({required this.alumno, required this.gestionService});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
          child: Text(
            alumno.nombre.isNotEmpty
                ? alumno.nombre[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Color(0xFF1565C0),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          alumno.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Matrícula: ${alumno.matricula}\n${alumno.correo}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
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
          title: const Text('Eliminar alumno'),
          content: Text(
              '¿Eliminar a "${alumno.nombre}" de este grupo?'),
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
                      await gestionService.eliminarAlumno(alumno.id);
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