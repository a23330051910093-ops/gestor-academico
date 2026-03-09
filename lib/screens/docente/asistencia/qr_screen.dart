import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../../../services/auth_service.dart';
import '../../../services/asistencia_service.dart';
import '../../../models/materia_model.dart';
import '../../../models/grupo_model.dart';
import '../../../models/sesion_qr_model.dart';
import '../../../models/asistencia_model.dart';
import 'reporte_asistencia_screen.dart';

class QRScreen extends StatefulWidget {
  final Materia materia;
  final Grupo grupo;

  const QRScreen({
    super.key,
    required this.materia,
    required this.grupo,
  });

  @override
  State<QRScreen> createState() => _QRScreenState();
}

class _QRScreenState extends State<QRScreen> {
  final AsistenciaService _asistenciaService = AsistenciaService();

  SesionQR? _sesionActual;
  bool _generando = false;
  Timer? _timer;
  int _segundosRestantes = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _generarQR() async {
    setState(() => _generando = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    final sesion = await _asistenciaService.crearSesionQR(
      materiaId: widget.materia.id,
      materiaNombre: widget.materia.nombre,
      grupoId: widget.grupo.id,
      docenteId: authService.currentUser!.uid,
      minutosQR: 10,
    );

    if (sesion == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fuera del horario de clases'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() => _generando = false);
      return;
    }

    setState(() {
      _sesionActual = sesion;
      _segundosRestantes = sesion.segundosRestantes;
      _generando = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _segundosRestantes = _sesionActual?.segundosRestantes ?? 0;
        if (_segundosRestantes <= 0) timer.cancel();
      });
    });
  }

  Future<void> _cerrarSesion() async {
    if (_sesionActual == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión de asistencia'),
        content: const Text(
            '¿Deseas cerrar la sesión? Los alumnos que no escanearon quedarán como ausentes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _asistenciaService.cerrarSesionQR(_sesionActual!.id);
      _timer?.cancel();
      setState(() {
        _sesionActual = null;
        _segundosRestantes = 0;
      });
    }
  }

  String _formatearTiempo(int segundos) {
    if (segundos <= 0) return '00:00';
    final minutos = segundos ~/ 60;
    final segs = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool qrExpirado =
        _sesionActual != null && _segundosRestantes <= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.materia.nombre),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment_rounded),
            tooltip: 'Ver porcentajes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReporteAsistenciaScreen(
                  materia: widget.materia,
                  grupo: widget.grupo,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Grupo ${widget.grupo.nombre}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fechaHoy(),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),

                  if (_sesionActual != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _sesionActual!.numeroModulo == 0
                            ? 'Modo de prueba'
                            : 'Módulo ${_sesionActual!.numeroModulo}',
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  if (_sesionActual == null) ...[
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey.shade300, width: 2),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2_rounded,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Sin sesión activa',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ] else if (qrExpirado) ...[
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_off_rounded,
                              size: 64, color: Colors.red.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'QR Expirado',
                            style: TextStyle(color: Colors.red.shade600),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Genera uno nuevo',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    QrImageView(
                      data: _sesionActual!.id,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _segundosRestantes > 60
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _segundosRestantes > 60
                              ? Colors.green.shade200
                              : Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_rounded,
                            size: 18,
                            color: _segundosRestantes > 60
                                ? Colors.green.shade600
                                : Colors.orange.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Expira en ${_formatearTiempo(_segundosRestantes)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _segundosRestantes > 60
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generando ? null : _generarQR,
                    icon: _generando
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.qr_code_rounded),
                    label: Text(
                      _sesionActual == null || qrExpirado
                          ? 'Generar QR'
                          : 'Regenerar QR',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_sesionActual != null && !qrExpirado) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _cerrarSesion,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Cerrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            _AsistenciasHoy(
              materiaId: widget.materia.id,
              asistenciaService: _asistenciaService,
            ),
          ],
        ),
      ),
    );
  }

  String _fechaHoy() {
    final ahora = DateTime.now();
    const meses = [
      'enero','febrero','marzo','abril','mayo','junio',
      'julio','agosto','septiembre','octubre','noviembre','diciembre'
    ];
    return '${ahora.day} de ${meses[ahora.month - 1]} de ${ahora.year}';
  }
}

class _AsistenciasHoy extends StatelessWidget {
  final String materiaId;
  final AsistenciaService asistenciaService;

  const _AsistenciasHoy({
    required this.materiaId,
    required this.asistenciaService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Asistencia>>(
      stream: asistenciaService.getAsistenciasHoy(materiaId),
      builder: (context, snapshot) {
        final asistencias = snapshot.data ?? [];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.people_rounded,
                        color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    Text(
                      'Presentes hoy: ${asistencias.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (asistencias.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'Ningún alumno ha registrado asistencia todavía',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: asistencias.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final asistencia = asistencias[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            Colors.green.withValues(alpha: 0.1),
                        child: const Icon(Icons.check,
                            color: Colors.green, size: 16),
                      ),
                      title: Text(
                        asistencia.alumnoNombre,
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: Text(
                        '${asistencia.fecha.hour}:${asistencia.fecha.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
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
}