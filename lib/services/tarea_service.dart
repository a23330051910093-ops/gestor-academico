import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/tarea_model.dart';
import '../models/entrega_model.dart';

class TareaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── TAREAS ───────────────────────────────────────────────

  Future<void> crearTarea(Tarea tarea) async {
    await _db.collection('tareas').add(tarea.toFirestore());
  }

  Stream<List<Tarea>> getTareas(String materiaId) {
    return _db
        .collection('tareas')
        .where('materiaId', isEqualTo: materiaId)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Tarea.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> eliminarTarea(String tareaId) async {
    await _db.collection('tareas').doc(tareaId).delete();
  }

  // ─── EXTRAER TEXTO DEL PDF ────────────────────────────────

  Future<Map<String, dynamic>?> seleccionarYExtraerPDF() async {
    try {
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (resultado == null || resultado.files.isEmpty) return null;

      final archivo = resultado.files.first;
      if (archivo.bytes == null) return null;

      // Extraer texto con Syncfusion
      final documento = PdfDocument(inputBytes: archivo.bytes!);
      final extractor = PdfTextExtractor(documento);
      final texto = extractor.extractText();
      documento.dispose();

      return {
        'nombre': archivo.name,
        'texto': texto,
        'bytes': archivo.bytes,
      };
    } catch (e) {
      return null;
    }
  }

  // Obtiene las entregas calificadas de un alumno en una materia
  Stream<List<Entrega>> getEntregasAlumno(
      String alumnoId, String materiaId) {
    return _db
        .collection('entregas')
        .where('alumnoId', isEqualTo: alumnoId)
        .where('materiaId', isEqualTo: materiaId)
        .where('estado', isEqualTo: 'calificado')
        .orderBy('fechaEntrega', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Entrega.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<Tarea?> getTareaPorId(String tareaId) async {
    try {
      final doc = await _db.collection('tareas').doc(tareaId).get();
      if (!doc.exists) return null;
      return Tarea.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // ─── ENTREGAS ─────────────────────────────────────────────

  Future<void> guardarEntrega(Entrega entrega) async {
    await _db.collection('entregas').add(entrega.toFirestore());
  }

  Future<void> actualizarEntrega(
      String entregaId, Map<String, dynamic> datos) async {
    await _db.collection('entregas').doc(entregaId).update(datos);
  }

  Stream<List<Entrega>> getEntregas(String tareaId) {
    return _db
        .collection('entregas')
        .where('tareaId', isEqualTo: tareaId)
        .orderBy('fechaEntrega', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Entrega.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<bool> yaEntrego(String tareaId, String alumnoId) async {
    final query = await _db
        .collection('entregas')
        .where('tareaId', isEqualTo: tareaId)
        .where('alumnoId', isEqualTo: alumnoId)
        .get();
    return query.docs.isNotEmpty;
  }
}