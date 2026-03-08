import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/gestion_service.dart';
import '../../../services/asistencia_service.dart';
import '../../../models/materia_model.dart';
import '../../../models/grupo_model.dart';
import '../../../models/semestre_model.dart';
import '../../../models/asistencia_model.dart';
import 'qr_screen.dart';
import 'pendientes_screen.dart';

class AsistenciaHome extends StatelessWidget {
  const AsistenciaHome({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final gestionService = GestionService();
    final asistenciaService = AsistenciaService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Control de Asistencia'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<List<Asistencia>>(
            stream: asistenciaService
                .getAsistenciasPendientes(authService.currentUser!.uid),
            builder: (context, snapshot) {
              final pendientes = snapshot.data?.length ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.pending_actions_rounded),
                    tooltip: 'Pendientes',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PendientesScreen(),
                      ),
                    ),
                  ),
                  if (pendientes > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$pendientes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Semestre>>(
        stream: gestionService.getSemestres(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final semestres = snapshot.data ?? [];

          if (semestres.isEmpty) {
            return _EmptyState(
              icono: Icons.calendar_month_outlined,
              mensaje: 'No tienes semestres registrados',
              submensaje: 'Crea un semestre en Gestión Académica primero',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: semestres.length,
            itemBuilder: (context, index) {
              final semestre = semestres[index];
              return _SemestreExpansion(
                semestre: semestre,
                gestionService: gestionService,
              );
            },
          );
        },
      ),
    );
  }
}

// Expansión por semestre que muestra sus grupos y materias
class _SemestreExpansion extends StatelessWidget {
  final Semestre semestre;
  final GestionService gestionService;

  const _SemestreExpansion({
    required this.semestre,
    required this.gestionService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading:
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF1565C0)),
        title: Text(
          semestre.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          StreamBuilder<List<Grupo>>(
            stream: gestionService.getGrupos(semestre.id),
            builder: (context, snapshot) {
              final grupos = snapshot.data ?? [];
              if (grupos.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay grupos en este semestre',
                      style: TextStyle(color: Colors.grey)),
                );
              }
              return Column(
                children: grupos
                    .map((grupo) => _GrupoExpansion(
                          grupo: grupo,
                          gestionService: gestionService,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GrupoExpansion extends StatelessWidget {
  final Grupo grupo;
  final GestionService gestionService;

  const _GrupoExpansion({
    required this.grupo,
    required this.gestionService,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: ExpansionTile(
        leading: const Icon(Icons.group_rounded, color: Color(0xFF2E7D32)),
        title: Text(grupo.nombre),
        children: [
          StreamBuilder<List<Materia>>(
            stream: gestionService.getMaterias(grupo.id),
            builder: (context, snapshot) {
              final materias = snapshot.data ?? [];
              if (materias.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay materias en este grupo',
                      style: TextStyle(color: Colors.grey)),
                );
              }
              return Column(
                children: materias
                    .map((materia) => ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 32),
                          leading: const Icon(Icons.book_rounded,
                              color: Color(0xFF6A1B9A)),
                          title: Text(materia.nombre),
                          subtitle:
                              const Text('Toca para tomar asistencia'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QRScreen(
                                materia: materia,
                                grupo: grupo,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icono;
  final String mensaje;
  final String submensaje;

  const _EmptyState({
    required this.icono,
    required this.mensaje,
    required this.submensaje,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(mensaje,
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              submensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}