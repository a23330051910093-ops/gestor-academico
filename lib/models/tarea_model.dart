class Tarea {
  final String id;
  final String nombre;
  final String descripcion;
  final String materiaId;
  final String grupoId;
  final String docenteId;
  final String rubricaId;
  final String rubricaNombre;
  final DateTime fechaCreacion;
  final DateTime? fechaLimite;

  Tarea({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.materiaId,
    required this.grupoId,
    required this.docenteId,
    required this.rubricaId,
    required this.rubricaNombre,
    required this.fechaCreacion,
    this.fechaLimite,
  });

  factory Tarea.fromFirestore(Map<String, dynamic> data, String id) {
    return Tarea(
      id: id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      materiaId: data['materiaId'] ?? '',
      grupoId: data['grupoId'] ?? '',
      docenteId: data['docenteId'] ?? '',
      rubricaId: data['rubricaId'] ?? '',
      rubricaNombre: data['rubricaNombre'] ?? '',
      fechaCreacion: DateTime.parse(data['fechaCreacion']),
      fechaLimite: data['fechaLimite'] != null
          ? DateTime.parse(data['fechaLimite'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'materiaId': materiaId,
      'grupoId': grupoId,
      'docenteId': docenteId,
      'rubricaId': rubricaId,
      'rubricaNombre': rubricaNombre,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaLimite': fechaLimite?.toIso8601String(),
    };
  }
}