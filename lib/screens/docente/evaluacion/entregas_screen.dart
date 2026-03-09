import 'package:flutter/material.dart';
import '../../../services/tarea_service.dart';
import '../../../services/gestion_service.dart';
import '../../../models/tarea_model.dart';
import '../../../models/entrega_model.dart';
import '../../../models/materia_model.dart';
import '../../../models/alumno_model.dart';
import 'calificar_screen.dart';

class EntregasScreen extends StatelessWidget {
  final Tarea tarea;
  final Materia materia;

  const EntregasScreen({
    super.key,
    required this.tarea,
    required this.materia,
  });

  @override
  Widget build(BuildContext context) {
    final tareaService = TareaService();
    final gestionService = GestionService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(tarea.nombre),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Alumno>>(
        future: gestionService.getAlumnosPorGrupoFuture(tarea.grupoId),
        builder: (context, alumnosSnapshot) {
          if (alumnosSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final alumnos = alumnosSnapshot.data ?? [];

          if (alumnos.isEmpty) {
            return const Center(
              child: Text('No hay alumnos en este grupo',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return StreamBuilder<List<Entrega>>(
            stream: tareaService.getEntregas(tarea.id),
            builder: (context, entregasSnapshot) {
              final entregas = entregasSnapshot.data ?? [];
              final calificadas =
                  entregas.where((e) => e.estado == 'calificado').length;

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    color:
                        const Color(0xFF1565C0).withValues(alpha: 0.05),
                    child: Text(
                      '$calificadas de ${alumnos.length} calificados',
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
                        final entrega = entregas.cast<Entrega?>()
                            .firstWhere(
                          (e) => e?.alumnoId == alumno.id,
                          orElse: () => null,
                        );

                        return _AlumnoEntregaCard(
                          alumno: alumno,
                          entrega: entrega,
                          onCalificar: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CalificarScreen(
                                tarea: tarea,
                                alumno: alumno,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _AlumnoEntregaCard extends StatelessWidget {
  final Alumno alumno;
  final Entrega? entrega;
  final VoidCallback onCalificar;

  const _AlumnoEntregaCard({
    required this.alumno,
    required this.entrega,
    required this.onCalificar,
  });

  @override
  Widget build(BuildContext context) {
    final bool calificado = entrega?.estado == 'calificado';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: calificado
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          child: Text(
            alumno.nombre.isNotEmpty
                ? alumno.nombre[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: calificado ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          alumno.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          calificado
              ? 'Calificación: ${entrega!.calificacionFinal.toStringAsFixed(1)}'
              : 'Sin calificar',
          style: TextStyle(
            color: calificado ? Colors.green : Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: onCalificar,
          style: ElevatedButton.styleFrom(
            backgroundColor: calificado
                ? Colors.green
                : const Color(0xFF6A1B9A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            calificado ? 'Ver' : 'Calificar',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}