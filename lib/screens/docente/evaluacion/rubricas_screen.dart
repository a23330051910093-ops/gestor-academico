import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../services/auth_service.dart';
import '../../../services/rubrica_service.dart';
import '../../../services/gestion_service.dart';
import '../../../models/rubrica_model.dart';
import '../../../models/materia_model.dart';
import '../../../models/grupo_model.dart';
import '../../../models/semestre_model.dart';

class RubricasScreen extends StatelessWidget {
  const RubricasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final gestionService = GestionService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mis Rúbricas'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Semestre>>(
        stream: gestionService.getSemestres(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final semestres = snapshot.data ?? [];
          if (semestres.isEmpty) {
            return const Center(
              child: Text('No tienes semestres registrados',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: semestres.length,
            itemBuilder: (context, index) {
              final semestre = semestres[index];
              return _SemestreExpansion(
                semestre: semestre,
                gestionService: gestionService,
              );
            },
          );
        },
      ),
    );
  }
}

class _SemestreExpansion extends StatelessWidget {
  final Semestre semestre;
  final GestionService gestionService;

  const _SemestreExpansion({
    required this.semestre,
    required this.gestionService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.calendar_month_rounded,
            color: Color(0xFF1565C0)),
        title: Text(semestre.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          StreamBuilder<List<Grupo>>(
            stream: gestionService.getGrupos(semestre.id),
            builder: (context, snapshot) {
              final grupos = snapshot.data ?? [];
              if (grupos.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sin grupos',
                      style: TextStyle(color: Colors.grey)),
                );
              }
              return Column(
                children: grupos
                    .map((g) => _GrupoExpansion(
                          grupo: g,
                          gestionService: gestionService,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GrupoExpansion extends StatelessWidget {
  final Grupo grupo;
  final GestionService gestionService;

  const _GrupoExpansion({
    required this.grupo,
    required this.gestionService,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: ExpansionTile(
        leading:
            const Icon(Icons.group_rounded, color: Color(0xFF2E7D32)),
        title: Text(grupo.nombre),
        children: [
          StreamBuilder<List<Materia>>(
            stream: gestionService.getMaterias(grupo.id),
            builder: (context, snapshot) {
              final materias = snapshot.data ?? [];
              if (materias.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sin materias',
                      style: TextStyle(color: Colors.grey)),
                );
              }
              return Column(
                children: materias
                    .map((m) => _MateriaRubricas(materia: m))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MateriaRubricas extends StatelessWidget {
  final Materia materia;

  const _MateriaRubricas({required this.materia});

  @override
  Widget build(BuildContext context) {
    final rubricaService = RubricaService();

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: ExpansionTile(
        leading:
            const Icon(Icons.book_rounded, color: Color(0xFF6A1B9A)),
        title: Text(materia.nombre),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: Color(0xFF1565C0)),
              onPressed: () =>
                  _mostrarDialogoCrear(context, rubricaService),
              tooltip: 'Nueva rúbrica',
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          StreamBuilder<List<Rubrica>>(
            stream: rubricaService.getRubricas(materia.id),
            builder: (context, snapshot) {
              final rubricas = snapshot.data ?? [];
              if (rubricas.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sin rúbricas. Toca + para crear una.',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                );
              }
              return Column(
                children: rubricas
                    .map((r) => _RubricaCard(
                          rubrica: r,
                          rubricaService: rubricaService,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCrear(
      BuildContext context, RubricaService rubricaService) {
    final authService =
        Provider.of<AuthService>(context, listen: false);
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final List<Map<String, dynamic>> criterios = [];
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          int totalPeso =
              criterios.fold(0, (s, c) => s + (c['peso'] as int));

          return AlertDialog(
            title: const Text('Nueva Rúbrica'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de la rúbrica',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descripcionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Descripción (opcional)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Criterios
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Criterios (${totalPeso}% de 100%)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: totalPeso == 100
                                ? Colors.green
                                : totalPeso > 100
                                    ? Colors.red
                                    : Colors.orange,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              _agregarCriterio(context, setState, criterios),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Agregar'),
                        ),
                      ],
                    ),

                    if (criterios.isEmpty)
                      const Text(
                        'Agrega al menos un criterio',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 12),
                      ),

                    ...criterios.asMap().entries.map((entry) {
                      final i = entry.key;
                      final c = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          title: Text(c['nombre'],
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text(c['descripcion'],
                              style: const TextStyle(fontSize: 11)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${c['peso']}%',
                                  style: const TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                onPressed: () => setState(
                                    () => criterios.removeAt(i)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isLoading ||
                        nombreController.text.isEmpty ||
                        criterios.isEmpty ||
                        totalPeso != 100
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        final uuid = const Uuid();
                        final rubrica = Rubrica(
                          id: '',
                          nombre: nombreController.text.trim(),
                          descripcion:
                              descripcionController.text.trim(),
                          docenteId:
                              authService.currentUser!.uid,
                          materiaId: materia.id,
                          criterios: criterios
                              .map((c) => CriterioRubrica(
                                    id: uuid.v4(),
                                    nombre: c['nombre'],
                                    descripcion: c['descripcion'],
                                    peso: c['peso'],
                                  ))
                              .toList(),
                          fechaCreacion: DateTime.now(),
                        );
                        await rubricaService.crearRubrica(rubrica);
                        if (context.mounted) Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _agregarCriterio(BuildContext context, StateSetter setState,
      List<Map<String, dynamic>> criterios) {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final pesoController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo Criterio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre del criterio',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descripcionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pesoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Peso (%)',
                helperText: 'Todos los criterios deben sumar 100%',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombreController.text.isEmpty ||
                  pesoController.text.isEmpty) return;
              final peso = int.tryParse(pesoController.text) ?? 0;
              if (peso <= 0 || peso > 100) return;

              setState(() {
                criterios.add({
                  'nombre': nombreController.text.trim(),
                  'descripcion': descripcionController.text.trim(),
                  'peso': peso,
                });
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}

class _RubricaCard extends StatelessWidget {
  final Rubrica rubrica;
  final RubricaService rubricaService;

  const _RubricaCard({
    required this.rubrica,
    required this.rubricaService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        leading: const Icon(Icons.checklist_rounded,
            color: Color(0xFF6A1B9A), size: 20),
        title: Text(rubrica.nombre,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${rubrica.criterios.length} criterios',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.red),
              onPressed: () => _confirmarEliminar(context),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: rubrica.criterios
            .map((c) => ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24),
                  leading: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${c.peso}%',
                      style: const TextStyle(
                        color: Color(0xFF6A1B9A),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(c.nombre,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: c.descripcion.isNotEmpty
                      ? Text(c.descripcion,
                          style: const TextStyle(fontSize: 11))
                      : null,
                ))
            .toList(),
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar rúbrica'),
        content: Text(
            '¿Eliminar "${rubrica.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await rubricaService.eliminarRubrica(rubrica.id);
    }
  }
}