import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DashboardProfessor extends StatefulWidget {
  const DashboardProfessor({super.key});

  @override
  State<DashboardProfessor> createState() => _DashboardProfessorState();
}

class _DashboardProfessorState extends State<DashboardProfessor> {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Función para obtener los datos del usuario (profesor)
  Future<Map<String, dynamic>> _getUserData() async {
    final userSnap = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    return userSnap.data() ?? {};
  }

  // Función para obtener las clases que dicta el profesor
  Future<List<Map<String, dynamic>>> _getClasesActuales() async {
    try {
      final clasesSnap = await FirebaseFirestore.instance
          .collection('clases')
          .where('profesorId', isEqualTo: uid) // Verifica que 'profesorId' esté correctamente asignado
          .get();

      if (clasesSnap.docs.isEmpty) {
        print("No se encontraron clases para este profesor.");
        return []; // No hay clases disponibles para el profesor
      }

      final clases = clasesSnap.docs.map((e) {
        final data = e.data();
        data['id'] = e.id;
        return data;
      }).toList();

      // Ordenamos las clases por la hora de inicio (si la hora no está vacía)
      clases.sort((a, b) {
        final horaA = a['horario']?['horaInicio'] ?? '';
        final horaB = b['horario']?['horaInicio'] ?? '';
        return horaA.compareTo(horaB);
      });

      return clases;
    } catch (e) {
      print('Error al obtener las clases: $e');
      return [];
    }
  }

  // Función para obtener las evaluaciones próximas
  Future<List<Map<String, dynamic>>> _getEvaluacionesProximas() async {
    try {
      final evaluaciones = <Map<String, dynamic>>[];

      final clasesSnap = await FirebaseFirestore.instance
          .collection('clases')
          .where('profesorId', isEqualTo: uid) // Verifica que 'profesorId' esté correctamente asignado
          .get();

      for (final doc in clasesSnap.docs) {
        final data = doc.data();
        final evaluacionesMap = data['evaluaciones'] as Map<String, dynamic>? ?? {};

        evaluacionesMap.forEach((id, eval) {
          if (eval['fecha'] is Timestamp) {
            final fecha = (eval['fecha'] as Timestamp).toDate();
            if (fecha.isAfter(DateTime.now())) {
              evaluaciones.add({
                'nombre': eval['nombre'],
                'fecha': fecha,
                'clase': data['nombreMateria'],
              });
            }
          }
        });
      }

      evaluaciones.sort((a, b) => a['fecha'].compareTo(b['fecha']));
      return evaluaciones;
    } catch (e) {
      print('Error al obtener las evaluaciones: $e');
      return [];
    }
  }

  // Función para calcular los días restantes
  String _diasRestantes(DateTime fecha) {
    final diferencia = fecha.difference(DateTime.now()).inDays;
    return 'En $diferencia ${diferencia == 1 ? "día" : "días"}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        _getUserData(),
        _getClasesActuales(),
        _getEvaluacionesProximas(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data![0] as Map<String, dynamic>;
        final clases = snapshot.data![1] as List<Map<String, dynamic>>;
        final evaluaciones = snapshot.data![2] as List<Map<String, dynamic>>;

        final proximaClase = clases.isNotEmpty ? clases.first : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenido de vuelta, ${user['fullName']?.toString().trim().isNotEmpty == true ? user['fullName'] : 'Profesor'}',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            text: 'Tu próxima clase es ',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: const Color(0xFF64748B),
                            ),
                            children: [
                              TextSpan(
                                text: proximaClase != null
                                    ? proximaClase['nombreMateria']
                                    : 'ninguna',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: const Color(0xFFFF8C00),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Materias Impartidas',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,  // Cambié el color del texto a negro
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (clases.isEmpty)
                      Text(
                        "No estás asignado a ninguna materia.",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.red,  // Este se mantiene rojo si quieres mantenerlo así
                        ),
                      )
                    else
                      ...clases.map((clase) {
                        final hora = clase['horario']?['horaInicio'] ?? '';
                        final prof = clase['profesorNombre'] ?? '';
                        final aula = clase['aula'] ?? '';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clase['nombreMateria'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                      color: Colors.black,  // Cambié el color a negro
                                    ),
                                  ),
                                  Text(
                                    '$prof – $aula',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.black,  // Cambié el color a negro
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                hora,
                                style: GoogleFonts.poppins(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Próximas Evaluaciones',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...evaluaciones.map((eval) {
                      final fecha = eval['fecha'] as DateTime;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${eval['nombre']}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    color: Colors.black,  // Cambié el color a negro
                                  ),
                                ),
                                Text(
                                  DateFormat("d 'de' MMMM, yyyy", 'es_ES').format(fecha),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.black,  // Cambié el color a negro
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEDD5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _diasRestantes(fecha),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFFFD8305),
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
