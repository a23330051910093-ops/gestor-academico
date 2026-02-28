class Grupo {
  final String id;
  final String nombre;
  final String grado;
  final String semestreId;
  final String docenteId;

  Grupo({
    required this.id,
    required this.nombre,
    required this.grado,
    required this.semestreId,
    required this.docenteId,
  });

  factory Grupo.fromFirestore(Map<String, dynamic> data, String id) {
    return Grupo(
      id: id,
      nombre: data['nombre'] ?? '',
      grado: data['grado'] ?? '',
      semestreId: data['semestreId'] ?? '',
      docenteId: data['docenteId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'grado': grado,
      'semestreId': semestreId,
      'docenteId': docenteId,
    };
  }
}