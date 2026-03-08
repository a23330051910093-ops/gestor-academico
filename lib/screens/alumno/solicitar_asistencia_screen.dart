import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/asistencia_service.dart';
import '../../services/gestion_service.dart';
import '../../utils/horario_utils.dart';

class SolicitarAsistenciaScreen extends StatefulWidget {
  const SolicitarAsistenciaScreen({super.key});

  @override
  State<SolicitarAsistenciaScreen> createState() =>
      _SolicitarAsistenciaScreenState();
}

class _SolicitarAsistenciaScreenState
    extends State<SolicitarAsistenciaScreen> {
  final AsistenciaService _asistenciaService = AsistenciaService();
  final GestionService _gestionService = GestionService();

  bool _isLoading = false;
  bool _solicitado = false;
  String? _mensaje;
  bool _exito = false;

  @override
  Widget build(BuildContext context) {
    final modulo = HorarioUtils.moduloActual();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Solicitar Asistencia'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info del módulo actual
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.schedule_rounded,
                        color: Color(0xFF1565C0)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          modulo == null
                              ? 'Fuera del horario de clases'
                              : HorarioUtils.descripcionModulo(modulo),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          modulo == null
                              ? 'No hay clase activa en este momento'
                              : 'Clase activa ahora mismo',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: modulo == null ? Colors.grey : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Instrucción
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Usa esta opción solo si no puedes escanear el QR. '
                      'Tu maestro deberá confirmar tu asistencia.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Resultado de la solicitud
            if (_mensaje != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _exito ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _exito
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _exito
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color:
                          _exito ? Colors.green.shade600 : Colors.red.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _mensaje!,
                        style: TextStyle(
                          color: _exito
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Spacer(),

            // Botón solicitar
            if (!_solicitado)
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading || modulo == null
                      ? null
                      : _solicitarAsistencia,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.front_hand_rounded),
                  label: Text(
                    modulo == null
                        ? 'Sin clase activa'
                        : 'Solicitar asistencia',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _solicitarAsistencia() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final alumno =
        await _gestionService.getAlumnoPorUid(authService.currentUser!.uid);

    if (alumno == null) {
      setState(() {
        _mensaje = 'No se encontró tu perfil';
        _exito = false;
        _isLoading = false;
      });
      return;
    }

    // Obtener la primera materia del alumno para la solicitud
    // En una versión futura el alumno elegiría la materia
    if (alumno.grupoIds.isEmpty) {
      setState(() {
        _mensaje = 'No estás inscrito en ningún grupo';
        _exito = false;
        _isLoading = false;
      });
      return;
    }

    final materias =
        await _gestionService.getMateriasPorGrupo(alumno.grupoIds.first);

    if (materias.isEmpty) {
      setState(() {
        _mensaje = 'No hay materias en tu grupo';
        _exito = false;
        _isLoading = false;
      });
      return;
    }

    final error = await _asistenciaService.solicitarAsistenciaManual(
      alumnoId: alumno.id,
      alumnoNombre: alumno.nombre,
      materiaId: materias.first.id,
      grupoId: alumno.grupoIds.first,
    );

    setState(() {
      _isLoading = false;
      if (error != null) {
        _mensaje = error;
        _exito = false;
      } else {
        _mensaje = 'Solicitud enviada. Espera la confirmación de tu maestro.';
        _exito = true;
        _solicitado = true;
      }
    });
  }
}