import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageStudent extends StatelessWidget {
  final Map<String, dynamic> studentData;
  final String studentId;
  final String claseId;

  const ManageStudent({
    super.key,
    required this.studentData,
    required this.studentId,
    required this.claseId,
  });

  @override
  Widget build(BuildContext context) {
    final promedio = studentData['acumulado'] ?? 0;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 12),
            color: Colors.white,
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
                        style: GoogleFonts.poppins(color: const Color(0xFF475569)),
                      ),
                      Text(
                        "Email: ${studentData['correo']}",
                        style: GoogleFonts.poppins(color: const Color(0xFF475569)),
                      ),
                      Text(
                        "Teléfono: ${studentData['telefono'] ?? '—'}",
                        style: GoogleFonts.poppins(color: const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Promedio General: ${promedio.toString()}%',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('clases').doc(claseId).snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || !snapshot.data!.exists) return SizedBox.shrink();

                          final data = snapshot.data!.data() as Map<String, dynamic>;

                          final cantidadClases = data['cantidadClases'] ?? 0;
                          final asistencias = Map<String, dynamic>.from(
                            (data['estudiantes'] ?? {})[studentId]?['asistenciasClases'] ?? {},
                          );

                          final totalAsistencias = asistencias.values.where((v) => v['asistencia'] == true).length;

                          return Text(
                            'Total Asistencias: $totalAsistencias/$cantidadClases',
                            style: GoogleFonts.poppins(
                              color: Color(0xFF0EA5E9),
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const TabBar(
            indicatorColor: Color(0xFFFB923C),
            labelColor: Color(0xFFFB923C),
            unselectedLabelColor: Color(0xFF94A3B8),
            tabs: [
              Tab(text: 'Evaluaciones'),
              Tab(text: 'Asistencias'),
            ],
          ),
          SizedBox(
            height: 500,
            child: TabBarView(
              children: [
                _buildEvaluacionesSection(context, claseId),
                _buildAsistenciasSection(context, claseId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluacionesSection(BuildContext context, String claseId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('clases').doc(claseId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("No se pudo cargar la información."));
        }

        final claseData = snapshot.data!.data() as Map<String, dynamic>;
        final evaluacionesGlobal = Map<String, dynamic>.from(claseData['evaluaciones'] ?? {});
        final estudianteData = Map<String, dynamic>.from(
          (claseData['estudiantes'] ?? {})[studentId] ?? {},
        );
        final evaluacionesAlumno = Map<String, dynamic>.from(estudianteData['evaluaciones'] ?? {});

        if (evaluacionesAlumno.isEmpty) {
          return Center(
            child: Text(
              'Este estudiante aún no tiene evaluaciones registradas.',
              style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: evaluacionesAlumno.entries.map((entry) {
            final evalId = entry.key;
            final notaData = entry.value as Map<String, dynamic>;
            final evalData = Map<String, dynamic>.from(evaluacionesGlobal[evalId] ?? {});

            final titulo = evalData['nombre'] ?? 'Evaluación';
            final modalidad = evalData['modalidad'] ?? '—';
            final fecha = evalData['fecha']?.toDate()?.toString().split(' ')[0] ?? '—';
            final puntosMaximos = (evalData['ponderacion']?['puntos']?.toDouble()) ?? 20.0;
            final nota = notaData['nota'];
            final comentarios = notaData['comentarios'] ?? '';
            final porcentaje = (nota != null) ? ((nota / 20.0) * 100).round() : null;
            final puntosObtenidos = (nota != null) ? (nota * puntosMaximos) / 20.0 : 0.0;

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Modalidad: $modalidad   Fecha: $fecha   Puntos: $puntosObtenidos/$puntosMaximos',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        if (comentarios.isNotEmpty)
                          Text(
                            'Comentarios: $comentarios',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        nota != null ? "$nota/20" : 'Sin calificar',
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
                          final notaController = TextEditingController(text: nota?.toString() ?? '');
                          final comentarioController = TextEditingController(text: comentarios);

                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Editar Nota - $titulo', style: GoogleFonts.poppins()),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: notaController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Nota'),
                                    ),
                                    TextField(
                                      controller: comentarioController,
                                      maxLines: 3,
                                      decoration: const InputDecoration(labelText: 'Comentarios'),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text('Cancelar', style: GoogleFonts.poppins()),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final nuevaNota = double.tryParse(notaController.text.trim());
                                      final nuevoComentario = comentarioController.text.trim();

                                      if (nuevaNota == null || nuevaNota < 0 || nuevaNota > 20) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('La nota debe estar entre 0 y 20.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      await FirebaseFirestore.instance
                                          .collection('clases')
                                          .doc(claseId)
                                          .update({
                                        'estudiantes.$studentId.evaluaciones.$evalId.nota': nuevaNota,
                                        'estudiantes.$studentId.evaluaciones.$evalId.comentarios': nuevoComentario,
                                      });

                                      Navigator.of(context).pop();
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                    child: Text('Guardar', style: GoogleFonts.poppins(color: Colors.white)),
                                  ),
                                ],
                              );
                            },
                          );
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
      },
    );
  }

  Widget _buildAsistenciasSection(BuildContext context, String claseId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('clases').doc(claseId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final claseData = snapshot.data!.data() as Map<String, dynamic>;

        final Map<String, dynamic> infoClases =
        Map<String, dynamic>.from(claseData['infoClases'] ?? {});
        final Map<String, dynamic> asistencias =
        Map<String, dynamic>.from(claseData['estudiantes']?[studentId]?['asistenciasClases'] ?? {});

        // Convertimos a una lista ordenada por fecha
        final List<Map<String, dynamic>> clasesOrdenadas = infoClases.entries.map((entry) {
          final String claseKey = entry.key;
          final String fechaStr = entry.value.toString(); // "23/06/2025"

          final partes = fechaStr.split('/');
          final fecha = DateTime(
            int.parse(partes[2]),
            int.parse(partes[1]),
            int.parse(partes[0]),
          );

          return {
            'claseKey': claseKey,
            'fechaStr': fechaStr,
            'fecha': fecha,
          };
        }).toList()
          ..sort((a, b) => (a['fecha'] as DateTime).compareTo(b['fecha'] as DateTime));

        // Agrupar de 2 en 2 para las semanas
        final List<Widget> widgets = [];

        for (int i = 0; i < clasesOrdenadas.length; i += 2) {
          final semana = (i ~/ 2) + 1;

          // Crear contenedor de la semana
          final List<Widget> semanaClases = [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Semana $semana',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ];

          // Añadir 1 o 2 clases dentro del recuadro
          for (int j = i; j < i + 2 && j < clasesOrdenadas.length; j++) {
            final clase = clasesOrdenadas[j];
            final String claseKey = clase['claseKey']!;
            final String fechaStr = clase['fechaStr']!;
            final String numeroClase = claseKey.replaceAll('clase_', '');
            final bool asistencia = asistencias[claseKey]?['asistencia'] ?? false;

            semanaClases.add(
              CheckboxListTile(
                title: Text(
                  'Clase $numeroClase: $fechaStr',
                  style: GoogleFonts.poppins(),
                ),
                value: asistencia,
                onChanged: (newValue) async {
                  final docRef = FirebaseFirestore.instance.collection('clases').doc(claseId);

                  // Primero, actualizar solo la asistencia de esta clase
                  await docRef.update({
                    'estudiantes.$studentId.asistenciasClases.$claseKey.asistencia': newValue,
                  });

                  // Luego, volver a leer el documento completo
                  final snapshot = await docRef.get();
                  if (!snapshot.exists) return;

                  final data = snapshot.data() as Map<String, dynamic>;
                  final asistencias = Map<String, dynamic>.from(
                    data['estudiantes']?[studentId]?['asistenciasClases'] ?? {},
                  );

                  // Contar todas las asistencias marcadas como true
                  int total = asistencias.values.where((v) => v['asistencia'] == true).length;

                  // Actualizar el campo 'asistencias' del estudiante
                  await docRef.update({
                    'estudiantes.$studentId.asistencias': total,
                  });
                },
              ),
            );
          }

          widgets.add(
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: semanaClases,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: widgets,
        );
      },
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "NA";
    final parts = name.split(" ");
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return "${parts[0][0]}${parts[1][0]}".toUpperCase();
  }
}
