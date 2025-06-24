import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ClassesDetailsProfessor extends StatelessWidget {
  final String claseId;
  final Map<String, dynamic> claseData;

  const ClassesDetailsProfessor({
    super.key,
    required this.claseId,
    required this.claseData,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // TopBar con botón, texto y título integrado
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Volver a Asignaturas',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    claseData['nombreMateria'] ?? 'Materia',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const TabBar(
            labelColor: Color(0xFFFB923C),
            unselectedLabelColor: Color(0xFF94A3B8),
            indicatorColor: Color(0xFFFB923C),
            tabs: [
              Tab(text: 'Estudiantes'),
              Tab(text: 'Evaluaciones'),
              Tab(text: 'Tareas'),
              Tab(text: 'Reportes'),
            ],
          ),

          SizedBox(
            height: 500,
            child: TabBarView(
              children: [
                StudentsTab(claseId: claseId),
                Center(child: Text('Evaluaciones')),
                Center(child: Text('Tareas')),
                Center(child: Text('Reportes')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Reemplaza tu clase StudentsTab completa por esta:

class StudentsTab extends StatefulWidget {
  final String claseId;

  const StudentsTab({super.key, required this.claseId});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic> _estudiantes = {};
  List<MapEntry<String, dynamic>> _filteredEstudiantes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterEstudiantes);
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance.collection('clases').doc(widget.claseId).get();
    final data = doc.data() as Map<String, dynamic>?;

    if (data != null) {
      final estudiantes = data['estudiantes'] as Map<String, dynamic>? ?? {};
      setState(() {
        _estudiantes = estudiantes;
        _filteredEstudiantes = estudiantes.entries.toList();
      });
    }
  }

  void _filterEstudiantes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEstudiantes = _estudiantes.entries
          .where((e) => (e.value['nombre'] ?? '').toString().toLowerCase().contains(query))
          .toList();
    });
  }

  void _addEstudiante() {
    final nombreCtrl = TextEditingController();
    final acumuladoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nuevo estudiante"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: acumuladoCtrl, decoration: const InputDecoration(labelText: "Acumulado %")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = DateTime.now().millisecondsSinceEpoch.toString();
              final newData = {
                'nombre': nombreCtrl.text,
                'acumulado': int.tryParse(acumuladoCtrl.text),
                'color': '#60A5FA'
              };
              final ref = FirebaseFirestore.instance.collection('clases').doc(widget.claseId);
              await ref.update({'estudiantes.$id': newData});
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEstudiante(String id) async {
    final ref = FirebaseFirestore.instance.collection('clases').doc(widget.claseId);
    await ref.update({'estudiantes.$id': FieldValue.delete()});
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _estudiantes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lista completa de los estudiantes del curso',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Buscar estudiante...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1, color: Color(0xFFFB923C), size: 28),
                      onPressed: _addEstudiante,
                      tooltip: 'Agregar estudiante',
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Total: ${_filteredEstudiantes.length} estudiante${_filteredEstudiantes.length == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredEstudiantes.length,
                    itemBuilder: (context, index) {
                      final entry = _filteredEstudiantes[index];
                      final id = entry.key;
                      final nombre = entry.value['nombre'] ?? 'Estudiante';
                      final acumulado = entry.value['acumulado'];
                      final avatarColor = entry.value['color'] ?? Colors.greenAccent;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: _parseColor(avatarColor),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombre,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Ver detalles',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  acumulado != null ? "$acumulado%" : 'Pendiente',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: acumulado != null
                                        ? (acumulado >= 90
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFFB923C))
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                                  onPressed: () => _deleteEstudiante(id),
                                )
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _parseColor(dynamic value) {
    if (value is int) return Color(value);
    if (value is String && value.startsWith('#')) {
      return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
    }
    return Colors.grey;
  }
}