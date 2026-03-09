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
    final modulo = HorarioUtils.moduloActual();

    if (modulo == null) {
      // En desarrollo permitimos crear QR fuera de horario
    }

    final ahora = DateTime.now();
    final expiracionQR = ahora.add(Duration(minutes: minutosQR));

    final finModulo =
        HorarioUtils.finModuloActual() ?? ahora.add(const Duration(minutes: 50));

    final numeroModulo = modulo?.numero ?? 0;

    final sesionExistente = await _db
        .collection('sesionesQR')
        .where('materiaId', isEqualTo: materiaId)
        .where('numeroModulo', isEqualTo: numeroModulo)
        .where('activo', isEqualTo: true)
        .get();

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

  // ─── CERRAR SESIÓN ────────────────────────────────────────

  Future<void> cerrarSesionQR(String sesionId) async {
    await _db.collection('sesionesQR').doc(sesionId).update({
      'activo': false,
    });
  }

  // ─── SESIÓN ACTIVA ────────────────────────────────────────

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

  Future<String?> registrarAsistenciaQR({
    required String sesionId,
    required String alumnoId,
    required String alumnoNombre,
    required String materiaId,
    required String grupoId,
  }) async {
    try {
      final sesionDoc =
          await _db.collection('sesionesQR').doc(sesionId).get();

      if (!sesionDoc.exists) return 'El código QR no es válido';

      final sesion =
          SesionQR.fromFirestore(sesionDoc.data()!, sesionDoc.id);

      if (!sesion.activo) return 'Esta sesión ya fue cerrada';
      if (sesion.qrExpirado) return 'El código QR ha expirado';

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

      await _db.collection('asistencias').add(
            Asistencia(
              id: '',
              alumnoId: alumnoId,
              alumnoNombre: alumnoNombre,
              materiaId: materiaId,
              grupoId: grupoId,
              sesionId: sesionId,
              fecha: DateTime.now(),
              metodo: 'qr',
              estado: 'presente',
              validadoPorDocente: true,
            ).toFirestore(),
          );

      return null;
    } catch (e) {
      return 'Error al registrar asistencia. Intenta de nuevo';
    }
  }

  // ─── SOLICITAR ASISTENCIA MANUAL ──────────────────────────

  Future<String?> solicitarAsistenciaManual({
    required String alumnoId,
    required String alumnoNombre,
    required String materiaId,
    required String grupoId,
  }) async {
    try {
      final ahora = DateTime.now();

      final modulo = HorarioUtils.moduloActual();
      final numeroModulo = modulo?.numero ?? 0;

      final finModulo =
          HorarioUtils.finModuloActual() ?? ahora.add(const Duration(minutes: 50));

      await _db.collection('asistencias').add(
            Asistencia(
              id: '',
              alumnoId: alumnoId,
              alumnoNombre: alumnoNombre,
              materiaId: materiaId,
              grupoId: grupoId,
              sesionId: 'manual_${materiaId}_$numeroModulo',
              fecha: ahora,
              metodo: 'manual',
              estado: 'pendiente',
              validadoPorDocente: false,
              numeroModulo: numeroModulo,
              finModulo: finModulo,
            ).toFirestore(),
          );

      return null;
    } catch (e) {
      return 'No se pudo enviar la solicitud';
    }
  }

  // ─── STREAMS DE ASISTENCIAS ───────────────────────────────

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

  // ─── ESTADÍSTICAS ─────────────────────────────────────────

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

  // ─── HELPERS ──────────────────────────────────────────────

  DateTime _inicioDia() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  Future<SesionQR?> getSesionPorId(String sesionId) async {
    try {
      final doc = await _db.collection('sesionesQR').doc(sesionId).get();
      if (!doc.exists) return null;
      return SesionQR.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }


  // Calcula porcentajes de todos los alumnos de un grupo en una materia
  Future<Map<String, double>> calcularPorcentajesGrupo(
      String materiaId, List<String> alumnoIds) async {
    final Map<String, double> porcentajes = {};

    for (final alumnoId in alumnoIds) {
      final porcentaje = await calcularPorcentaje(alumnoId, materiaId);
      porcentajes[alumnoId] = porcentaje;
    }

    return porcentajes;
  }

  // Obtiene asistencias de un alumno agrupadas por fecha
  Stream<List<Asistencia>> getAsistenciasAlumno(
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
  

  // ─── ASISTENCIAS PENDIENTES ───────────────────────────────

  Stream<List<Asistencia>> getAsistenciasPendientes(String docenteId) {
    return _db
        .collection('asistencias')
        .where('estado', isEqualTo: 'pendiente')
        .orderBy('fecha', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final asistencias = snapshot.docs
          .map((doc) => Asistencia.fromFirestore(doc.data(), doc.id))
          .toList();

      final List<Asistencia> propias = [];
      for (final a in asistencias) {
        final materiaDoc =
            await _db.collection('materias').doc(a.materiaId).get();
        if (materiaDoc.exists &&
            materiaDoc.data()?['docenteId'] == docenteId) {
          propias.add(a);
        }
      }
      return propias;
    });
  }

  Future<void> confirmarAsistencia(String asistenciaId) async {
    await _db.collection('asistencias').doc(asistenciaId).update({
      'estado': 'presente',
      'validadoPorDocente': true,
    });
  }

  Future<void> rechazarAsistencia(String asistenciaId) async {
    await _db.collection('asistencias').doc(asistenciaId).update({
      'estado': 'ausente',
      'validadoPorDocente': true,
    });
  }
}

