import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class Class extends StatelessWidget {
  final Map<String, dynamic> clase;

  const Class({super.key, required this.clase});

  @override
  Widget build(BuildContext context) {
    final horario = clase['horario'] as Map<String, dynamic>?;
    final dias = (horario?['dias'] as List<dynamic>?)?.join(', ') ?? '';
    final hora = horario?['horaInicio'] ?? '';
    final nombre = clase['nombreMateria'] ?? '';
    final profesor = clase['profesorNombre'] ?? '';
    final aula = clase['aula'] ?? '';
    final creditos = clase['creditos']?.toString() ?? '4';
    final claseId = clase['id'] ?? '';

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final promedio = (clase['estudiantes']?[uid]?['notaFinal'] ?? '0').toString();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Volver a Mis Asignaturas',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 14,
            ),
          ),
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            )),
                        const SizedBox(height: 6),
                        Text('Prof. $profesor - Aula $aula',
                            style: GoogleFonts.poppins(color: Colors.black)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _pill(hora, const Color(0xFFF97316), Colors.white),
                            const SizedBox(width: 8),
                            _pill(dias, const Color(0xFFE2E8F0), Colors.black),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _infoBox('Evaluaciones', '4'),
                            const SizedBox(width: 10),
                            _infoBox('Calificadas', '3'),
                            const SizedBox(width: 10),
                            _infoBox('Pendientes', '1'),
                            const SizedBox(width: 10),
                            _infoBox('Créditos', creditos),
                          ],
                        )
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '$promedio%',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF97316),
                        ),
                      ),
                      Text(
                        'Promedio General',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  )
                ],
              ),
            ),
            TabBar(
              labelColor: const Color(0xFFF97316),
              unselectedLabelColor: Colors.black,
              indicatorColor: const Color(0xFFF97316),
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(),
              tabs: const [
                Tab(text: 'Evaluaciones'),
                Tab(text: 'Tareas'),
                Tab(text: 'Contenidos'),
                Tab(text: 'Participantes'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _evaluacionesTab(clase),
                  Center(child: Text('Tareas (en desarrollo)', style: GoogleFonts.poppins(color: Colors.black))),
                  _claseContenidosTab(claseId),
                  _participantesTab(clase),
                ],
              ),
            ),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static Widget _infoBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ],
        ),
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recurso['titulo'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(fecha, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(recurso['descripcion'] ?? '', style: GoogleFonts.poppins(color: Colors.black)),
                  const SizedBox(height: 8),
                  recurso['tipo'] == 'image'
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(recurso['link'] ?? ''),
                  )
                      : TextButton(
                    onPressed: () => launchUrl(Uri.parse(recurso['link'] ?? '')),
                    child: Text('Abrir recurso', style: GoogleFonts.poppins(color: Colors.black)),
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

    final items = evaluacionesAlumno.entries.map((entry) {
      final evalId = entry.key;
      final datosAlumno = entry.value as Map<String, dynamic>;
      final nota = datosAlumno['nota'];
      final datosEval = evaluacionesGlobal[evalId] as Map<String, dynamic>? ?? {};

      final fecha = (datosEval['fecha'] != null && datosEval['fecha'] is Timestamp)
          ? DateFormat('dd/MM/yyyy').format((datosEval['fecha'] as Timestamp).toDate())
          : '';

      return {
        'nombre': datosEval['nombre'] ?? 'Evaluación',
        'tipo': datosEval['tipo'] ?? 'Evaluación',
        'fecha': fecha,
        'peso': '${datosEval['ponderacion']?['porcentaje'] ?? ''}%',
        'estado': nota == null ? 'Pendiente' : 'Calificada',
        'nota': nota == null ? '' : 'Calificación: ${nota.toString()}',
        'color': nota == null ? Colors.grey : Colors.orange,
      };
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Evaluaciones',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Historial completo de evaluaciones y calificaciones',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        ...items.map((e) => _evalCard(e)).toList(),
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
          'Participantes',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
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
          final uid = entry.key;
          return Container(
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
                Text(uid, style: GoogleFonts.poppins(color: Colors.black)),
              ],
            ),
          );
        }),
      ],
    );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                data['nombre'],
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  data['tipo'],
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Fecha: ${data['fecha']}   Peso: ${data['peso']}',
            style: GoogleFonts.poppins(color: Colors.black, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: data['estado'] == 'Pendiente'
                      ? const Color(0xFFFFEDD5)
                      : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  data['estado'],
                  style: GoogleFonts.poppins(
                    color: data['estado'] == 'Pendiente' ? Colors.orange : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                data['estado'] == 'Pendiente'
                    ? 'Pendiente'
                    : '${data['nota']}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: data['color'],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),

              Text(
                data['estado'] == 'Pendiente'
                    ? ''
                    : 'Puntos: ${data['puntosObtenidos'] ?? '0'}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
