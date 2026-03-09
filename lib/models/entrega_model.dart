class Entrega {
  final String id;
  final String tareaId;
  final String alumnoId;
  final String alumnoNombre;
  final String materiaId;
  final String textoPdf;         // Texto extraído del PDF
  final String nombreArchivo;
  final DateTime fechaEntrega;
  final String estado;           // 'pendiente', 'calificado'
  final Map<String, double> calificacionesIA;   // criterioId → calificación
  final Map<String, String> retroalimentacion;  // criterioId → comentario
  final double calificacionFinal;
  final bool revisadoPorDocente;
  final String comentarioDocente;

  Entrega({
    required this.id,
    required this.tareaId,
    required this.alumnoId,
    required this.alumnoNombre,
    required this.materiaId,
    required this.textoPdf,
    required this.nombreArchivo,
    required this.fechaEntrega,
    required this.estado,
    this.calificacionesIA = const {},
    this.retroalimentacion = const {},
    this.calificacionFinal = 0,
    this.revisadoPorDocente = false,
    this.comentarioDocente = '',
  });

  factory Entrega.fromFirestore(Map<String, dynamic> data, String id) {
    return Entrega(
      id: id,
      tareaId: data['tareaId'] ?? '',
      alumnoId: data['alumnoId'] ?? '',
      alumnoNombre: data['alumnoNombre'] ?? '',
      materiaId: data['materiaId'] ?? '',
      textoPdf: data['textoPdf'] ?? '',
      nombreArchivo: data['nombreArchivo'] ?? '',
      fechaEntrega: DateTime.parse(data['fechaEntrega']),
      estado: data['estado'] ?? 'pendiente',
      calificacionesIA: Map<String, double>.from(
          data['calificacionesIA'] ?? {}),
      retroalimentacion: Map<String, String>.from(
          data['retroalimentacion'] ?? {}),
      calificacionFinal:
          (data['calificacionFinal'] ?? 0).toDouble(),
      revisadoPorDocente: data['revisadoPorDocente'] ?? false,
      comentarioDocente: data['comentarioDocente'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tareaId': tareaId,
      'alumnoId': alumnoId,
      'alumnoNombre': alumnoNombre,
      'materiaId': materiaId,
      'textoPdf': textoPdf,
      'nombreArchivo': nombreArchivo,
      'fechaEntrega': fechaEntrega.toIso8601String(),
      'estado': estado,
      'calificacionesIA': calificacionesIA,
      'retroalimentacion': retroalimentacion,
      'calificacionFinal': calificacionFinal,
      'revisadoPorDocente': revisadoPorDocente,
      'comentarioDocente': comentarioDocente,
    };
  }
}