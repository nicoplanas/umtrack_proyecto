import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ClassesDetailsProfessor extends StatelessWidget {
  final String claseId;
  final Map<String, dynamic> claseData; // <-- NUEVO CAMPO

  const ClassesDetailsProfessor({
    super.key,
    required this.claseId,
    required this.claseData, // <-- NUEVO PARAMETRO REQUERIDO
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          title: const Text(''),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
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
        ),
        body: TabBarView(
          children: [
            _buildStudentsTab(),
            Center(child: Text('Evaluaciones')), // Placeholder
            Center(child: Text('Tareas')), // Placeholder
            Center(child: Text('Reportes')), // Placeholder
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsTab() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('clases').doc(claseId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.hasError) {
          return const Center(child: Text('No se pudo cargar la clase.'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final estudiantes = data['estudiantes'] as Map<String, dynamic>? ?? {};

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['nombreMateria'] ?? 'Materia',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lista completa de los estudiantes del curso',
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              ...estudiantes.entries.map((entry) {
                final nombre = entry.value['nombre'] ?? 'Estudiante';
                final acumulado = entry.value['acumulado'];
                final avatarColor = entry.value['color'] ?? Colors.greenAccent;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                      Text(
                        acumulado != null ? "$acumulado%" : 'Pendiente',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: acumulado != null ? const Color(0xFFFB923C) : const Color(0xFF94A3B8),
                        ),
                      )
                    ],
                  ),
                );
              }).toList()
            ],
          ),
        );
      },
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
