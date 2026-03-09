import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/tarea_service.dart';
import '../../services/gestion_service.dart';
import '../../services/rubrica_service.dart';
import '../../models/entrega_model.dart';
import '../../models/materia_model.dart';
import '../../models/tarea_model.dart';
import '../../models/rubrica_model.dart';

class MisCalificacionesScreen extends StatelessWidget {
  final String? alumnoIdOverride;

  const MisCalificacionesScreen({super.key, this.alumnoIdOverride});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final gestionService = GestionService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mis Calificaciones'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: alumnoIdOverride != null
            ? gestionService.getAlumnoPorId(alumnoIdOverride!)
            : gestionService.getAlumnoPorUid(authService.currentUser!.uid),
        builder: (context, alumnoSnapshot) {
          if (alumnoSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final alumno = alumnoSnapshot.data;
          if (alumno == null) {
            return const Center(
              child: Text(
                'No se encontró tu perfil',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          if (alumno.grupoIds.isEmpty) {
            return const Center(
              child: Text(
                'No estás inscrito en ningún grupo',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return FutureBuilder<List<Materia>>(
            future: gestionService.getMateriasPorGrupo(alumno.grupoIds.first),
            builder: (context, materiasSnapshot) {
              if (materiasSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final materias = materiasSnapshot.data ?? [];

              if (materias.isEmpty) {
                return const Center(
                  child: Text(
                    'No hay materias registradas',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: materias.length,
                itemBuilder: (context, index) {
                  return _MateriaCalificaciones(
                    materia: materias[index],
                    alumnoId: alumno.id,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _MateriaCalificaciones extends StatelessWidget {
  final Materia materia;
  final String alumnoId;

  const _MateriaCalificaciones({
    required this.materia,
    required this.alumnoId,
  });

  @override
  Widget build(BuildContext context) {
    final tareaService = TareaService();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              const Icon(Icons.book_rounded, color: Color(0xFF6A1B9A), size: 20),
        ),
        title: Text(
          materia.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          StreamBuilder<List<Entrega>>(
            stream: tareaService.getEntregasAlumno(alumnoId, materia.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final entregas = snapshot.data ?? [];

              if (entregas.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Sin calificaciones en esta materia todavía',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                );
              }

              return Column(
                children:
                    entregas.map((e) => _EntregaDetalle(entrega: e)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EntregaDetalle extends StatelessWidget {
  final Entrega entrega;

  const _EntregaDetalle({required this.entrega});

  Color get _colorCalificacion {
    if (entrega.calificacionFinal >= 8) return Colors.green;
    if (entrega.calificacionFinal >= 6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final rubricaService = RubricaService();
    final tareaService = TareaService();

    return FutureBuilder<Tarea?>(
      future: _getTarea(tareaService, entrega.tareaId),
      builder: (context, tareaSnapshot) {
        final tarea = tareaSnapshot.data;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _colorCalificacion.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entrega.calificacionFinal.toStringAsFixed(1),
                style: TextStyle(
                  color: _colorCalificacion,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            title: Text(
              tarea?.nombre ?? 'Cargando...',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${entrega.fechaEntrega.day}/${entrega.fechaEntrega.month}/${entrega.fechaEntrega.year}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            children: [
              if (tarea != null)
                FutureBuilder<Rubrica?>(
                  future: rubricaService.getRubricaPorId(tarea.rubricaId),
                  builder: (context, rubricaSnapshot) {
                    final rubrica = rubricaSnapshot.data;
                    if (rubrica == null) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...rubrica.criterios.map((criterio) {
                            final cal =
                                entrega.calificacionesIA[criterio.id] ?? 0;
                            final retro =
                                entrega.retroalimentacion[criterio.id] ?? '';

                            final colorCal = cal >= 8
                                ? Colors.green
                                : cal >= 6
                                    ? Colors.orange
                                    : Colors.red;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          criterio.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colorCal.withValues(
                                              alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${cal.toStringAsFixed(1)}/10',
                                          style: TextStyle(
                                            color: colorCal,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (retro.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      retro,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),

                          if (entrega.comentarioDocente.isNotEmpty) ...[
                            const Divider(),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Comentario general:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entrega.comentarioDocente,
                                    style:
                                        const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<Tarea?> _getTarea(
      TareaService service, String tareaId) async {
    try {
      final doc = await service.getTareaPorId(tareaId);
      return doc;
    } catch (e) {
      return null;
    }
  }
}