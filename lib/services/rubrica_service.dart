import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rubrica_model.dart';

class RubricaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Crear rúbrica
  Future<void> crearRubrica(Rubrica rubrica) async {
    await _db.collection('rubricas').add(rubrica.toFirestore());
  }

  // Obtiene una rúbrica por su ID
  Future<Rubrica?> getRubricaPorId(String rubricaId) async {
    try {
      final doc = await _db.collection('rubricas').doc(rubricaId).get();
      if (!doc.exists) return null;
      return Rubrica.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // Obtener rúbricas de una materia
  Stream<List<Rubrica>> getRubricas(String materiaId) {
    return _db
        .collection('rubricas')
        .where('materiaId', isEqualTo: materiaId)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Rubrica.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Eliminar rúbrica
  Future<void> eliminarRubrica(String rubricaId) async {
    await _db.collection('rubricas').doc(rubricaId).delete();
  }
}