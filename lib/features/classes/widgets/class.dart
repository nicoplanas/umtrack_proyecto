import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '/core/widgets/navbar.dart';
import '/core/widgets/footer.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class Class extends StatelessWidget {
  final Map<String, dynamic> clase;

  const Class({super.key, required this.clase});

  @override
  Widget build(BuildContext context) {
    final horario = clase['horario'] as Map<String, dynamic>?;
    final dias = (horario?['dias'] as List<dynamic>?)?.join(', ') ?? '';
    final hora = horario?['horaInicio'] ?? '';
    final nombre = clase['nombreMateria'] ?? 'Materia no disponible';
    final profesor = clase['profesorNombre'] ?? 'Profesor no disponible';
    final seccion = clase['seccion'] ?? 'Sección no disponible';
    final aula = clase['aula'] ?? 'Aula no disponible';
    final claseId = clase['id'] ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final evaluacionesClase = clase['evaluaciones'] as Map<String, dynamic>? ?? {};
    final evaluacionesEstudiante = clase['estudiantes']?[uid]?['evaluaciones'] as Map<String, dynamic>? ?? {};

    // ✅ Cálculo del acumulado
    double acumuladoValor = 0;
    double totalPeso = 0;

    evaluacionesEstudiante.forEach((evalId, evalData) {
      final nota = evalData['nota'];
      final evalGlobal = evaluacionesClase[evalId] ?? {};
      final peso = (evalGlobal['ponderacion']?['porcentaje'] ?? 0).toDouble();

      if (nota != null && peso > 0) {
        acumuladoValor += (nota * peso) / 100;
        totalPeso += peso;
      }
    });

    final acumulado = totalPeso > 0 ? acumuladoValor.toStringAsFixed(1) : '0.0';

    int evaluacionesTotales = evaluacionesClase.length;
    int evaluacionesCalificadas = 0;
    int evaluacionesPendientes = 0;

    evaluacionesEstudiante.forEach((evalId, evalData) {
      final nota = evalData['nota'];
      if (nota != null) {
        evaluacionesCalificadas++;
      } else {
        evaluacionesPendientes++;
      }
    });

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: Navbar()),
            SliverToBoxAdapter(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 8),
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back, color: Color(0xFFFD8305)),
                          label: Text(
                            'Volver',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFFD8305),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 6,
                              spreadRadius: 2,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nombre,
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      )),
                                  const SizedBox(height: 6),
                                  Text('Sección $seccion • Prof. $profesor • Aula $aula',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Horario',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          _pill(hora, const Color(0xFFFFEAD2), const Color(0xFFFD8305)),
                                          const SizedBox(width: 8),
                                          _pill(dias, const Color(0xFFF1F5F9), const Color(0xFF475569)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      _infoBox('Evaluaciones', evaluacionesTotales.toString()),
                                      const SizedBox(width: 10),
                                      _infoBox('Calificadas', evaluacionesCalificadas.toString()),
                                      const SizedBox(width: 10),
                                      _infoBox('Pendientes', evaluacionesPendientes.toString()),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  '$acumulado/20',
                                  style: GoogleFonts.poppins(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFD8305),
                                  ),
                                ),
                                Text(
                                  'Acumulado',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ]
                )
            ),
            SliverToBoxAdapter(
              child: TabBar(
                labelColor: const Color(0xFFFD8305),
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: const Color(0xFFFD8305),
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.poppins(),
                tabs: const [
                  Tab(text: 'Evaluaciones'),
                  Tab(text: 'Contenidos'),
                  Tab(text: 'Participantes'),
                ],
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: TabBarView(
                children: [
                  _evaluacionesTab(clase),
                  _claseContenidosTab(claseId),
                  _participantesTab(clase),
                ],
              ),
            ),
            SliverToBoxAdapter(child: Footer()),
          ],
        ),
      ),
    );
  }

  static Widget _pill(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static Widget _infoBox(String label, String value) {
    return Container(
      width: 350,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
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

  static Widget _claseContenidosTab(String claseId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clases')
          .doc(claseId)
          .collection('contenidos')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(child: Text('No hay recursos disponibles', style: GoogleFonts.poppins(color: Colors.black)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final recurso = docs[index].data() as Map<String, dynamic>;
            final fecha = recurso['fecha'] is Timestamp
                ? DateFormat('dd/MM/yyyy – HH:mm').format((recurso['fecha'] as Timestamp).toDate())
                : '';
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen o ícono a la izquierda
                  if (recurso['tipo'] == 'image')
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: Colors.white,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 400,
                                maxHeight: 600,
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            spreadRadius: 2,
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          recurso['link'] ?? '',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        if (kIsWeb) {
                                          final url = recurso['link'] ?? '';
                                          final name = url.split('/').last;

                                          try {
                                            final anchor = html.AnchorElement(href: url)
                                              ..target = 'blank'
                                              ..download = name;
                                            anchor.click();
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('No se pudo descargar la imagen')),
                                            );
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Descarga solo disponible en Web')),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.open_in_browser),
                                      label: const Text('Abrir archivo'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFD8305),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          recurso['link'] ?? '',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.play_circle_fill, size: 40, color: Colors.black45),
                        onPressed: () => launchUrl(Uri.parse(recurso['link'] ?? '')),
                      ),
                    ),
                  const SizedBox(width: 16),

                  // Texto del recurso
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recurso['titulo'] ?? '',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fecha,
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recurso['descripcion'] ?? '',
                          style: GoogleFonts.poppins(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _evaluacionesTab(Map<String, dynamic> clase) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final evaluacionesAlumno = clase['estudiantes']?[uid]?['evaluaciones'] as Map<String, dynamic>? ?? {};
    final evaluacionesGlobal = clase['evaluaciones'] as Map<String, dynamic>? ?? {};

    final Map<String, List<Map<String, dynamic>>> categorias = {
      'Parciales': [],
      'Quizzes': [],
      'Tareas': [],
      'Talleres': [],
      'Exposiciones': [],
      'Trabajos': [],
    };

    evaluacionesAlumno.forEach((evalId, datosAlumno) {
      final datosEval = evaluacionesGlobal[evalId] as Map<String, dynamic>? ?? {};
      final tipoRaw = (datosEval['tipo'] ?? '').toString().toLowerCase();

      String? categoria;
      if (tipoRaw.contains('parcial')) {
        categoria = 'Parciales';
      } else if (tipoRaw.contains('quiz') || tipoRaw.contains('cuestionario')) {
        categoria = 'Quizzes';
      } else if (tipoRaw.contains('tarea')) {
        categoria = 'Tareas';
      } else if (tipoRaw.contains('taller')) {
        categoria = 'Talleres';
      } else if (tipoRaw.contains('expo')) {
        categoria = 'Exposiciones';
      } else if (tipoRaw.contains('trabajo')) {
        categoria = 'Trabajos';
      }

      if (categoria != null) {
        final fecha = (datosEval['fecha'] != null && datosEval['fecha'] is Timestamp)
            ? DateFormat('dd/MM/yyyy').format((datosEval['fecha'] as Timestamp).toDate())
            : '';

        final nota = datosAlumno['nota'];

        final evalData = {
          'nombre': datosEval['nombre'] ?? 'Evaluación',
          'fecha': fecha,
          'peso': '${datosEval['ponderacion']?['porcentaje'] ?? ''}%',
          'estado': nota == null ? 'Pendiente' : 'Calificada',
          'nota': nota == null ? '' : 'Nota: ${nota.toString()}',
          'color': nota == null ? Colors.grey : Colors.orange,
          'puntosObtenidos': datosAlumno['puntosObtenidos'] ?? '',
        };

        categorias[categoria]?.add(evalData);
      }
    });

    // Elimina categorías vacías
    final categoriasConContenido = categorias.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    return categoriasConContenido.isEmpty
        ? Center(
      child: Text(
        'No hay evaluaciones registradas aún.',
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
      ),
    )
        : ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ...categoriasConContenido.map((entry) {
          final titulo = entry.key;
          final items = entry.value;

          return Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                ...items.map((e) => _evalCard(e)).toList(),
              ],
            ),
          );
        }),
      ],
    );
  }

  static Widget _participantesTab(Map<String, dynamic> clase) {
    final profesorNombre = clase['profesorNombre'] ?? 'Profesor/a';
    final estudiantes = (clase['estudiantes'] as Map<String, dynamic>?) ?? {};

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Profesor',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.person, color: Colors.deepOrange),
              const SizedBox(width: 10),
              Text(
                '$profesorNombre',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Compañeros (${estudiantes.length})',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black),
        ),
        const SizedBox(height: 12),
        ...estudiantes.entries.map((entry) {
          final data = entry.value as Map<String, dynamic>;
          final nombre = data['nombre'] ?? 'Estudiante sin nombre';

          return GestureDetector(
            onTap: () {
              // Abre la sección de chat
              _openChatWithStudent(entry.key);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: Colors.black),
                  const SizedBox(width: 10),
                  Text(nombre, style: GoogleFonts.poppins(color: Colors.black)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // Nueva función para abrir el chat con el estudiante
  static void _openChatWithStudent(String studentId) {
    // Lógica para abrir el chat, dependiendo de tu estructura o implementación
    // Ejemplo usando Firestore o alguna API de mensajería
    print('Abriendo chat con estudiante: $studentId');
    // Aquí puedes integrar la lógica para redirigir a un chat en tiempo real o cargar los mensajes.
  }

  static Widget _evalCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      data['nombre'] ?? '',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Fecha: ${data['fecha'] ?? '-'}',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '•',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Peso: ${data['peso'] ?? '-'}',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: data['estado'] == 'Pendiente'
                        ? const Color(0xFFFFEDD5)
                        : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    data['estado']?.toString() ?? '',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: data['estado'] == 'Pendiente' ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                data['estado'] == 'Pendiente'
                    ? 'Pendiente'
                    : '${data['nota']?.toString() ?? '-'}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFD8305),
                ),
              ),
              if (data['estado'] != 'Pendiente') ...[
                const SizedBox(height: 4),
                Text(
                  'Puntos: ${data['puntosObtenidos']?.toString() ?? '-'}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
