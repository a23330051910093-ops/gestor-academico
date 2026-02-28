class Semestre {
  final String id;
  final String nombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String docenteId;
  final bool activo;

  Semestre({
    required this.id,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.docenteId,
    this.activo = true,
  });

  // Convierte un documento de Firestore en un objeto Semestre
  factory Semestre.fromFirestore(Map<String, dynamic> data, String id) {
    return Semestre(
      id: id,
      nombre: data['nombre'] ?? '',
      fechaInicio: DateTime.parse(data['fechaInicio']),
      fechaFin: DateTime.parse(data['fechaFin']),
      docenteId: data['docenteId'] ?? '',
      activo: data['activo'] ?? true,
    );
  }

  // Convierte un objeto Semestre en un Map para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'docenteId': docenteId,
      'activo': activo,
    };
  }
}