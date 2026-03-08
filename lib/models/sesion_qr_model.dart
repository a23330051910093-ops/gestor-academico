class SesionQR {
  final String id;
  final String materiaId;
  final String materiaNombre;
  final String grupoId;
  final String docenteId;
  final DateTime fechaCreacion;
  final DateTime fechaExpiracion;     // Cuándo expira el QR actual
  final DateTime finModulo;           // Cuándo termina el módulo/clase
  final int numeroModulo;             // Qué módulo es (1-16)
  final bool activo;

  SesionQR({
    required this.id,
    required this.materiaId,
    required this.materiaNombre,
    required this.grupoId,
    required this.docenteId,
    required this.fechaCreacion,
    required this.fechaExpiracion,
    required this.finModulo,
    required this.numeroModulo,
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
      finModulo: DateTime.parse(data['finModulo']),
      numeroModulo: data['numeroModulo'] ?? 0,
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
      'finModulo': finModulo.toIso8601String(),
      'numeroModulo': numeroModulo,
      'activo': activo,
    };
  }

  // El QR actual expiró (pero la sesión puede seguir abierta)
  bool get qrExpirado => DateTime.now().isAfter(fechaExpiracion);

  // El módulo completo terminó
  bool get moduloTerminado => DateTime.now().isAfter(finModulo);

  // Segundos restantes del QR actual
  int get segundosRestantes =>
      fechaExpiracion.difference(DateTime.now()).inSeconds;
}