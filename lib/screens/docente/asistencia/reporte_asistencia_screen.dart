import 'package:flutter/material.dart';
import '../../../services/asistencia_service.dart';
import '../../../services/gestion_service.dart';
import '../../../models/materia_model.dart';
import '../../../models/grupo_model.dart';
import '../../../models/alumno_model.dart';

class ReporteAsistenciaScreen extends StatefulWidget {
  final Materia materia;
  final Grupo grupo;

  const ReporteAsistenciaScreen({
    super.key,
    required this.materia,
    required this.grupo,
  });

  @override
  State<ReporteAsistenciaScreen> createState() =>
      _ReporteAsistenciaScreenState();
}

class _ReporteAsistenciaScreenState extends State<ReporteAsistenciaScreen> {
  final AsistenciaService _asistenciaService = AsistenciaService();
  final GestionService _gestionService = GestionService();

  List<Alumno> _alumnos = [];
  Map<String, double> _porcentajes = {};
  bool _cargando = true;

  // Umbral mínimo de asistencia (80%)
  static const double umbralRiesgo = 80.0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    // Obtener alumnos del grupo
    final alumnos = await _gestionService
        .getAlumnosPorGrupoFuture(widget.grupo.id);

    if (alumnos.isEmpty) {
      setState(() => _cargando = false);
      return;
    }

    // Calcular porcentajes de todos
    final ids = alumnos.map((a) => a.id).toList();
    final porcentajes = await _asistenciaService
        .calcularPorcentajesGrupo(widget.materia.id, ids);

    setState(() {
      _alumnos = alumnos;
      _porcentajes = porcentajes;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final enRiesgo = _alumnos
        .where((a) => (_porcentajes[a.id] ?? 0) < umbralRiesgo)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Asistencia — ${widget.materia.nombre}'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _alumnos.isEmpty
              ? const Center(
                  child: Text(
                    'No hay alumnos en este grupo',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    // ─── Resumen del grupo ───────────────
                    _ResumenGrupo(
                      totalAlumnos: _alumnos.length,
                      enRiesgo: enRiesgo,
                      promedioGrupo: _porcentajes.isEmpty
                          ? 0
                          : _porcentajes.values.reduce((a, b) => a + b) /
                              _porcentajes.length,
                    ),

                    // ─── Alerta si hay alumnos en riesgo ─
                    if (enRiesgo > 0)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_rounded,
                                color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$enRiesgo alumno${enRiesgo != 1 ? 's' : ''} '
                                'con menos del 80% de asistencia',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ─── Lista de alumnos ─────────────────
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _alumnos.length,
                        itemBuilder: (context, index) {
                          final alumno = _alumnos[index];
                          final porcentaje = _porcentajes[alumno.id] ?? 0;
                          return _AlumnoPorcentajeCard(
                            alumno: alumno,
                            porcentaje: porcentaje,
                            enRiesgo: porcentaje < umbralRiesgo,
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ResumenGrupo extends StatelessWidget {
  final int totalAlumnos;
  final int enRiesgo;
  final double promedioGrupo;

  const _ResumenGrupo({
    required this.totalAlumnos,
    required this.enRiesgo,
    required this.promedioGrupo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _StatItem(
            valor: '$totalAlumnos',
            etiqueta: 'Total\nalumnos',
            icono: Icons.people_rounded,
          ),
          const SizedBox(width: 16),
          _StatItem(
            valor: '${promedioGrupo.toStringAsFixed(1)}%',
            etiqueta: 'Promedio\ngrupo',
            icono: Icons.bar_chart_rounded,
          ),
          const SizedBox(width: 16),
          _StatItem(
            valor: '$enRiesgo',
            etiqueta: 'En\nriesgo',
            icono: Icons.warning_rounded,
            color: enRiesgo > 0 ? Colors.orange.shade300 : Colors.white,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final IconData icono;
  final Color? color;

  const _StatItem({
    required this.valor,
    required this.etiqueta,
    required this.icono,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icono, color: color ?? Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlumnoPorcentajeCard extends StatelessWidget {
  final Alumno alumno;
  final double porcentaje;
  final bool enRiesgo;

  const _AlumnoPorcentajeCard({
    required this.alumno,
    required this.porcentaje,
    required this.enRiesgo,
  });

  @override
  Widget build(BuildContext context) {
    final Color colorPorcentaje = porcentaje >= 90
        ? Colors.green
        : porcentaje >= 80
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar con inicial
            CircleAvatar(
              backgroundColor: colorPorcentaje.withValues(alpha: 0.1),
              child: Text(
                alumno.nombre.isNotEmpty
                    ? alumno.nombre[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: colorPorcentaje,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Nombre y barra de progreso
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alumno.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (enRiesgo)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            '⚠ Riesgo',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Barra de progreso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: porcentaje / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorPorcentaje),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Porcentaje
            Text(
              '${porcentaje.toStringAsFixed(0)}%',
              style: TextStyle(
                color: colorPorcentaje,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}