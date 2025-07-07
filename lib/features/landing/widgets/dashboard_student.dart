import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DashboardStudent extends StatefulWidget {
  const DashboardStudent({super.key});

  @override
  State<DashboardStudent> createState() => _DashboardStudentState();
}

class _DashboardStudentState extends State<DashboardStudent> {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Función para obtener los datos del usuario (estudiante)
  Future<Map<String, dynamic>> _getUserData() async {
    final userSnap =
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    return userSnap.data() ?? {};
  }

  // Función para obtener las clases actuales del estudiante
  Future<List<Map<String, dynamic>>> _getClasesActuales() async {
    final clasesSnap = await FirebaseFirestore.instance
        .collection('clases')
        .where('estudiantes.$uid', isGreaterThan: {})
        .get();

    final clases = clasesSnap.docs.map((e) {
      final data = e.data();
      data['id'] = e.id;
      return data;
    }).toList();

    clases.sort((a, b) {
      final horaA = a['horario']?['horaInicio'] ?? '';
      final horaB = b['horario']?['horaInicio'] ?? '';
      return horaA.compareTo(horaB);
    });

    return clases;
  }

  // Función para obtener las evaluaciones próximas
  Future<List<Map<String, dynamic>>> _getEvaluacionesProximas() async {
    final evaluaciones = <Map<String, dynamic>>[];

    final clasesSnap = await FirebaseFirestore.instance
        .collection('clases')
        .where('estudiantes.$uid', isGreaterThan: {})
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
  }

  // Función para obtener el flujograma del estudiante
  Future<Map<String, dynamic>> _getFlujogramaData(String major) async {
    try {
      // Modificar el campo major para obtener el documento correspondiente en 'flujogramas'
      final flujogramaDocId = major.replaceFirst('ING', 'FLU');
      final flujogramaSnap = await FirebaseFirestore.instance.collection('flujogramas').doc(flujogramaDocId).get();

      if (flujogramaSnap.exists) {
        return flujogramaSnap.data() ?? {};
      }
    } catch (e) {
      print("Error al obtener el flujograma: $e");
    }
    return {}; // Si ocurre un error, devolvemos un mapa vacío
  }

  // Función para calcular el progreso de carrera basado en las materias aprobadas
  Future<double> _getProgresoCarrera() async {
    try {
      final userSnap = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
      final userData = userSnap.data();

      if (userData != null) {
        final major = userData['major'] ?? ''; // Obtener el 'major' del estudiante

        // Sustituir el prefijo para obtener el nombre correcto del flujograma (ej. "ING-SI" a "FLU-SI")
        final flujogramaId = major.replaceFirst(RegExp(r'^[^-]+'), 'FLU'); // Modificar el prefijo aquí

        // Obtener los datos del flujograma usando el prefijo modificado
        final flujogramaData = await _getFlujogramaData(flujogramaId);

        if (flujogramaData.isNotEmpty) {
          // Filtrar las materias aprobadas dentro del flujograma
          final materias = flujogramaData.values.whereType<Map<String, dynamic>>().toList();

          // Verificar si hay materias dentro del flujograma
          if (materias.isEmpty) {
            print('No se encontraron materias en el flujograma');
            return 0.0;
          }

          final totalMaterias = materias.length;
          final materiasAprobadas = materias.where((materia) => materia['estado'] == 'aprobada').length;

          if (totalMaterias > 0) {
            final progreso = (materiasAprobadas / totalMaterias) * 100;
            return progreso; // Retornamos el progreso calculado
          }
        } else {
          print("No se obtuvo datos del flujograma.");
        }
      }
    } catch (e) {
      print("Error al calcular el progreso de carrera: $e");
    }
    return 0.0; // Si ocurre un error, devolvemos 0%
  }

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
        _getProgresoCarrera(),  // Añadimos el cálculo del progreso de carrera
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data![0] as Map<String, dynamic>;
        final clases = snapshot.data![1] as List<Map<String, dynamic>>;
        final evaluaciones = snapshot.data![2] as List<Map<String, dynamic>>;
        final progreso = snapshot.data![3] as double;

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
                          'Bienvenido de vuelta, ${user['fullName']?.toString().trim().isNotEmpty == true ? user['fullName'] : 'Estudiante'}',
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
                  const SizedBox(width: 16),
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
                      'Materias Actuales',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                                // Nombre de la materia en color negro
                                Text(
                                  clase['nombreMateria'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    color: Colors.black, // Color negro
                                  ),
                                ),
                                Text(
                                  '$prof – $aula',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
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
                                // Nombre de la evaluación en color negro
                                Text(
                                  '${eval['nombre']}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    color: Colors.black, // Color negro
                                  ),
                                ),
                                Text(
                                  DateFormat("d 'de' MMMM, yyyy", 'es_ES').format(fecha),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
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
