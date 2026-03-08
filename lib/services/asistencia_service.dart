import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sesion_qr_model.dart';
import '../models/asistencia_model.dart';
import '../utils/horario_utils.dart';

class AsistenciaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── SESIONES QR ──────────────────────────────────────────

  Future<SesionQR?> crearSesionQR({
    required String materiaId,
    required String materiaNombre,
    required String grupoId,
    required String docenteId,
    int minutosQR = 10,
  }) async {
    // Detectar módulo actual por horario
    final modulo = HorarioUtils.moduloActual();

    // Si estamos fuera del horario de clases
    if (modulo == null) {
      // En desarrollo permitimos crear QR fuera de horario para pruebas
      // En producción aquí iría: return null;
    }

    final ahora = DateTime.now();
    final expiracionQR = ahora.add(Duration(minutes: minutosQR));

    // Fin del módulo actual (o 50 minutos si estamos fuera de horario)
    final finModulo =
        HorarioUtils.finModuloActual() ?? ahora.add(const Duration(minutes: 50));

    final numeroModulo = modulo?.numero ?? 0;

    // Buscar si ya existe una sesión activa para este módulo y materia
    final sesionExistente = await _db
        .collection('sesionesQR')
        .where('materiaId', isEqualTo: materiaId)
        .where('numeroModulo', isEqualTo: numeroModulo)
        .where('activo', isEqualTo: true)
        .get();

    // Si ya existe una sesión para este módulo, solo actualizamos el QR
    // (nueva fecha de expiración) pero mantenemos la misma sesión
    if (sesionExistente.docs.isNotEmpty) {
      final docRef = sesionExistente.docs.first.reference;
      await docRef.update({
        'fechaExpiracion': expiracionQR.toIso8601String(),
        'activo': true,
      });

      return SesionQR.fromFirestore(
        {
          ...sesionExistente.docs.first.data(),
          'fechaExpiracion': expiracionQR.toIso8601String()
        },
        sesionExistente.docs.first.id,
      );
    }

    // Si no existe, crear sesión nueva para este módulo
    // Primero desactivar cualquier sesión anterior de otra materia
    final sesionesAnteriores = await _db
        .collection('sesionesQR')
        .where('docenteId', isEqualTo: docenteId)
        .where('activo', isEqualTo: true)
        .get();

    final batch = _db.batch();
    for (final doc in sesionesAnteriores.docs) {
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
      fechaExpiracion: expiracionQR,
      finModulo: finModulo,
      numeroModulo: numeroModulo,
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
      fechaExpiracion: expiracionQR,
      finModulo: finModulo,
      numeroModulo: numeroModulo,
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
      if (sesion.qrExpirado) return 'El código QR ha expirado';

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

    final presentes =
        total.docs.where((doc) => doc.data()['estado'] == 'presente').length;

    return (presentes / total.docs.length) * 100;
  }

  // Helper: inicio del día actual
  DateTime _inicioDia() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  // Obtiene una sesión QR por su ID
  Future<SesionQR?> getSesionPorId(String sesionId) async {
    try {
      final doc = await _db.collection('sesionesQR').doc(sesionId).get();
      if (!doc.exists) return null;
      return SesionQR.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }
}