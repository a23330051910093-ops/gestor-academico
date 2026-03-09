import 'package:flutter/material.dart';
import '../../../services/tarea_service.dart';
import '../../../models/tarea_model.dart';
import '../../../models/entrega_model.dart';
import '../../../models/materia_model.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(tarea.nombre),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Entrega>>(
        stream: tareaService.getEntregas(tarea.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entregas = snapshot.data ?? [];

          if (entregas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Sin entregas todavía',
                      style:
                          TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    'Rúbrica: ${tarea.rubricaNombre}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final calificadas =
              entregas.where((e) => e.estado == 'calificado').length;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: const Color(0xFF1565C0).withValues(alpha: 0.05),
                child: Text(
                  '$calificadas de ${entregas.length} calificadas',
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entregas.length,
                  itemBuilder: (context, index) {
                    final entrega = entregas[index];
                    return _EntregaCard(entrega: entrega);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EntregaCard extends StatelessWidget {
  final Entrega entrega;

  const _EntregaCard({required this.entrega});

  @override
  Widget build(BuildContext context) {
    final bool calificada = entrega.estado == 'calificado';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: calificada
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          child: Icon(
            calificada
                ? Icons.check_circle_rounded
                : Icons.hourglass_empty_rounded,
            color: calificada ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          entrega.alumnoNombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          calificada
              ? 'Calificación: ${entrega.calificacionFinal.toStringAsFixed(1)}'
              : 'Pendiente de calificar',
          style: TextStyle(
            color: calificada ? Colors.green : Colors.orange,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          entrega.nombreArchivo,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}