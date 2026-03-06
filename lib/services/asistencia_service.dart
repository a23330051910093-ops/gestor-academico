import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sesion_qr_model.dart';
import '../models/asistencia_model.dart';

class AsistenciaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── SESIONES QR ──────────────────────────────────────────

  // Crea una nueva sesión QR para una materia
  Future<SesionQR> crearSesionQR({
    required String materiaId,
    required String materiaNombre,
    required String grupoId,
    required String docenteId,
    int minutosExpiracion = 15,
  }) async {
    final ahora = DateTime.now();
    final expiracion = ahora.add(Duration(minutes: minutosExpiracion));

    // Primero desactiva cualquier sesión activa anterior de esta materia
    final sesionesActivas = await _db
        .collection('sesionesQR')
        .where('materiaId', isEqualTo: materiaId)
        .where('activo', isEqualTo: true)
        .get();

    final batch = _db.batch();
    for (final doc in sesionesActivas.docs) {
      batch.update(doc.reference, {'activo': false});
    }
    await batch.commit();

    // Crear la nueva sesión
    final sesion = SesionQR(
      id: '',
      materiaId: materiaId,
      materiaNombre: materiaNombre,
      grupoId: grupoId,
      docenteId: docenteId,
      fechaCreacion: ahora,
      fechaExpiracion: expiracion,
      activo: true,
    );

    final docRef = await _db.collection('sesionesQR').add(sesion.toFirestore());

    return SesionQR(
      id: docRef.id,
      materiaId: materiaId,
      materiaNombre: materiaNombre,
      grupoId: grupoId,
      docenteId: docenteId,
      fechaCreacion: ahora,
      fechaExpiracion: expiracion,
      activo: true,
    );
  }

  // Desactiva una sesión QR
  Future<void> cerrarSesionQR(String sesionId) async {
    await _db.collection('sesionesQR').doc(sesionId).update({
      'activo': false,
    });
  }

  // Obtiene la sesión QR activa de una materia en tiempo real
  Stream<SesionQR?> getSesionActiva(String materiaId) {
    return _db
        .collection('sesionesQR')
        .where('materiaId', isEqualTo: materiaId)
        .where('activo', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return SesionQR.fromFirestore(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    });
  }

  // ─── ASISTENCIAS ──────────────────────────────────────────

  // Registra asistencia por QR
  Future<String?> registrarAsistenciaQR({
    required String sesionId,
    required String alumnoId,
    required String alumnoNombre,
    required String materiaId,
    required String grupoId,
  }) async {
    try {
      // Verificar que la sesión existe y está activa
      final sesionDoc =
          await _db.collection('sesionesQR').doc(sesionId).get();

      if (!sesionDoc.exists) return 'El código QR no es válido';

      final sesion =
          SesionQR.fromFirestore(sesionDoc.data()!, sesionDoc.id);

      if (!sesion.activo) return 'Esta sesión ya fue cerrada';
      if (sesion.estaExpirado) return 'El código QR ha expirado';

      // Verificar que el alumno no haya registrado ya
      final yaRegistrado = await _db
          .collection('asistencias')
          .where('alumnoId', isEqualTo: alumnoId)
          .where('materiaId', isEqualTo: materiaId)
          .where('fecha',
              isGreaterThanOrEqualTo: _inicioDia().toIso8601String())
          .get();

      if (yaRegistrado.docs.isNotEmpty) {
        return 'Ya registraste tu asistencia hoy';
      }

      // Registrar asistencia
      await _db.collection('asistencias').add(
            Asistencia(
              id: '',
              alumnoId: alumnoId,
              alumnoNombre: alumnoNombre,
              materiaId: materiaId,
              grupoId: grupoId,
              fecha: DateTime.now(),
              metodo: 'qr',
              estado: 'presente',
              validadoPorDocente: true,
            ).toFirestore(),
          );

      return null; // null = éxito
    } catch (e) {
      return 'Error al registrar asistencia. Intenta de nuevo';
    }
  }

  // Obtiene asistencias de hoy para una materia en tiempo real
  Stream<List<Asistencia>> getAsistenciasHoy(String materiaId) {
    return _db
        .collection('asistencias')
        .where('materiaId', isEqualTo: materiaId)
        .where('fecha',
            isGreaterThanOrEqualTo: _inicioDia().toIso8601String())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Asistencia.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Obtiene historial de asistencias de un alumno
  Stream<List<Asistencia>> getHistorialAlumno(
      String alumnoId, String materiaId) {
    return _db
        .collection('asistencias')
        .where('alumnoId', isEqualTo: alumnoId)
        .where('materiaId', isEqualTo: materiaId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Asistencia.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Calcula el porcentaje de asistencia de un alumno en una materia
  Future<double> calcularPorcentaje(
      String alumnoId, String materiaId) async {
    final total = await _db
        .collection('asistencias')
        .where('alumnoId', isEqualTo: alumnoId)
        .where('materiaId', isEqualTo: materiaId)
        .get();

    if (total.docs.isEmpty) return 0.0;

    final presentes = total.docs
        .where((doc) => doc.data()['estado'] == 'presente')
        .length;

    return (presentes / total.docs.length) * 100;
  }

  // Helper: inicio del día actual
  DateTime _inicioDia() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }
}