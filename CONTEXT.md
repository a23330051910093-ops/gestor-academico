# GESTOR ACADÉMICO INTELIGENTE - CONTEXTO DEL PROYECTO

## Perfil del desarrollador
Estudiante de preparatoria tercer año, especialidad programación.
Nivel: principiante. Trabajo asistido por Claude Web + VSCode.

## Cliente
Mtro. José Alfredo Hernández Palacios, docente de preparatoria.
Gestiona SUS propios grupos y materias únicamente.

## Stack tecnológico — NO cambiar
- Framework: Flutter (Dart)
- Auth + DB + Storage: Firebase
- IA calificación: OpenAI API (gpt-4o-mini)
- Editor: VSCode
- Versiones: GitHub

## Roles — CRÍTICO
- DOCENTE: acceso total
- ALUMNO: solo lectura + escanear QR
- PADRE: solo lectura, solo ve a su hijo

## Reglas de negocio — NUNCA romper
- Alumno NUNCA sube archivos ni modifica datos
- Calificación IA siempre requiere revisión del maestro
- QR expira en 15 minutos
- Alumno es registro único aunque esté en varias materias
- Firebase Security Rules activas desde día 1

## Estructura académica
Semestre → Grupo (ej 2°B) → Materia → Alumnos

## Módulos
1. Autenticación con roles
2. Gestión: semestres, grupos, materias, alumnos
3. Asistencia: QR automático + manual verificado
4. Evaluación IA: maestro sube PDF → IA califica → maestro revisa
5. Reportes semanales exportables

## Flujo evaluación IA
Maestro descarga PDF de Classroom → lo sube en la app →
app extrae texto → manda texto + rúbrica a OpenAI →
OpenAI califica por criterio → maestro revisa → publica →
alumno ve resultado (solo lectura)

## Estado actual
- Semana: 1 | Día: 2
- Completado: Entorno configurado, proyecto Flutter creado
- Trabajando en: Estructura de carpetas + Firebase
- Próximo: Sistema de autenticación con roles

## Decisiones tomadas — NO reabrir
- Sin integración API Classroom (riesgo alto)
- Maestro sube PDFs manualmente
- Importación alumnos desde CSV
- Teléfono físico: Poco X7 Pro para pruebas

## Historial
- Día 1: Flutter configurado, PATH, flutter doctor OK
- Día 2: Proyecto creado, CONTEXT.md, estructura de carpetas