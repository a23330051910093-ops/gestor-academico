class Alumno {
  final String id;
  final String nombre;
  final String matricula;
  final String correo;
  final String docenteId;
  final List<String> grupoIds;

  Alumno({
    required this.id,
    required this.nombre,
    required this.matricula,
    required this.correo,
    required this.docenteId,
    this.grupoIds = const [],
  });

  factory Alumno.fromFirestore(Map<String, dynamic> data, String id) {
    return Alumno(
      id: id,
      nombre: data['nombre'] ?? '',
      matricula: data['matricula'] ?? '',
      correo: data['correo'] ?? '',
      docenteId: data['docenteId'] ?? '',
      grupoIds: List<String>.from(data['grupoIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'matricula': matricula,
      'correo': correo,
      'docenteId': docenteId,
      'grupoIds': grupoIds,
    };
  }
}