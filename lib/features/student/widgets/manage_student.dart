import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageStudent extends StatelessWidget {
  final Map<String, dynamic> studentData;
  final String studentId;

  const ManageStudent({
    super.key,
    required this.studentData,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final promedio = studentData['acumulado'] ?? 0;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 12),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Volver a Lista de Estudiantes',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Tarjeta del estudiante
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF34D399),
                  child: Text(
                    _getInitials(studentData['nombre']),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentData['nombre'] ?? 'Estudiante',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ID Estudiante: $studentId",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF475569), // gris oscuro
                        ),
                      ),
                      Text(
                        "Email: ${studentData['correo']}",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF475569),
                        ),
                      ),
                      Text(
                        "Teléfono: ${studentData['telefono'] ?? '—'}",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Promedio General: ${promedio.toString()}%',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          const TabBar(
            indicatorColor: Color(0xFFFB923C),
            labelColor: Color(0xFFFB923C),
            unselectedLabelColor: Color(0xFF94A3B8),
            tabs: [
              Tab(text: 'Asistencias'),
              Tab(text: 'Evaluaciones'),
            ],
          ),

          // TabBarView con altura limitada
          Container(
            height: 400, // Ajusta según necesidad o usa MediaQuery
            child: TabBarView(
              children: [
                Center(child: Text('Aquí irían las asistencias')),
                _buildEvaluacionesSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluacionesSection(BuildContext context) {
    final evaluaciones = Map<String, dynamic>.from(studentData['evaluaciones'] ?? {});

    return ListView(
      padding: const EdgeInsets.all(16),
      children: evaluaciones.entries.map((entry) {
        final data = entry.value as Map<String, dynamic>;
        final estado = data['estado'] ?? 'pendiente';
        final nota = data['nota'];
        final puntajeMaximo = data['maximo'] ?? 100;
        final porcentaje = (nota != null && puntajeMaximo > 0)
            ? ((nota / puntajeMaximo) * 100).round()
            : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['titulo'] ?? 'Evaluación',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tipo: ${data['tipo'] ?? '—'}   Fecha: ${data['fecha'] ?? '—'}   Puntos máximos: $puntajeMaximo',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: estado == 'calificado' ? const Color(0xFFD1FAE5) : const Color(0xFFFDE68A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        estado == 'calificado' ? 'Calificado' : 'Pendiente',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: estado == 'calificado' ? const Color(0xFF065F46) : const Color(0xFF92400E),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              // Nota y botón
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    nota != null ? "$nota/$puntajeMaximo" : 'Sin calificar',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  if (porcentaje != null)
                    Text(
                      "($porcentaje%)",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFB923C),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    onPressed: () {
                      // TODO: implementar edición
                    },
                    child: Text(
                      'Editar Nota',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "NA";
    final parts = name.split(" ");
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return "${parts[0][0]}${parts[1][0]}".toUpperCase();
  }
}
