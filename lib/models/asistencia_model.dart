class Asistencia {
  final String id;
  final String alumnoId;
  final String alumnoNombre;
  final String materiaId;
  final String grupoId;
  final DateTime fecha;
  final String metodo; // 'qr' o 'manual'
  final String estado; // 'presente', 'ausente', 'pendiente'
  final bool validadoPorDocente;

  Asistencia({
    required this.id,
    required this.alumnoId,
    required this.alumnoNombre,
    required this.materiaId,
    required this.grupoId,
    required this.fecha,
    required this.metodo,
    required this.estado,
    this.validadoPorDocente = false,
  });

  factory Asistencia.fromFirestore(Map<String, dynamic> data, String id) {
    return Asistencia(
      id: id,
      alumnoId: data['alumnoId'] ?? '',
      alumnoNombre: data['alumnoNombre'] ?? '',
      materiaId: data['materiaId'] ?? '',
      grupoId: data['grupoId'] ?? '',
      fecha: DateTime.parse(data['fecha']),
      metodo: data['metodo'] ?? 'manual',
      estado: data['estado'] ?? 'ausente',
      validadoPorDocente: data['validadoPorDocente'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'alumnoId': alumnoId,
      'alumnoNombre': alumnoNombre,
      'materiaId': materiaId,
      'grupoId': grupoId,
      'fecha': fecha.toIso8601String(),
      'metodo': metodo,
      'estado': estado,
      'validadoPorDocente': validadoPorDocente,
    };
  }
}