import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/gestion_service.dart';
import '../../../models/semestre_model.dart';
import 'grupos_screen.dart';

class SemestresScreen extends StatelessWidget {
  const SemestresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final gestionService = GestionService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Gestión Académica'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Semestre>>(
        stream: gestionService.getSemestres(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar semestres'),
            );
          }

          final semestres = snapshot.data ?? [];

          if (semestres.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay semestres registrados',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Toca el botón + para crear el primero',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: semestres.length,
            itemBuilder: (context, index) {
              final semestre = semestres[index];
              return _SemestreCard(
                semestre: semestre,
                gestionService: gestionService,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoCrear(
          context,
          authService.currentUser!.uid,
          gestionService,
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo semestre'),
      ),
    );
  }

  void _mostrarDialogoCrear(
      BuildContext context, String docenteId, GestionService gestionService) {
    final nombreController = TextEditingController();
    DateTime? fechaInicio;
    DateTime? fechaFin;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo Semestre'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Nombre del semestre',
                    hintText: 'Ej: Ago-Dic 2025',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today,
                      color: Color(0xFF1565C0)),
                  title: Text(
                    fechaInicio == null
                        ? 'Fecha de inicio'
                        : '${fechaInicio!.day}/${fechaInicio!.month}/${fechaInicio!.year}',
                    style: TextStyle(
                      color:
                          fechaInicio == null ? Colors.grey : Colors.black,
                    ),
                  ),
                  onTap: isLoading
                      ? null
                      : () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (fecha != null) {
                            setState(() => fechaInicio = fecha);
                          }
                        },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined,
                      color: Color(0xFF1565C0)),
                  title: Text(
                    fechaFin == null
                        ? 'Fecha de fin'
                        : '${fechaFin!.day}/${fechaFin!.month}/${fechaFin!.year}',
                    style: TextStyle(
                      color: fechaFin == null ? Colors.grey : Colors.black,
                    ),
                  ),
                  onTap: isLoading
                      ? null
                      : () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now()
                                .add(const Duration(days: 90)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (fecha != null) {
                            setState(() => fechaFin = fecha);
                          }
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
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nombreController.text.isEmpty ||
                          fechaInicio == null ||
                          fechaFin == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Completa todos los campos'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      await gestionService.crearSemestre(
                        Semestre(
                          id: '',
                          nombre: nombreController.text.trim(),
                          fechaInicio: fechaInicio!,
                          fechaFin: fechaFin!,
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

class _SemestreCard extends StatelessWidget {
  final Semestre semestre;
  final GestionService gestionService;

  const _SemestreCard({
    required this.semestre,
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
          child: const Icon(Icons.calendar_month_rounded,
              color: Color(0xFF1565C0)),
        ),
        title: Text(semestre.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${semestre.fechaInicio.day}/${semestre.fechaInicio.month}/${semestre.fechaInicio.year} '
          '→ ${semestre.fechaFin.day}/${semestre.fechaFin.month}/${semestre.fechaFin.year}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.people_alt_rounded,
                  color: Color(0xFF1565C0)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GruposScreen(semestre: semestre),
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
          title: const Text('Eliminar semestre'),
          content: Text(
              '¿Seguro que deseas eliminar "${semestre.nombre}"?\nEsta acción no se puede deshacer.'),
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
                      await gestionService.eliminarSemestre(semestre.id);
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