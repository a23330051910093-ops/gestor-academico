class Asistencia {
  final String id;
  final String alumnoId;
  final String alumnoNombre;
  final String materiaId;
  final String grupoId;
  final String sesionId;
  final DateTime fecha;
  final String metodo;
  final String estado;
  final bool validadoPorDocente;
  final int numeroModulo;       // ← nuevo
  final DateTime? finModulo;    // ← nuevo

  Asistencia({
    required this.id,
    required this.alumnoId,
    required this.alumnoNombre,
    required this.materiaId,
    required this.grupoId,
    required this.sesionId,
    required this.fecha,
    required this.metodo,
    required this.estado,
    this.validadoPorDocente = false,
    this.numeroModulo = 0,
    this.finModulo,
  });

  factory Asistencia.fromFirestore(Map<String, dynamic> data, String id) {
    return Asistencia(
      id: id,
      alumnoId: data['alumnoId'] ?? '',
      alumnoNombre: data['alumnoNombre'] ?? '',
      materiaId: data['materiaId'] ?? '',
      grupoId: data['grupoId'] ?? '',
      sesionId: data['sesionId'] ?? '',
      fecha: DateTime.parse(data['fecha']),
      metodo: data['metodo'] ?? 'manual',
      estado: data['estado'] ?? 'ausente',
      validadoPorDocente: data['validadoPorDocente'] ?? false,
      numeroModulo: data['numeroModulo'] ?? 0,
      finModulo: data['finModulo'] != null
          ? DateTime.parse(data['finModulo'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'alumnoId': alumnoId,
      'alumnoNombre': alumnoNombre,
      'materiaId': materiaId,
      'grupoId': grupoId,
      'sesionId': sesionId,
      'fecha': fecha.toIso8601String(),
      'metodo': metodo,
      'estado': estado,
      'validadoPorDocente': validadoPorDocente,
      'numeroModulo': numeroModulo,
      'finModulo': finModulo?.toIso8601String(),
    };
  }
}