class Alumno {
  final String id;
  final String nombre;
  final String matricula;
  final String correo;
  final String docenteId;
  final List<String> grupoIds;

  // ─── Campos nuevos ────────────────────────────────────────
  final String correoTutor;       // Correo del padre/tutor
  final bool cuentaActivada;      // ¿El alumno ya creó su contraseña?
  final bool cuentaTutorActivada; // ¿El padre ya creó su contraseña?
  final String uid;               // UID de Firebase Auth del alumno
  final String uidTutor;          // UID de Firebase Auth del padre

  Alumno({
    required this.id,
    required this.nombre,
    required this.matricula,
    required this.correo,
    required this.docenteId,
    this.grupoIds = const [],
    this.correoTutor = '',
    this.cuentaActivada = false,
    this.cuentaTutorActivada = false,
    this.uid = '',
    this.uidTutor = '',
  });

  factory Alumno.fromFirestore(Map<String, dynamic> data, String id) {
    return Alumno(
      id: id,
      nombre: data['nombre'] ?? '',
      matricula: data['matricula'] ?? '',
      correo: data['correo'] ?? '',
      docenteId: data['docenteId'] ?? '',
      grupoIds: List<String>.from(data['grupoIds'] ?? []),
      correoTutor: data['correoTutor'] ?? '',
      cuentaActivada: data['cuentaActivada'] ?? false,
      cuentaTutorActivada: data['cuentaTutorActivada'] ?? false,
      uid: data['uid'] ?? '',
      uidTutor: data['uidTutor'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'matricula': matricula,
      'correo': correo,
      'docenteId': docenteId,
      'grupoIds': grupoIds,
      'correoTutor': correoTutor,
      'cuentaActivada': cuentaActivada,
      'cuentaTutorActivada': cuentaTutorActivada,
      'uid': uid,
      'uidTutor': uidTutor,
    };
  }
}