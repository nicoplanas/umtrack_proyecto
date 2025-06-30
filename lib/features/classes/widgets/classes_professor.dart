import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../classes/views/classes_details_professor_page.dart';
import 'package:google_fonts/google_fonts.dart';

class ClassesProfessor extends StatelessWidget {
  const ClassesProfessor({super.key});

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('usuarios').doc(uid).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userSnapshot.hasError || !userSnapshot.hasData) {
          return Center(
            child: Text(
              "Error al cargar los datos del usuario.",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
            ),
          );
        }

        final fullName = userSnapshot.data!.get('fullName') ?? 'prof.';

        return Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('clases')
                .where('profesorId', isEqualTo: uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Ocurrió un error al cargar las clases.",
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
                  ),
                );
              }

              final clases = snapshot.data?.docs ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Bienvenido de vuelta, prof. $fullName",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      )),
                  const SizedBox(height: 12),
                  Text("Asignaturas",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      )),
                  const SizedBox(height: 6),
                  Text("Seleccione una materia para gestionar su progreso",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      )),
                  const SizedBox(height: 24),
                  if (clases.isEmpty)
                    Center(
                      child: Text(
                        "No se encontraron clases asignadas.",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: clases.length,
                      itemBuilder: (context, index) {
                        final claseDoc = clases[index];
                        final clase = claseDoc.data() as Map<String, dynamic>;
                        final claseId = claseDoc.id;

                        final nombre = clase['nombreMateria'] ?? 'Sin nombre';
                        final aula = clase['aula'] ?? 'Aula desconocida';
                        final horario = clase['horario'] ?? {};
                        final dias = (horario['dias'] as List<dynamic>?)?.join(', ') ?? '';
                        final horaInicio = horario['horaInicio'] ?? '';
                        final estudiantes = (clase['estudiantes'] as Map?)?.length ?? 0;
                        final evaluaciones = (clase['evaluaciones'] as Map?)?.length ?? 0;
                        final pendientes = clase['pendientes'] ?? 0;
                        final progreso = clase['progreso'] ?? 0;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClassesDetailsProfessorPage(
                                  claseId: claseId,
                                  claseData: clase,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Expanded left section
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(nombre,
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF0F172A),
                                          )),
                                      const SizedBox(height: 4),
                                      Text(aula,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: const Color(0xFF64748B),
                                          )),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFEDD5),
                                              borderRadius:
                                              BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              horaInicio,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFFFB923C),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(dias,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: const Color(0xFF64748B),
                                              )),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          _infoBox("Estudiantes",
                                              estudiantes.toString()),
                                          _infoBox("Evaluaciones",
                                              evaluaciones.toString()),
                                          _infoBox("Pendientes",
                                              pendientes.toString()),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                // Right progress percentage
                                Container(
                                  alignment: Alignment.topRight,
                                  margin: const EdgeInsets.only(left: 12),
                                  child: Column(
                                    children: [
                                      Text(
                                        "${progreso.toString()}%",
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFF97316),
                                        ),
                                      ),
                                      Text("Progreso del curso",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: const Color(0xFF64748B),
                                          )),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _infoBox(String label, String value) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              )),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF64748B),
              )),
        ],
      ),
    );
  }
}
