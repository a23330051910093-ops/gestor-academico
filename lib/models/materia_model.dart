class Materia {
  final String id;
  final String nombre;
  final String grupoId;
  final String semestreId;
  final String docenteId;

  Materia({
    required this.id,
    required this.nombre,
    required this.grupoId,
    required this.semestreId,
    required this.docenteId,
  });

  factory Materia.fromFirestore(Map<String, dynamic> data, String id) {
    return Materia(
      id: id,
      nombre: data['nombre'] ?? '',
      grupoId: data['grupoId'] ?? '',
      semestreId: data['semestreId'] ?? '',
      docenteId: data['docenteId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'grupoId': grupoId,
      'semestreId': semestreId,
      'docenteId': docenteId,
    };
  }
}