class CriterioRubrica {
  final String id;
  final String nombre;
  final String descripcion;
  final int peso; // Porcentaje del total, todos deben sumar 100

  CriterioRubrica({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.peso,
  });

  factory CriterioRubrica.fromMap(Map<String, dynamic> data) {
    return CriterioRubrica(
      id: data['id'] ?? '',
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      peso: data['peso'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'peso': peso,
    };
  }
}

class Rubrica {
  final String id;
  final String nombre;
  final String descripcion;
  final String docenteId;
  final String materiaId;
  final List<CriterioRubrica> criterios;
  final DateTime fechaCreacion;

  Rubrica({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.docenteId,
    required this.materiaId,
    required this.criterios,
    required this.fechaCreacion,
  });

  factory Rubrica.fromFirestore(Map<String, dynamic> data, String id) {
    return Rubrica(
      id: id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      docenteId: data['docenteId'] ?? '',
      materiaId: data['materiaId'] ?? '',
      criterios: (data['criterios'] as List<dynamic>? ?? [])
          .map((c) => CriterioRubrica.fromMap(c as Map<String, dynamic>))
          .toList(),
      fechaCreacion: DateTime.parse(data['fechaCreacion']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'docenteId': docenteId,
      'materiaId': materiaId,
      'criterios': criterios.map((c) => c.toMap()).toList(),
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  // Suma total de pesos, debe ser 100
  int get totalPeso =>
      criterios.fold(0, (suma, c) => suma + c.peso);
}