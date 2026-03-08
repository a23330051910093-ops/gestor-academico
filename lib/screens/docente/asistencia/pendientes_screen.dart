import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/asistencia_service.dart';
import '../../../models/asistencia_model.dart';

class PendientesScreen extends StatelessWidget {
  const PendientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final asistenciaService = AsistenciaService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Asistencias Pendientes'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Asistencia>>(
        stream: asistenciaService
            .getAsistenciasPendientes(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pendientes = snapshot.data ?? [];

          if (pendientes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Sin pendientes',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No hay solicitudes de asistencia pendientes',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: Colors.orange.withValues(alpha: 0.1),
                child: Text(
                  '${pendientes.length} solicitud${pendientes.length != 1 ? 'es' : ''} pendiente${pendientes.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendientes.length,
                  itemBuilder: (context, index) {
                    final asistencia = pendientes[index];
                    return _PendienteCard(
                      asistencia: asistencia,
                      asistenciaService: asistenciaService,
                    );
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

class _PendienteCard extends StatelessWidget {
  final Asistencia asistencia;
  final AsistenciaService asistenciaService;

  const _PendienteCard({
    required this.asistencia,
    required this.asistenciaService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Colors.orange.withValues(alpha: 0.1),
                  child: Text(
                    asistencia.alumnoNombre.isNotEmpty
                        ? asistencia.alumnoNombre[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asistencia.alumnoNombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        asistencia.numeroModulo == 0
                            ? 'Solicitud manual'
                            : 'Módulo ${asistencia.numeroModulo}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    '${asistencia.fecha.hour}:${asistencia.fecha.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rechazar(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmar(context),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Confirmar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmar(BuildContext context) async {
    await asistenciaService.confirmarAsistencia(asistencia.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Asistencia de ${asistencia.alumnoNombre} confirmada'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _rechazar(BuildContext context) async {
    await asistenciaService.rechazarAsistencia(asistencia.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Asistencia de ${asistencia.alumnoNombre} rechazada'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}