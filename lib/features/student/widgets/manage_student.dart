import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
    // Calcular total acumulado sumando puntosObtenidos de cada evaluación
    final evals = Map<String, dynamic>.from(studentData['evaluaciones'] ?? {});
    final totalAcumulado = evals.values
        .map((e) => (e['puntosObtenidos'] as num? ?? 0).toDouble())
        .fold<double>(0, (a, b) => a + b);

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ← Botón regresar
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

          // ← Tarjeta de información del estudiante
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('clases')
                .doc(claseId)
                .snapshots(),
            builder: (context, snapClase) {
              if (!snapClase.hasData || !snapClase.data!.exists) {
                return const SizedBox.shrink();
              }
              final clase = snapClase.data!.data() as Map<String, dynamic>;
              // trae de Firestore la sección de evaluaciones para este estudiante
              final stuEvals = Map<String, dynamic>.from(
                (clase['estudiantes'] ?? {})[studentId]?['evaluaciones'] ?? {},
              );
              // recalcula el total acumulado de puntosObtenidos
              final totalAcumulado = stuEvals.values
                  .map((e) => (e['puntosObtenidos'] as num? ?? 0).toDouble())
                  .fold<double>(0, (a, b) => a + b);

              final dataClase = snapClase.data!.data() as Map<String, dynamic>;
              final totalClases = dataClase['cantidadClases'] as int? ?? 0;
              final asistMap = Map<String, dynamic>.from(
                (dataClase['estudiantes'] ?? {})[studentId]?['asistenciasClases'] ?? {},
              );
              final totalAsis = asistMap.values.where((v) => v['asistencia'] == true).length;

              // mantén el resto EXACTO, solo sustituye studentData[...] por clase[...] o studentData si procede
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
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
                            fontWeight: FontWeight.bold),
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
                          Text("ID Estudiante: $studentId",
                              style: GoogleFonts.poppins(
                                  color: const Color(0xFF475569))),
                          Text("Email: ${studentData['correo']}",
                              style: GoogleFonts.poppins(
                                  color: const Color(0xFF475569))),
                          Text(
                              "Teléfono: ${studentData['telefono'] ?? '—'}",
                              style: GoogleFonts.poppins(
                                  color: const Color(0xFF475569))),
                          const SizedBox(height: 8),
                          // aquí usamos la variable recalc:
                          Text(
                            'Total Acumulado: ${totalAcumulado.toStringAsFixed(2)} pts',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // (la parte de Total Asistencias igual dentro de este mismo StreamBuilder)
                          Text(
                            'Total Asistencias: $totalAsis/$totalClases',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF0EA5E9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ← Tabs
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
                _buildEvaluacionesSection(context),
                _buildAsistenciasSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluacionesSection(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('clases').doc(claseId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!.data() as Map<String, dynamic>;
        final allEvals = Map<String, dynamic>.from(data['evaluaciones'] ?? {});
        final stuEvals = Map<String, dynamic>.from(
          data['estudiantes']?[studentId]?['evaluaciones'] ?? {},
        );

        if (stuEvals.isEmpty) {
          return Center(
            child: Text(
              'Este estudiante aún no tiene evaluaciones registradas.',
              style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: stuEvals.entries.map((e) {
            final evalId = e.key;
            final notaData = e.value as Map<String, dynamic>;
            final meta = Map<String, dynamic>.from(allEvals[evalId] ?? {});
            final titulo = meta['nombre'] ?? 'Evaluación';
            final tipo = meta['tipo'] ?? '—';
            final fecha = (meta['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();
            final puntosMax = (meta['ponderacion']?['puntos']?.toDouble()) ?? 20.0;
            final nota = (notaData['nota'] as num?)?.toDouble();
            final puntosObtenidos = nota != null ? nota * puntosMax / 20.0 : 0.0;
            final pct = nota != null ? ((nota / 20.0) * 100).round() : null;
            final estado = nota != null ? 'Calificado' : 'Pendiente';
            final estadoColor = nota != null ? const Color(0xFF10B981) : const Color(0xFFEAB308);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  // ← Izquierda
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo,
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        Text(
                          'Tipo: $tipo   Fecha: ${DateFormat('d/M/yyyy').format(fecha)}   '
                              'Ptos: ${puntosObtenidos.toStringAsFixed(0)}/${puntosMax.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: estadoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            estado,
                            style: GoogleFonts.poppins(fontSize: 12, color: estadoColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ← Derecha
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        nota != null
                            ? '${nota.toStringAsFixed(0)}/20'
                            : 'Sin calificar',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (pct != null)
                        Text(
                          '($pct%)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          final notaController = TextEditingController(text: nota?.toString() ?? '');
                          final comentarioController = TextEditingController(text: notaData['comentarios'] ?? '');

                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Editar Nota - $titulo', style: GoogleFonts.poppins()),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: notaController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Nota (0–20)'),
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
                                    if (nuevaNota == null || nuevaNota < 0 || nuevaNota > 20) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('La nota debe ser entre 0 y 20'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    final puntosOb = nuevaNota * puntosMax / 20.0;
                                    await FirebaseFirestore.instance
                                        .collection('clases')
                                        .doc(claseId)
                                        .update({
                                      'estudiantes.$studentId.evaluaciones.$evalId.nota': nuevaNota,
                                      'estudiantes.$studentId.evaluaciones.$evalId.puntosObtenidos': puntosOb,
                                      'estudiantes.$studentId.evaluaciones.$evalId.comentarios':
                                      comentarioController.text.trim(),
                                    });
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                  child: Text('Guardar', style: GoogleFonts.poppins(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFB923C),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
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

  Widget _buildAsistenciasSection(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('clases').doc(claseId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final infoClases = Map<String, dynamic>.from(data['infoClases'] ?? {});
        final asistencias = Map<String, dynamic>.from(
          data['estudiantes']?[studentId]?['asistenciasClases'] ?? {},
        );

        // Estadísticas
        final totalClases = infoClases.length;
        final presentCount = asistencias.values.where((v) => v['asistencia'] == true).length;
        final absentCount = totalClases - presentCount;
        final pct = totalClases > 0 ? ((presentCount / totalClases) * 100).round() : 0;

        // Construcción de la lista de clases
        final clasesList = infoClases.entries.map((e) {
          final partes = (e.value as String).split('/');
          final fecha = DateTime(int.parse(partes[2]), int.parse(partes[1]), int.parse(partes[0]));
          return {
            'key': e.key,
            'fecha': fecha,
            'fechaStr': DateFormat('dd/MM/yyyy').format(fecha),
            'hora': DateFormat('hh:mm a').format(fecha),
          };
        }).toList()
          ..sort((a, b) => (a['fecha'] as DateTime).compareTo(b['fecha'] as DateTime));

        // Agrupar en semanas de 2 en 2
        final semanas = <List<Map<String, dynamic>>>[];
        for (int i = 0; i < clasesList.length; i += 2) {
          semanas.add(clasesList.sublist(i, min(i + 2, clasesList.length)));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título y subtítulo
              Text(
                'Control de Asistencias',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Registro de asistencia por semana y clase',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),

              // Tarjetas de estadísticas
              Row(
                children: [
                  _statCard('Total Clases', '$totalClases', Colors.grey.shade100, const Color(0xFF0F172A)),
                  const SizedBox(width: 12),
                  _statCard('Presentes', '$presentCount', const Color(0xFFDCFCE7), const Color(0xFF166534)),
                  const SizedBox(width: 12),
                  _statCard('Ausentes', '$absentCount', const Color(0xFFFEE2E2), const Color(0xFF9A3412)),
                ],
              ),
              const SizedBox(height: 16),

              // Porcentaje
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Porcentaje de Asistencia:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Detalle por semanas
              for (var idx = 0; idx < semanas.length; idx++) ...[
                Text(
                  'Semana ${idx + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: semanas[idx].map((cls) {
                      final key = cls['key'] as String;
                      final fechaStr = cls['fechaStr'] as String;
                      final horaStr = cls['hora'] as String;
                      final presente = asistencias[key]?['asistencia'] ?? false;

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clase ${key.replaceAll("clase_", "")}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fechaStr,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                horaStr,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Botón clickeable para alternar estado
                              Align(
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  onTap: () async {
                                    final ref = FirebaseFirestore.instance
                                        .collection('clases')
                                        .doc(claseId);
                                    await ref.update({
                                      'estudiantes.$studentId.asistenciasClases.$key.asistencia':
                                      !presente,
                                    });
                                    final snap2 = await ref.get();
                                    final updated = (snap2.data()!['estudiantes']
                                    [studentId]['asistenciasClases']
                                    as Map<String, dynamic>)[key]['asistencia']
                                    as bool;
                                    final total = (snap2.data()!['estudiantes']
                                    [studentId]['asistenciasClases'] as Map)
                                        .values
                                        .where((v) => v['asistencia'] == true)
                                        .length;
                                    await ref.update({
                                      'estudiantes.$studentId.asistencias': total,
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: presente
                                          ? const Color(0xFFDCFCE7)
                                          : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      presente ? 'Presente' : 'Ausente',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: presente
                                            ? const Color(0xFF166534)
                                            : const Color(0xFF9A3412),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }

// Helper para las tarjetas de estadísticas
  Widget _statCard(String label, String value, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: fg)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.poppins(color: fg)),
          ],
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return "NA";
    final parts = name.split(" ");
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return "${parts[0][0]}${parts[1][0]}".toUpperCase();
  }
}
