import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/semestre_model.dart';
import '../models/grupo_model.dart';

class GestionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── SEMESTRES ───────────────────────────────────────────

  // Obtiene todos los semestres del docente en tiempo real
  Stream<List<Semestre>> getSemestres(String docenteId) {
    return _db
        .collection('semestres')
        .where('docenteId', isEqualTo: docenteId)
        .orderBy('fechaInicio', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Semestre.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Crea un nuevo semestre
  Future<void> crearSemestre(Semestre semestre) async {
    await _db.collection('semestres').add(semestre.toFirestore());
  }

  // Elimina un semestre
  Future<void> eliminarSemestre(String semestreId) async {
    await _db.collection('semestres').doc(semestreId).delete();
  }

  // ─── GRUPOS ──────────────────────────────────────────────

  // Obtiene todos los grupos de un semestre en tiempo real
  Stream<List<Grupo>> getGrupos(String semestreId) {
    return _db
        .collection('grupos')
        .where('semestreId', isEqualTo: semestreId)
        .orderBy('nombre')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Grupo.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Crea un nuevo grupo
  Future<void> crearGrupo(Grupo grupo) async {
    await _db.collection('grupos').add(grupo.toFirestore());
  }

  // Elimina un grupo
  Future<void> eliminarGrupo(String grupoId) async {
    await _db.collection('grupos').doc(grupoId).delete();
  }
}