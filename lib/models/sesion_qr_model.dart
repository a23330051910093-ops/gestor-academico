class SesionQR {
  final String id;
  final String materiaId;
  final String materiaNombre;
  final String grupoId;
  final String docenteId;
  final DateTime fechaCreacion;
  final DateTime fechaExpiracion;
  final bool activo;

  SesionQR({
    required this.id,
    required this.materiaId,
    required this.materiaNombre,
    required this.grupoId,
    required this.docenteId,
    required this.fechaCreacion,
    required this.fechaExpiracion,
    this.activo = true,
  });

  factory SesionQR.fromFirestore(Map<String, dynamic> data, String id) {
    return SesionQR(
      id: id,
      materiaId: data['materiaId'] ?? '',
      materiaNombre: data['materiaNombre'] ?? '',
      grupoId: data['grupoId'] ?? '',
      docenteId: data['docenteId'] ?? '',
      fechaCreacion: DateTime.parse(data['fechaCreacion']),
      fechaExpiracion: DateTime.parse(data['fechaExpiracion']),
      activo: data['activo'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'materiaId': materiaId,
      'materiaNombre': materiaNombre,
      'grupoId': grupoId,
      'docenteId': docenteId,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaExpiracion': fechaExpiracion.toIso8601String(),
      'activo': activo,
    };
  }

  // El QR ya expiró
  bool get estaExpirado => DateTime.now().isAfter(fechaExpiracion);

  // Minutos restantes antes de expirar
  int get minutosRestantes =>
      fechaExpiracion.difference(DateTime.now()).inMinutes;

  // Segundos restantes para el contador
  int get segundosRestantes =>
      fechaExpiracion.difference(DateTime.now()).inSeconds;
}