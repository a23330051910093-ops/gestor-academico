import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import '../../../services/gestion_service.dart';
import '../../../models/alumno_model.dart';
import '../../../models/grupo_model.dart';

class ImportarCsvScreen extends StatefulWidget {
  final Grupo grupo;
  final String docenteId;

  const ImportarCsvScreen({
    super.key,
    required this.grupo,
    required this.docenteId,
  });

  @override
  State<ImportarCsvScreen> createState() => _ImportarCsvScreenState();
}

class _ImportarCsvScreenState extends State<ImportarCsvScreen> {
  final GestionService _gestionService = GestionService();

  // Lista de alumnos detectados en el CSV
  List<Alumno> _alumnosDetectados = [];

  // Estados de la pantalla
  bool _archivoSeleccionado = false;
  bool _isLoading = false;
  bool _importando = false;
  String? _errorArchivo;
  String? _nombreArchivo;

  // ─── Seleccionar y leer el archivo CSV ───────────────────
  Future<void> _seleccionarArchivo() async {
    setState(() {
      _errorArchivo = null;
      _alumnosDetectados = [];
      _archivoSeleccionado = false;
      _isLoading = true;
    });

    try {
      // Abre el selector de archivos del sistema
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      // Si el usuario canceló sin seleccionar
      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final file = File(result.files.single.path!);
      final contenido = await file.readAsString();
      _nombreArchivo = result.files.single.name;

      // Parsear el CSV
      final List<List<dynamic>> filas = const CsvToListConverter().convert(
        contenido,
        eol: '\n',
      );

      if (filas.isEmpty) {
        setState(() {
          _errorArchivo = 'El archivo está vacío';
          _isLoading = false;
        });
        return;
      }

      // Detectar si la primera fila es encabezado
      // Si la primera celda contiene letras que no son un nombre real
      // asumimos que es encabezado y la saltamos
      final primeraFila = filas[0];
      final int inicioData = _esEncabezado(primeraFila) ? 1 : 0;

      if (filas.length <= inicioData) {
        setState(() {
          _errorArchivo = 'El archivo no contiene datos de alumnos';
          _isLoading = false;
        });
        return;
      }

      // Convertir cada fila en un objeto Alumno
      final List<Alumno> alumnosParseados = [];
      final List<int> filasConError = [];

      for (int i = inicioData; i < filas.length; i++) {
        final fila = filas[i];

        // Ignorar filas vacías
        if (fila.every((cell) => cell.toString().trim().isEmpty)) continue;

        // El CSV debe tener al menos 3 columnas: nombre, matrícula, correo
        if (fila.length < 3) {
          filasConError.add(i + 1);
          continue;
        }

        final nombre = fila[0].toString().trim();
        final matricula = fila[1].toString().trim();
        final correo = fila[2].toString().trim();

        if (nombre.isEmpty || matricula.isEmpty || correo.isEmpty) {
          filasConError.add(i + 1);
          continue;
        }

        final correoTutor = fila.length >= 4
            ? fila[3].toString().trim()
            : '';

        alumnosParseados.add(Alumno(
          id: '',
          nombre: nombre,
          matricula: matricula,
          correo: correo,
          correoTutor: correoTutor,
          docenteId: widget.docenteId,
          grupoIds: [widget.grupo.id],
        ));
      }


      if (alumnosParseados.isEmpty) {
        setState(() {
          _errorArchivo =
              'No se encontraron alumnos válidos. Verifica el formato del archivo.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _alumnosDetectados = alumnosParseados;
        _archivoSeleccionado = true;
        _isLoading = false;
        if (filasConError.isNotEmpty) {
          _errorArchivo =
              'Filas ignoradas por formato incorrecto: ${filasConError.join(', ')}';
        }
      });
    } catch (e) {
      setState(() {
        _errorArchivo =
            'Error al leer el archivo. Verifica que sea un CSV válido.';
        _isLoading = false;
      });
    }
  }

  // Detecta si una fila es encabezado revisando si parece texto de título
  bool _esEncabezado(List<dynamic> fila) {
    if (fila.isEmpty) return false;
    final primera = fila[0].toString().toLowerCase().trim();
    return primera == 'nombre' ||
        primera == 'name' ||
        primera == 'alumno' ||
        primera == 'student';
  }

  // ─── Importar los alumnos detectados ─────────────────────
  Future<void> _importar() async {
    setState(() => _importando = true);

    try {
      final resultado = await _gestionService.importarAlumnos(
        _alumnosDetectados,
        widget.grupo.id,
      );

      if (!mounted) return;

      final importados = resultado['importados'] ?? 0;
      final duplicados = resultado['duplicados'] ?? 0;

      // Mostrar resultado y regresar
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Importación completada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('$importados alumnos importados'),
                ],
              ),
              if (duplicados > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('$duplicados duplicados omitidos'),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _importando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al importar. Intenta de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Importar desde CSV'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instrucciones del formato
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Formato requerido',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'El archivo CSV debe tener 3 columnas en este orden:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _FormatRow(numero: '1', texto: 'Nombre completo'),
                  _FormatRow(numero: '2', texto: 'Matrícula'),
                  _FormatRow(numero: '3', texto: 'Correo electrónico'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Juan Pérez García,12345,juan@cetis.edu.mx\n'
                      'María López Torres,12346,maria@cetis.edu.mx',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La primera fila puede ser encabezado, se detecta automáticamente.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botón seleccionar archivo
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading || _importando ? null : _seleccionarArchivo,
                icon: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_file_rounded),
                label: Text(
                  _archivoSeleccionado
                      ? 'Cambiar archivo'
                      : 'Seleccionar archivo CSV',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Error del archivo
            if (_errorArchivo != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorArchivo!,
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Preview de alumnos detectados
            if (_archivoSeleccionado && _alumnosDetectados.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.preview_rounded,
                      color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Text(
                    'Vista previa — $_nombreArchivo',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_alumnosDetectados.length} alumnos detectados',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),

              // Lista de preview
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _alumnosDetectados.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final alumno = _alumnosDetectados[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            const Color(0xFF1565C0).withValues(alpha: 0.1),
                        child: Text(
                          alumno.nombre[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1565C0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        alumno.nombre,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        '${alumno.matricula} • ${alumno.correo}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Botón importar
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _importando ? null : _importar,
                  icon: _importando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(
                    _importando
                        ? 'Importando...'
                        : 'Importar ${_alumnosDetectados.length} alumnos',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Widget pequeño para cada fila del formato
class _FormatRow extends StatelessWidget {
  final String numero;
  final String texto;

  const _FormatRow({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              numero,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(texto, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}