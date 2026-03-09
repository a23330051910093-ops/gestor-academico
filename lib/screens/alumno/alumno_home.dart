import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'escanear_qr_screen.dart';
import 'mi_asistencia_screen.dart';
import 'mis_calificaciones_screen.dart';

class AlumnoHome extends StatelessWidget {
  const AlumnoHome({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final bool esPadre = authService.userRole == 'padre';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              esPadre ? 'Portal de Padres' : 'Mi Portal',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              authService.userName ?? '',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text('¿Estás seguro que deseas salir?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Salir',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                if (context.mounted) {
                  Provider.of<AuthService>(context, listen: false).signOut();
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final bool isLandscape = orientation == Orientation.landscape;
            final bool esPadre = authService.userRole == 'padre';

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.all(isLandscape ? 12.0 : 20.0),
                child: isLandscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildWelcomeCard(
                                authService, esPadre, isLandscape),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: _buildModuleCards(
                                context, esPadre, authService),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeCard(authService, esPadre, isLandscape),
                          const SizedBox(height: 24),
                          const Text(
                            'Mis módulos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildModuleCards(context, esPadre, authService),
                          const SizedBox(height: 16),
                          _buildReadOnlyBadge(),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(
      AuthService authService, bool esPadre, bool isLandscape) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLandscape ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.school_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            esPadre
                ? 'Bienvenido, ${authService.userName ?? ''}'
                : 'Hola, ${authService.userName ?? ''}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            esPadre
                ? 'Consulta el progreso de tu hijo'
                : 'Consulta tus calificaciones y asistencias',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCards(
      BuildContext context, bool esPadre, AuthService authService) {
    return Column(
      children: [

        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MiAsistenciaScreen(
                alumnoIdOverride: esPadre
                    ? authService.alumnoIdHijo
                    : null,
              ),
            ),
          ),
          child: _InfoCard(
            icon: Icons.fact_check_rounded,
            color: const Color(0xFF2E7D32),
            title: esPadre ? 'Asistencia de mi hijo' : 'Mi Asistencia',
            subtitle: esPadre
                ? 'Consulta el historial de asistencias de tu hijo'
                : 'Consulta tu historial de asistencias por materia',
          ),
        ),

        const SizedBox(height: 12),

        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MisCalificacionesScreen(
                alumnoIdOverride: esPadre
                    ? authService.alumnoIdHijo
                    : null,
              ),
            ),
          ),
          child: _InfoCard(
            icon: Icons.grade_rounded,
            color: const Color(0xFF6A1B9A),
            title: esPadre ? 'Calificaciones de mi hijo' : 'Mis Calificaciones',
            subtitle: esPadre
                ? 'Consulta las calificaciones de tu hijo'
                : 'Revisa tus calificaciones y retroalimentación',
          ),
        ),

        if (!esPadre) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EscanearQRScreen(),
              ),
            ),
            child: _InfoCard(
              icon: Icons.qr_code_scanner_rounded,
              color: const Color(0xFFE65100),
              title: 'Registrar Asistencia',
              subtitle: 'Escanea el código QR que muestre tu maestro',
            ),
          ),
        ],

        const SizedBox(height: 12),
        _buildReadOnlyBadge(),
      ],
    );
  }

  Widget _buildReadOnlyBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade400, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Este portal es de solo consulta. '
              'No puedes modificar ningún dato.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}