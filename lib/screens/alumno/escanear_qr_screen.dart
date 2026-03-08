import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/auth_service.dart';
import '../../services/asistencia_service.dart';
import '../../services/gestion_service.dart';

class EscanearQRScreen extends StatefulWidget {
  const EscanearQRScreen({super.key});

  @override
  State<EscanearQRScreen> createState() => _EscanearQRScreenState();
}

class _EscanearQRScreenState extends State<EscanearQRScreen> {
  final AsistenciaService _asistenciaService = AsistenciaService();
  final MobileScannerController _scannerController = MobileScannerController();

  bool _procesando = false;
  bool _escaneado = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _procesarQR(String sesionId) async {
    // Evita procesar el mismo QR dos veces
    if (_procesando || _escaneado) return;

    setState(() => _procesando = true);

    // Pausar el escáner mientras procesamos
    await _scannerController.stop();

    final authService = Provider.of<AuthService>(context, listen: false);
    final gestionService = GestionService();

    // Obtener datos del alumno desde Firestore
    final uid = authService.currentUser!.uid;

    try {
      // Buscar el documento del alumno por su UID
      final queryAlumno = await gestionService.getAlumnoPorUid(uid);

      if (queryAlumno == null) {
        if (mounted) _mostrarResultado(false, 'No se encontró tu perfil de alumno');
        return;
      }

      // Obtener los datos de la sesión QR para saber la materia y grupo
      final sesionDoc = await _asistenciaService.getSesionPorId(sesionId);

      if (sesionDoc == null) {
        if (mounted) _mostrarResultado(false, 'Código QR no válido');
        return;
      }

      // Verificar que el alumno pertenece al grupo de la sesión
      if (!queryAlumno.grupoIds.contains(sesionDoc.grupoId)) {
        if (mounted) {
          _mostrarResultado(false, 'Este QR no corresponde a tu grupo');
        }
        return;
      }

      // Registrar la asistencia
      final error = await _asistenciaService.registrarAsistenciaQR(
        sesionId: sesionId,
        alumnoId: queryAlumno.id,
        alumnoNombre: queryAlumno.nombre,
        materiaId: sesionDoc.materiaId,
        grupoId: sesionDoc.grupoId,
      );

      if (mounted) {
        if (error != null) {
          _mostrarResultado(false, error);
        } else {
          _mostrarResultado(
            true,
            '¡Asistencia registrada!\n${sesionDoc.materiaNombre}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarResultado(false, 'Error al procesar. Intenta de nuevo');
      }
    }
  }

  void _mostrarResultado(bool exito, String mensaje) {
    setState(() {
      _escaneado = true;
      _procesando = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              exito ? Icons.check_circle_rounded : Icons.error_rounded,
              color: exito ? Colors.green : Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // cierra el diálogo
                Navigator.pop(context); // regresa al portal del alumno
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    exito ? Colors.green : const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Aceptar'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear QR de Asistencia'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
            tooltip: 'Linterna',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Cámara
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final valor = barcodes.first.rawValue;
                if (valor != null && !_procesando && !_escaneado) {
                  _procesarQR(valor);
                }
              }
            },
          ),

          // Marco visual del escáner
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Esquinas decorativas
                  _Esquina(top: 0, left: 0),
                  _Esquina(top: 0, right: 0),
                  _Esquina(bottom: 0, left: 0),
                  _Esquina(bottom: 0, right: 0),
                ],
              ),
            ),
          ),

          // Instrucción
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Apunta la cámara al código QR que muestra tu maestro',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),

          // Indicador de procesando
          if (_procesando)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Registrando asistencia...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Widget de esquina decorativa del marco
class _Esquina extends StatelessWidget {
  final double? top, bottom, left, right;

  const _Esquina({this.top, this.bottom, this.left, this.right});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: top != null
                ? const BorderSide(color: Color(0xFF1565C0), width: 4)
                : BorderSide.none,
            bottom: bottom != null
                ? const BorderSide(color: Color(0xFF1565C0), width: 4)
                : BorderSide.none,
            left: left != null
                ? const BorderSide(color: Color(0xFF1565C0), width: 4)
                : BorderSide.none,
            right: right != null
                ? const BorderSide(color: Color(0xFF1565C0), width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}