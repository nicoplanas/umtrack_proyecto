import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class EvaluacionesTab extends StatelessWidget {
  final String claseId;

  const EvaluacionesTab({super.key, required this.claseId});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('clases').doc(claseId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final evaluaciones = data['evaluaciones'] as Map<String, dynamic>? ?? {};

              if (evaluaciones.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment, size: 80, color: Color(0xFFFB923C)), // Naranja como en el icono de estudiantes
                      const SizedBox(height: 16),
                      Text(
                        'No hay evaluaciones registradas',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B), // Gris oscuro
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          final String newId = const Uuid().v4();
                          _showEditDialog(context, claseId, newId, {});
                        },
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Agregar evaluación'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFB923C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          textStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final entries = evaluaciones.entries.toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar evaluación...',
                              prefixIcon: const Icon(Icons.search),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            onChanged: (value) {
                              // Aquí podrías filtrar si deseas
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            final String newId = const Uuid().v4();
                            _showEditDialog(context, claseId, newId, {});
                          },
                          child: const Icon(
                            Icons.add,
                            size: 28,
                            color: Color(0xFFFB923C), // Naranja
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
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
                                    icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                                    onPressed: () async {
                                      try {
                                        final claseRef = FirebaseFirestore.instance.collection('clases').doc(claseId);

                                        // Obtener los estudiantes actuales
                                        final claseSnapshot = await claseRef.get();
                                        final claseData = claseSnapshot.data() as Map<String, dynamic>;
                                        final estudiantes = claseData['estudiantes'] as Map<String, dynamic>? ?? {};

                                        // Crear una operación en batch
                                        final batch = FirebaseFirestore.instance.batch();

                                        // Eliminar evaluación del campo principal
                                        batch.update(claseRef, {'evaluaciones.$evalId': FieldValue.delete()});

                                        // Eliminar evaluación de cada estudiante
                                        for (final studentId in estudiantes.keys) {
                                          batch.update(claseRef, {
                                            'estudiantes.$studentId.evaluaciones.$evalId': FieldValue.delete(),
                                          });
                                        }

                                        await batch.commit();
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error al borrar evaluación: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF0F172A)),
                                    onPressed: () => _showEditDialog(context, claseId, evalId, evaluacion),
                                  ),
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
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

void _showEditDialog(BuildContext context, String claseId, String evalId, Map<String, dynamic> data) {
  final nombreController = TextEditingController(text: data['nombre'] ?? '');
  final modalidadController = TextEditingController(text: data['modalidad'] ?? '');
  final tiempoController = TextEditingController(text: data['duracion']?['tiempo']?.toString() ?? '');
  final unidadController = TextEditingController(text: data['duracion']?['unidad'] ?? 'minutos');
  final porcentajeController = TextEditingController(text: data['ponderacion']?['porcentaje']?.toString() ?? '');
  final puntosController = TextEditingController(text: data['ponderacion']?['puntos']?.toString() ?? '');
  final temasController = TextEditingController(text: data['temas'] ?? '');

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
                      try {
                        final evaluacionData = {
                          'nombre': nombreController.text,
                          'modalidad': modalidadController.text,
                          'duracion': {
                            'tiempo': int.tryParse(tiempoController.text) ?? 0,
                            'unidad': unidadController.text,
                          },
                          'ponderacion': {
                            'porcentaje': int.tryParse(porcentajeController.text) ?? 0,
                            'puntos': int.tryParse(puntosController.text) ?? 0,
                          },
                          'temas': temasController.text,
                          'fecha': DateTime.now(),
                        };

                        final claseRef = FirebaseFirestore.instance.collection('clases').doc(claseId);

                        // Guardar evaluación en la colección de evaluaciones
                        await claseRef.update({
                          'evaluaciones.$evalId': evaluacionData,
                        });

                        // Obtener los estudiantes
                        final claseSnapshot = await claseRef.get();
                        final claseData = claseSnapshot.data() as Map<String, dynamic>;
                        final estudiantes = claseData['estudiantes'] as Map<String, dynamic>? ?? {};

                        // Actualizar a cada estudiante con solo nota y comentarios vacíos
                        final batch = FirebaseFirestore.instance.batch();

                        estudiantes.forEach((studentId, _) {
                          batch.update(claseRef, {
                            'estudiantes.$studentId.evaluaciones.$evalId': {
                              'nota': null,
                              'comentarios': '',
                            }
                          });
                        });

                        await batch.commit();
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al guardar la evaluación: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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
