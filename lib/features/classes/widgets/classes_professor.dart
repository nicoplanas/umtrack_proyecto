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
                  Center(child: Text("Materias Impartidas",
                      style: GoogleFonts.poppins(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ))),
                  const SizedBox(height: 12),
                  Center(child: Text("Seleccione una materia para gestionarla",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF64748B),
                      ))),
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
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                )
                              ],
                              border: const Border(
                                left: BorderSide(color: Color(0xFFF97316), width: 4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(nombre,
                                              style: GoogleFonts.poppins(
                                                fontSize: 25,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF0F172A),
                                              )),
                                          const SizedBox(height: 12),
                                          Text('Prof. ${clase['profesorNombre']} - Aula $aula',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: const Color(0xFF94A3B8))),
                                          const SizedBox(height: 8),
                                          Text('Horario',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF0F172A),
                                              )),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFEDD5),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  horaInicio,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFFF97316),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE2E8F0),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  dias,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: const Color(0xFF475569),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "$progreso",
                                              style: GoogleFonts.poppins(
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFFF97316), // Naranja fuerte
                                              ),
                                            ),
                                            Text(
                                              "%",
                                              style: GoogleFonts.poppins(
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFFF97316), // Mismo color
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Acumulado",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: const Color(0xFF94A3B8), // Gris claro
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    _infoBox('Estudiantes', estudiantes.toString()),
                                    const SizedBox(width: 12),
                                    _infoBox("Evaluaciones", evaluaciones.toString()),
                                    const SizedBox(width: 12),
                                    _infoBox("Pendientes", pendientes.toString()),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Ver detalles",
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: const Color(0xFFF97316),
                                            fontWeight: FontWeight.w500)),
                                    const Icon(Icons.arrow_forward_ios_rounded,
                                        color: Color(0xFFF97316), size: 16)
                                  ],
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
      width: 350, // puedes ajustar este valor
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
