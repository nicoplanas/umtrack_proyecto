import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:umtrack/features/classes/widgets/class.dart';

class Classes extends StatefulWidget {
  const Classes({super.key});

  @override
  State<Classes> createState() => _ClassesState();
}

class _ClassesState extends State<Classes> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late Future<List<Map<String, dynamic>>> _clasesDelUsuario;

  @override
  void initState() {
    super.initState();
    _clasesDelUsuario = _cargarClasesDelUsuario();
  }

  Future<List<Map<String, dynamic>>> _cargarClasesDelUsuario() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final querySnapshot = await _firestore.collection('clases').get();

    final clasesUsuario = querySnapshot.docs.where((doc) {
      final data = doc.data();
      final estudiantes = data['estudiantes'] as Map<String, dynamic>?;

      return data['estado'] == 'activa' &&
          estudiantes != null &&
          estudiantes.containsKey(user.uid);
    }).map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    return clasesUsuario;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _clasesDelUsuario,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final clases = snapshot.data ?? [];

        if (clases.isEmpty) {
          return const Center(child: Text('No estás inscrito en ninguna clase activa.'));
        }

        return Container(
          color: Colors.white,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: clases.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  color: const Color(0xFFF8FAFC),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis Asignaturas',
                        style: GoogleFonts.poppins(
                          fontSize: 35,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Selecciona una materia para ver tus evaluaciones y calificaciones',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final clase = clases[index - 1];
              final horario = clase['horario'] as Map<String, dynamic>?;

              final horaInicio = horario?['horaInicio'] ?? '';
              final dias = (horario?['dias'] as List<dynamic>?)?.join(', ') ?? '';
              final aula = clase['aula'] ?? '';
              final uid = _auth.currentUser!.uid;
              final estudiante = clase['estudiantes'][uid] ?? {};
              final evaluacionesClase = clase['evaluaciones'] as Map<String, dynamic>? ?? {};
              final evaluacionesEstudiante = estudiante['evaluaciones'] as Map<String, dynamic>? ?? {};

              double acumulado = 0;
              int evaluacionesTotales = evaluacionesClase.length;
              int evaluacionesCalificadas = 0;

              evaluacionesEstudiante.forEach((evalId, evalData) {
                final nota = evalData['nota'];
                final evalClase = evaluacionesClase[evalId];

                if (nota != null && evalClase != null) {
                  final puntos = (evalClase['ponderacion']?['puntos'] ?? 0).toDouble();
                  final notaNum = (nota as num).toDouble();
                  acumulado += (notaNum * puntos) / 20;
                  evaluacionesCalificadas++;
                }
              });

              final promedio = acumulado.toStringAsFixed(1);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(20, 0, 0, 0),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                  border: Border(
                    left: BorderSide(
                      color: Color(0xFFFD8305),
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Cabecera: Nombre + promedio
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          clase['nombreMateria'] ?? 'Materia',
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$promedio/20',
                              style: GoogleFonts.poppins(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: (double.tryParse(promedio) ?? 0) >= 90
                                    ? Colors.green
                                    : (double.tryParse(promedio) ?? 0) >= 85
                                    ? Color(0xFFFD8305)
                                    : Color(0xFFFD8305),
                              ),
                            ),
                            Text(
                              'Acumulado',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),

                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    /// Profesor y aula
                    Text(
                      'Prof. ${clase['profesorNombre']} - Aula $aula',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Horario',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Hora (estilo pill naranja)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEAD2), // fondo naranja claro
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Text(
                            horaInicio,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFD8305), // texto naranja fuerte
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Días (estilo pill gris)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), // fondo gris claro
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Text(
                            dias,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569), // gris oscuro
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    /// Evaluaciones y calificadas
                    DefaultTextStyle.merge(
                      style: GoogleFonts.poppins(color: Colors.black,),
                      child: Row(
                        children: [
                          _infoBox(label: 'Evaluaciones', value: evaluacionesTotales.toString()),
                          const SizedBox(width: 12),
                          _infoBox(label: 'Calificadas', value: evaluacionesCalificadas.toString()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 24),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Class(clase: clase),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ver detalles',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Color(0xFFFD8305),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Color(0xFFFD8305),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _infoBox({required String label, required String value}) {
    return Container(
      width: 350, // o ajusta a 120 si lo quieres un poco más ancho
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorByHour(String hour) {
    if (hour.contains('8:00') || hour.contains('10:00')) return Colors.orange;
    if (hour.contains('2:00') || hour.contains('14:00')) return Colors.green;
    if (hour.contains('4:00') || hour.contains('16:00')) return Colors.deepPurpleAccent;
    return Colors.blueGrey;
  }
}
