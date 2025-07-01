import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EvaluationDetails extends StatelessWidget {
  final String claseId;
  final String evalId;

  const EvaluationDetails({
    Key? key,
    required this.claseId,
    required this.evalId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clases')
          .doc(claseId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());

        final claseData = snap.data!.data() as Map<String, dynamic>;
        final evalMap = (claseData['evaluaciones'] as Map)[evalId]
        as Map<String, dynamic>;

        final nombre = evalMap['nombre'] as String? ?? '';
        final fechaTs = evalMap['fecha'] as Timestamp;
        final fecha = fechaTs.toDate();
        final modalidad = evalMap['modalidad'] as String? ?? '';
        final dur = evalMap['duracion'] as Map<String, dynamic>;
        final pond = evalMap['ponderacion'] as Map<String, dynamic>;
        final temas = evalMap['temas'] as String? ?? '';
        final estudiantes =
            claseData['estudiantes'] as Map<String, dynamic>? ?? {};

        // cálculo rápido de promedio
        final notas = estudiantes.values
            .map((stu) =>
        (stu['evaluaciones'] as Map)[evalId]?['nota'])
            .whereType<num>()
            .map((n) => n.toDouble())
            .toList();
        final avg = notas.isEmpty
            ? 0.0
            : notas.reduce((a, b) => a + b) / notas.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ← Botón de volver atrás
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),

              // Nombre de la evaluación
              Text(
                nombre,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // ← Detalles en texto negro
              Text(
                'Fecha: ${DateFormat.yMMMMd('es').add_jm().format(fecha)}',
                style: GoogleFonts.poppins(color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text('Modalidad: $modalidad',
                  style: GoogleFonts.poppins(color: Colors.black)),
              const SizedBox(height: 4),
              Text('Duración: ${dur['tiempo']} ${dur['unidad']}',
                  style: GoogleFonts.poppins(color: Colors.black)),
              const SizedBox(height: 4),
              Text(
                'Ponderación: ${pond['porcentaje']}% (${pond['puntos']} pts)',
                style: GoogleFonts.poppins(color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text('Temas: $temas',
                  style: GoogleFonts.poppins(color: Colors.black)),

              // ← Divider para separar secciones
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(thickness: 1),
              ),

              // Asignar notas
              Text(
                'Asignar notas',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              ...estudiantes.entries.map((e) {
                final sid = e.key;
                final stu = e.value as Map<String, dynamic>;
                final current =
                (stu['evaluaciones'] as Map)[evalId]?['nota'];
                final controller =
                TextEditingController(text: current?.toString() ?? '');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(stu['nombre'] ?? '',
                          style: GoogleFonts.poppins(color: Colors.black)),
                      const Spacer(),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '%',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                          ),
                          onSubmitted: (val) async {
                            final n = double.tryParse(val) ?? 0.0;
                            await FirebaseFirestore.instance
                                .collection('clases')
                                .doc(claseId)
                                .update({
                              'estudiantes.$sid.evaluaciones.$evalId.nota': n,
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(thickness: 1),
              ),

              // Reporte rápido
              Text(
                'Reporte rápido',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text('Cantidad de notas: ${notas.length}',
                  style: GoogleFonts.poppins(color: Colors.black)),
              const SizedBox(height: 4),
              Text('Promedio: ${avg.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(color: Colors.black)),
            ],
          ),
        );
      },
    );
  }
}
