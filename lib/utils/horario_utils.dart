class ModuloClase {
  final int numero;
  final int horaInicio;
  final int minutoInicio;
  final int horaFin;
  final int minutoFin;

  const ModuloClase({
    required this.numero,
    required this.horaInicio,
    required this.minutoInicio,
    required this.horaFin,
    required this.minutoFin,
  });
}

class HorarioUtils {
  // Horario completo de la prepa
  static const List<ModuloClase> modulos = [
    ModuloClase(numero: 1,  horaInicio: 7,  minutoInicio: 0,  horaFin: 7,  minutoFin: 45),
    ModuloClase(numero: 2,  horaInicio: 7,  minutoInicio: 45, horaFin: 8,  minutoFin: 30),
    ModuloClase(numero: 3,  horaInicio: 8,  minutoInicio: 30, horaFin: 9,  minutoFin: 15),
    ModuloClase(numero: 4,  horaInicio: 9,  minutoInicio: 15, horaFin: 10, minutoFin: 0),
    ModuloClase(numero: 5,  horaInicio: 10, minutoInicio: 30, horaFin: 11, minutoFin: 15),
    ModuloClase(numero: 6,  horaInicio: 11, minutoInicio: 15, horaFin: 12, minutoFin: 0),
    ModuloClase(numero: 7,  horaInicio: 12, minutoInicio: 0,  horaFin: 12, minutoFin: 45),
    ModuloClase(numero: 8,  horaInicio: 12, minutoInicio: 45, horaFin: 13, minutoFin: 30),
    ModuloClase(numero: 9,  horaInicio: 13, minutoInicio: 30, horaFin: 14, minutoFin: 15),
    ModuloClase(numero: 10, horaInicio: 14, minutoInicio: 15, horaFin: 15, minutoFin: 0),
    ModuloClase(numero: 11, horaInicio: 15, minutoInicio: 0, horaFin: 15, minutoFin: 45),
    ModuloClase(numero: 12, horaInicio: 15, minutoInicio: 45, horaFin: 16, minutoFin: 30),
    ModuloClase(numero: 13, horaInicio: 17, minutoInicio: 0,  horaFin: 17, minutoFin: 45),
    ModuloClase(numero: 14, horaInicio: 17, minutoInicio: 45, horaFin: 18, minutoFin: 30),
    ModuloClase(numero: 15, horaInicio: 18, minutoInicio: 30, horaFin: 19, minutoFin: 15),
    ModuloClase(numero: 16, horaInicio: 19, minutoInicio: 15, horaFin: 20, minutoFin: 0),
  ];

  // Detecta en qué módulo estamos ahora mismo
  // Regresa null si estamos en receso o fuera del horario
  static ModuloClase? moduloActual() {
    final ahora = DateTime.now();
    final minutosActuales = ahora.hour * 60 + ahora.minute;

    for (final modulo in modulos) {
      final inicio = modulo.horaInicio * 60 + modulo.minutoInicio;
      final fin = modulo.horaFin * 60 + modulo.minutoFin;

      if (minutosActuales >= inicio && minutosActuales < fin) {
        return modulo;
      }
    }
    return null; // Fuera de horario o en receso
  }

  // Obtiene la hora de fin del módulo actual como DateTime
  static DateTime? finModuloActual() {
    final modulo = moduloActual();
    if (modulo == null) return null;

    final ahora = DateTime.now();
    return DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
      modulo.horaFin,
      modulo.minutoFin,
    );
  }

  // Descripción legible del módulo actual
  static String descripcionModulo(ModuloClase modulo) {
    final inicioH = modulo.horaInicio.toString().padLeft(2, '0');
    final inicioM = modulo.minutoInicio.toString().padLeft(2, '0');
    final finH = modulo.horaFin.toString().padLeft(2, '0');
    final finM = modulo.minutoFin.toString().padLeft(2, '0');
    return 'Módulo ${modulo.numero} ($inicioH:$inicioM - $finH:$finM)';
  }
}