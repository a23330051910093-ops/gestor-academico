import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/asistencia_service.dart';
import '../../services/gestion_service.dart';
import '../../models/asistencia_model.dart';
import '../../models/materia_model.dart';

class MiAsistenciaScreen extends StatelessWidget {
  final String? alumnoIdOverride; // ← nuevo parámetro

  const MiAsistenciaScreen({super.key, this.alumnoIdOverride});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final gestionService = GestionService();
    final asistenciaService = AsistenciaService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mi Asistencia'),
        backgroundColor: const Color(0xFF1565C0),
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
            future:
                gestionService.getMateriasPorGrupo(alumno.grupoIds.first),
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
                  final materia = materias[index];
                  return _MateriaAsistenciaCard(
                    materia: materia,
                    alumnoId: alumno.id,
                    asistenciaService: asistenciaService,
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

class _MateriaAsistenciaCard extends StatelessWidget {
  final Materia materia;
  final String alumnoId;
  final AsistenciaService asistenciaService;

  const _MateriaAsistenciaCard({
    required this.materia,
    required this.alumnoId,
    required this.asistenciaService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: asistenciaService.calcularPorcentaje(alumnoId, materia.id),
      builder: (context, snapshot) {
        final porcentaje = snapshot.data ?? 0.0;
        final Color color = porcentaje >= 90
            ? Colors.green
            : porcentaje >= 80
                ? Colors.orange
                : Colors.red;
        final bool enRiesgo = porcentaje < 80 && snapshot.hasData;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.book_rounded, color: color, size: 20),
            ),
            title: Text(
              materia.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: porcentaje / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${porcentaje.toStringAsFixed(0)}% de asistencia',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (enRiesgo) ...[
                      const SizedBox(width: 8),
                      Text(
                        '⚠ En riesgo',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            children: [
              StreamBuilder<List<Asistencia>>(
                stream: asistenciaService.getAsistenciasAlumno(
                    alumnoId, materia.id),
                builder: (context, snapshot) {
                  final asistencias = snapshot.data ?? [];

                  if (asistencias.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Sin registros de asistencia',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: asistencias.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final a = asistencias[index];
                      final esPresente = a.estado == 'presente';

                      return ListTile(
                        dense: true,
                        leading: Icon(
                          esPresente
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: esPresente ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        title: Text(
                          '${a.fecha.day}/${a.fecha.month}/${a.fecha.year}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          a.metodo == 'qr'
                              ? 'Módulo ${a.numeroModulo} — QR'
                              : 'Módulo ${a.numeroModulo} — Manual',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: esPresente
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            esPresente ? 'Presente' : 'Ausente',
                            style: TextStyle(
                              color: esPresente
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}