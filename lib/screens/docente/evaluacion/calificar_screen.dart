import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/tarea_service.dart';
import '../../../services/rubrica_service.dart';
import '../../../services/ia_service.dart';
import '../../../models/tarea_model.dart';
import '../../../models/entrega_model.dart';
import '../../../models/rubrica_model.dart';
import '../../../models/alumno_model.dart';

class CalificarScreen extends StatefulWidget {
  final Tarea tarea;
  final Alumno alumno;

  const CalificarScreen({
    super.key,
    required this.tarea,
    required this.alumno,
  });

  @override
  State<CalificarScreen> createState() => _CalificarScreenState();
}

class _CalificarScreenState extends State<CalificarScreen> {
  final TareaService _tareaService = TareaService();
  final RubricaService _rubricaService = RubricaService();
  final IAService _iaService = IAService();

  Rubrica? _rubrica;
  String? _textoPdf;
  String? _nombreArchivo;

  // Resultados de la IA
  Map<String, double> _calificacionesIA = {};
  Map<String, String> _retroalimentacion = {};
  String _comentarioGeneral = '';

  // Controladores para que el maestro edite las calificaciones
  Map<String, TextEditingController> _calControllers = {};

  bool _cargandoRubrica = true;
  bool _subiendoPdf = false;
  bool _calificando = false;
  bool _guardando = false;
  bool _iaCompleto = false;

  @override
  void initState() {
    super.initState();
    _cargarRubrica();
  }

  @override
  void dispose() {
    for (final c in _calControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarRubrica() async {
    final rubricas = await _rubricaService
        .getRubricas(widget.tarea.materiaId)
        .first;

    final rubrica = rubricas.cast<Rubrica?>().firstWhere(
          (r) => r?.id == widget.tarea.rubricaId,
          orElse: () => null,
        );

    setState(() {
      _rubrica = rubrica;
      _cargandoRubrica = false;
    });
  }

  Future<void> _seleccionarPDF() async {
    setState(() => _subiendoPdf = true);

    final resultado = await _tareaService.seleccionarYExtraerPDF();

    if (resultado == null) {
      setState(() => _subiendoPdf = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo leer el PDF. Verifica el archivo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _textoPdf = resultado['texto'];
      _nombreArchivo = resultado['nombre'];
      _subiendoPdf = false;
      _iaCompleto = false;
      _calificacionesIA = {};
      _retroalimentacion = {};
    });
  }

  Future<void> _calificarConIA() async {
    if (_textoPdf == null || _rubrica == null) return;

    setState(() => _calificando = true);

    final resultado = await _iaService.calificarConRubrica(
      textoPdf: _textoPdf!,
      rubrica: _rubrica!,
    );

    if (resultado == null) {
      setState(() => _calificando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Error al conectar con la IA. Verifica tu API key.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Parsear resultado de la IA
    final criteriosResult =
        resultado['criterios'] as Map<String, dynamic>;
    final Map<String, double> califs = {};
    final Map<String, String> retros = {};

    for (final criterio in _rubrica!.criterios) {
      final data = criteriosResult[criterio.id];
      if (data != null) {
        califs[criterio.id] =
            (data['calificacion'] as num).toDouble();
        retros[criterio.id] =
            data['comentario'] as String? ?? '';
      }
    }

    // Inicializar controladores para edición
    final controllers = <String, TextEditingController>{};
    for (final criterio in _rubrica!.criterios) {
      controllers[criterio.id] = TextEditingController(
        text: (califs[criterio.id] ?? 0).toStringAsFixed(1),
      );
    }

    setState(() {
      _calificacionesIA = califs;
      _retroalimentacion = retros;
      _comentarioGeneral =
          resultado['comentarioGeneral'] as String? ?? '';
      _calControllers = controllers;
      _calificando = false;
      _iaCompleto = true;
    });
  }

  // Calificación final ponderada
  double get _calificacionFinal {
    if (_rubrica == null || _calificacionesIA.isEmpty) return 0;
    double total = 0;
    for (final criterio in _rubrica!.criterios) {
      final cal = double.tryParse(
              _calControllers[criterio.id]?.text ?? '0') ??
          0;
      total += cal * (criterio.peso / 100);
    }
    return total;
  }

  Future<void> _publicarCalificacion() async {
    if (_rubrica == null || !_iaCompleto) return;

    setState(() => _guardando = true);

    // Recoger calificaciones editadas por el maestro
    final calificacionesFinales = <String, double>{};
    for (final criterio in _rubrica!.criterios) {
      calificacionesFinales[criterio.id] =
          double.tryParse(
                  _calControllers[criterio.id]?.text ?? '0') ??
              0;
    }

    final entrega = Entrega(
      id: '',
      tareaId: widget.tarea.id,
      alumnoId: widget.alumno.id,
      alumnoNombre: widget.alumno.nombre,
      materiaId: widget.tarea.materiaId,
      textoPdf: _textoPdf ?? '',
      nombreArchivo: _nombreArchivo ?? '',
      fechaEntrega: DateTime.now(),
      estado: 'calificado',
      calificacionesIA: calificacionesFinales,
      retroalimentacion: _retroalimentacion,
      calificacionFinal: _calificacionFinal,
      revisadoPorDocente: true,
      comentarioDocente: _comentarioGeneral,
    );

    await _tareaService.guardarEntrega(entrega);

    setState(() => _guardando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Calificación de ${widget.alumno.nombre} publicada'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.alumno.nombre),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _cargandoRubrica
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Info de la tarea ──────────────────
                  _InfoCard(
                    titulo: widget.tarea.nombre,
                    subtitulo:
                        'Rúbrica: ${widget.tarea.rubricaNombre}',
                  ),
                  const SizedBox(height: 16),

                  // ─── Subir PDF ─────────────────────────
                  _SeccionCard(
                    titulo: '1. Subir trabajo del alumno',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_nombreArchivo != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.picture_as_pdf,
                                    color: Colors.red.shade400),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _nombreArchivo!,
                                    style: const TextStyle(
                                        fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(Icons.check_circle,
                                    color: Colors.green.shade600,
                                    size: 18),
                              ],
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed:
                              _subiendoPdf ? null : _seleccionarPDF,
                          icon: _subiendoPdf
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.upload_file_rounded),
                          label: Text(_nombreArchivo == null
                              ? 'Seleccionar PDF'
                              : 'Cambiar PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Calificar con IA ──────────────────
                  if (_textoPdf != null) ...[
                    _SeccionCard(
                      titulo: '2. Calificar con IA',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_iaCompleto)
                            ElevatedButton.icon(
                              onPressed: _calificando
                                  ? null
                                  : _calificarConIA,
                              icon: _calificando
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.auto_awesome_rounded),
                              label: Text(_calificando
                                  ? 'Analizando con IA...'
                                  : 'Calificar con IA'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF6A1B9A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          if (_iaCompleto) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green.shade600,
                                      size: 18),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'IA completada. Puedes editar las calificaciones.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ─── Resultados por criterio ───────────
                  if (_iaCompleto && _rubrica != null) ...[
                    _SeccionCard(
                      titulo: '3. Revisar y ajustar calificaciones',
                      child: Column(
                        children: [
                          ..._rubrica!.criterios.map((criterio) {
                            return _CriterioCalificacion(
                              criterio: criterio,
                              controller:
                                  _calControllers[criterio.id]!,
                              retroalimentacion:
                                  _retroalimentacion[criterio.id] ??
                                      '',
                              onChanged: () => setState(() {}),
                            );
                          }),
                          const Divider(height: 24),

                          // Calificación final
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Calificación final:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _colorCalificacion(
                                          _calificacionFinal)
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _calificacionFinal
                                      .toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _colorCalificacion(
                                        _calificacionFinal),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_comentarioGeneral.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Comentario general de la IA:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _comentarioGeneral,
                                    style: const TextStyle(
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Publicar ──────────────────────
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed:
                            _guardando ? null : _publicarCalificacion,
                        icon: _guardando
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.publish_rounded),
                        label: const Text('Publicar calificación'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Color _colorCalificacion(double cal) {
    if (cal >= 8) return Colors.green;
    if (cal >= 6) return Colors.orange;
    return Colors.red;
  }
}

// Widgets auxiliares

class _InfoCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;

  const _InfoCard({required this.titulo, required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: const TextStyle(
                color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SeccionCard extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _SeccionCard({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CriterioCalificacion extends StatelessWidget {
  final CriterioRubrica criterio;
  final TextEditingController controller;
  final String retroalimentacion;
  final VoidCallback onChanged;

  const _CriterioCalificacion({
    required this.criterio,
    required this.controller,
    required this.retroalimentacion,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      criterio.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Peso: ${criterio.peso}%',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Campo editable de calificación
              SizedBox(
                width: 70,
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  textAlign: TextAlign.center,
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    suffixText: '/10',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (retroalimentacion.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              retroalimentacion,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black87),
            ),
          ],
        ],
      ),
    );
  }
}