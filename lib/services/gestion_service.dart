import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/semestre_model.dart';
import '../models/grupo_model.dart';
import '../models/materia_model.dart';
import '../models/alumno_model.dart';

class GestionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── SEMESTRES ────────────────────────────────────────────

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

  Future<void> crearSemestre(Semestre semestre) async {
    await _db.collection('semestres').add(semestre.toFirestore());
  }

  Future<void> eliminarSemestre(String semestreId) async {
    await _db.collection('semestres').doc(semestreId).delete();
  }

  // ─── GRUPOS ───────────────────────────────────────────────

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

  Future<void> crearGrupo(Grupo grupo) async {
    await _db.collection('grupos').add(grupo.toFirestore());
  }

  Future<void> eliminarGrupo(String grupoId) async {
    await _db.collection('grupos').doc(grupoId).delete();
  }

  // ─── MATERIAS ─────────────────────────────────────────────

  Stream<List<Materia>> getMaterias(String grupoId) {
    return _db
        .collection('materias')
        .where('grupoId', isEqualTo: grupoId)
        .orderBy('nombre')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Materia.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> crearMateria(Materia materia) async {
    await _db.collection('materias').add(materia.toFirestore());
  }

  Future<void> eliminarMateria(String materiaId) async {
    await _db.collection('materias').doc(materiaId).delete();
  }

  // ─── ALUMNOS ──────────────────────────────────────────────

  // Obtiene alumnos de un grupo específico
  Stream<List<Alumno>> getAlumnosPorGrupo(String grupoId) {
    return _db
        .collection('alumnos')
        .where('grupoIds', arrayContains: grupoId)
        .orderBy('nombre')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Alumno.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Crea un alumno nuevo
  Future<void> crearAlumno(Alumno alumno) async {
    await _db.collection('alumnos').add(alumno.toFirestore());
  }

  // Elimina un alumno
  Future<void> eliminarAlumno(String alumnoId) async {
    await _db.collection('alumnos').doc(alumnoId).delete();
  }

  // Verifica si ya existe un alumno con esa matrícula en este grupo
  Future<bool> existeMatricula(String matricula, String grupoId) async {
    final query = await _db
        .collection('alumnos')
        .where('matricula', isEqualTo: matricula)
        .where('grupoIds', arrayContains: grupoId)
        .get();
    return query.docs.isNotEmpty;
  }

  // Importa una lista de alumnos de golpe (para CSV)
  Future<Map<String, int>> importarAlumnos(
      List<Alumno> alumnos, String grupoId) async {
    int importados = 0;
    int duplicados = 0;

    // Usamos un batch para escribir todos de una sola vez
    // Esto es más rápido y seguro que escribir uno por uno
    final batch = _db.batch();

    for (final alumno in alumnos) {
      // Verificar si ya existe esa matrícula en este grupo
      final existe = await existeMatricula(alumno.matricula, grupoId);
      if (existe) {
        duplicados++;
        continue; // Salta este alumno y sigue con el siguiente
      }

      final docRef = _db.collection('alumnos').doc();
      batch.set(docRef, alumno.toFirestore());
      importados++;
    }

    // Ejecuta todas las escrituras de una sola vez
    await batch.commit();

    return {
      'importados': importados,
      'duplicados': duplicados,
    };
  }

  // Obtiene materias de un grupo como Future (no Stream)
  Future<List<Materia>> getMateriasPorGrupo(String grupoId) async {
    final snapshot = await _db
        .collection('materias')
        .where('grupoId', isEqualTo: grupoId)
        .get();
    return snapshot.docs
        .map((doc) => Materia.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // Obtiene alumnos de un grupo como Future (no Stream)
  Future<List<Alumno>> getAlumnosPorGrupoFuture(String grupoId) async {
    final snapshot = await _db
        .collection('alumnos')
        .where('grupoIds', arrayContains: grupoId)
        .orderBy('nombre')
        .get();
    return snapshot.docs
        .map((doc) => Alumno.fromFirestore(doc.data(), doc.id))
        .toList();
  }  

  Future<Alumno?> getAlumnoPorId(String alumnoId) async {
    try {
      final doc = await _db.collection('alumnos').doc(alumnoId).get();
      if (!doc.exists) return null;
      return Alumno.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // Obtiene un alumno por su UID de Firebase Auth
  Future<Alumno?> getAlumnoPorUid(String uid) async {
    try {
      final query = await _db
          .collection('alumnos')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return Alumno.fromFirestore(query.docs.first.data(), query.docs.first.id);
    } catch (e) {
      return null;
    }
  }
}