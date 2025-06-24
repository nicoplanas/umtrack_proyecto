import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EvaluacionesTab extends StatelessWidget {
  final String claseId;

  const EvaluacionesTab({super.key, required this.claseId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('clases').doc(claseId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final evaluaciones = data['evaluaciones'] as Map<String, dynamic>? ?? {};

        if (evaluaciones.isEmpty) {
          return Center(
            child: Text(
              'No hay evaluaciones registradas.',
              style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
            ),
          );
        }

        final entries = evaluaciones.entries.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final evalId = entries[index].key;
            final evaluacion = entries[index].value as Map<String, dynamic>;

            final nombre = evaluacion['nombre'] ?? 'Sin nombre';
            final rawFecha = evaluacion['fecha'];
            String fechaFormateada = '—';

            if (rawFecha is Timestamp) {
              final dateTime = rawFecha.toDate();
              fechaFormateada = DateFormat("d 'de' MMMM 'de' y, h:mm a", 'es_ES').format(dateTime);
            } else if (rawFecha is String) {
              fechaFormateada = rawFecha;
            }

            final modalidad = evaluacion['modalidad'] ?? '—';
            final duracion = evaluacion['duracion'] ?? {};
            final tiempo = duracion['tiempo']?.toString() ?? '—';
            final unidad = duracion['unidad'] ?? 'minutos';

            final ponderacion = evaluacion['ponderacion'] ?? {};
            final porcentaje = ponderacion['porcentaje']?.toString() ?? '—';
            final puntos = ponderacion['puntos']?.toString() ?? '—';

            final temas = evaluacion['temas'] ?? 'No especificados';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nombre,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF0F172A)),
                        onPressed: () {
                          final nombreController = TextEditingController(text: nombre);
                          final modalidadController = TextEditingController(text: modalidad);
                          final tiempoController = TextEditingController(text: tiempo);
                          final unidadController = TextEditingController(text: unidad);
                          final porcentajeController = TextEditingController(text: porcentaje);
                          final puntosController = TextEditingController(text: puntos);
                          final temasController = TextEditingController(text: temas);

                          showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Editar evaluación',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      _styledTextField(nombreController, 'Nombre'),
                                      _styledTextField(modalidadController, 'Modalidad'),
                                      _styledTextField(tiempoController, 'Duración'),
                                      _styledTextField(unidadController, 'Unidad'),
                                      _styledTextField(porcentajeController, 'Porcentaje'),
                                      _styledTextField(puntosController, 'Puntos'),
                                      _styledTextField(temasController, 'Temas'),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancelar', style: TextStyle(color: Colors.black87)),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () async {
                                              await FirebaseFirestore.instance
                                                  .collection('clases')
                                                  .doc(claseId)
                                                  .update({
                                                'evaluaciones.$evalId.nombre': nombreController.text,
                                                'evaluaciones.$evalId.modalidad': modalidadController.text,
                                                'evaluaciones.$evalId.duracion.tiempo':
                                                int.tryParse(tiempoController.text) ?? 0,
                                                'evaluaciones.$evalId.duracion.unidad': unidadController.text,
                                                'evaluaciones.$evalId.ponderacion.porcentaje':
                                                int.tryParse(porcentajeController.text) ?? 0,
                                                'evaluaciones.$evalId.ponderacion.puntos':
                                                int.tryParse(puntosController.text) ?? 0,
                                                'evaluaciones.$evalId.temas': temasController.text,
                                              });
                                              Navigator.pop(context);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFB923C),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                              textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                            ),
                                            child: const Text('Guardar'),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Fecha: $fechaFormateada', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text('Modalidad: $modalidad', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text('Duración: $tiempo $unidad', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text('Ponderación: $porcentaje% ($puntos puntos)', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text('Temas: $temas', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B))),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Widget _styledTextField(TextEditingController controller, String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: controller,
      style: GoogleFonts.poppins(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.black87),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    ),
  );
}
