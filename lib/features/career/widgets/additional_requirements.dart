import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AdditionalRequirements extends StatefulWidget {
  const AdditionalRequirements({super.key});

  @override
  State<AdditionalRequirements> createState() => _AdditionalRequirementsState();
}

class _AdditionalRequirementsState extends State<AdditionalRequirements> {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('requisitos_adicionales')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error cargando requisitos'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        final Map<String, Map<String, dynamic>> dataMap = {
          for (var doc in docs) doc.id: doc.data() as Map<String, dynamic>
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text('Gestiona y visualiza el progreso de tus requerimientos académicos adicionales.',
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF94A3B8)),
              )),
              const SizedBox(height: 24),
              _buildResumen(dataMap),
              const SizedBox(height: 30),
              if (dataMap.containsKey('idiomas')) _buildIdiomas(dataMap['idiomas']!),
              if (dataMap.containsKey('servicio_comunitario')) _buildServicio(dataMap['servicio_comunitario']!),
              if (dataMap.containsKey('trabajo_de_tesis')) _buildTesis(dataMap['trabajo_de_tesis']!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResumen(Map<String, Map<String, dynamic>> dataMap) {
    final idiomas = dataMap['idiomas'];
    final servicio = dataMap['servicio_comunitario'];
    final tesis = dataMap['trabajo_de_tesis'];

    final aprobado1 = idiomas?['idioma_1']?['aprobado'] == true ? 1 : 0;
    final aprobado2 = idiomas?['idioma_2']?['aprobado'] == true ? 1 : 0;
    final idiomasCantidad = idiomas?['cantidad'] ?? 2;

    final horasMinimas = servicio?['horas_minimas'] ?? 20;
    final horasCumplidas = servicio?['horas_cumplidas'] ?? 0;

    final entregado = tesis?['entregado'] == true;
    final Map<String, double> progresoPorEstado = {
      'No Iniciado': 0.0,
      'Enviado': 0.25,
      'Aceptado': 0.50,
      'Presentado': 0.75,
      'Aprobado': 1.0,
      'Reprobado': 0.0,
    };

    final progresoTesis = progresoPorEstado[tesis?['estado']] ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildResumenItem('Idiomas', '${aprobado1 + aprobado2}/$idiomasCantidad', const Color(0xFF2563EB), 'Completados/Total'),
          _buildResumenItem('Servicio', '$horasCumplidas/$horasMinimas', const Color(0xFF10B981), 'Horas Completadas'),
          _buildResumenItem('Tesis', '${(progresoTesis * 100).toStringAsFixed(0)}%', const Color(0xFF8B5CF6), 'Progreso'),
        ],
      ),
    );
  }

  Widget _buildResumenItem(String title, String value, Color color, String subtitle) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 20, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
        Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildIdiomas(Map<String, dynamic> data) {
    final idioma1 = data['idioma_1'] as Map<String, dynamic>? ?? {};
    final idioma2 = data['idioma_2'] as Map<String, dynamic>? ?? {};

    final aprobado1 = idioma1['aprobado'] == true;
    final aprobado2 = idioma2['aprobado'] == true;

    final label1 = idioma1['codigo']?.toString().isNotEmpty == true ? idioma1['codigo'] : 'Idioma 1';
    final label2 = idioma2['codigo']?.toString().isNotEmpty == true ? idioma2['codigo'] : 'Idioma 2';

    final ref = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('requisitos_adicionales')
        .doc('idiomas');

    void actualizarEstadoIdiomas({bool? nuevo1, bool? nuevo2}) {
      final nuevoAprobado1 = nuevo1 ?? aprobado1;
      final nuevoAprobado2 = nuevo2 ?? aprobado2;
      final completado = nuevoAprobado1 && nuevoAprobado2;

      ref.update({
        'idioma_1.aprobado': nuevoAprobado1,
        'idioma_2.aprobado': nuevoAprobado2,
        'completado': completado,
      });

      setState(() {});
    }

    return _buildCard(
      titulo: 'Idiomas Extranjeros',
      descripcion: 'Completa los idiomas requeridos según tu carrera.',
      estado: (aprobado1 && aprobado2) ? 'Completado' : 'Pendiente',
      contenido: Row(
        children: [
          _idiomaCheckbox(label1, aprobado1, (val) => actualizarEstadoIdiomas(nuevo1: val ?? false)),
          const SizedBox(width: 24),
          _idiomaCheckbox(label2, aprobado2, (val) => actualizarEstadoIdiomas(nuevo2: val ?? false)),
        ],
      ),
    );
  }

  Widget _idiomaCheckbox(String label, bool aprobado, void Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(value: aprobado, onChanged: onChanged),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black)),
      ],
    );
  }

  Widget _buildServicio(Map<String, dynamic> data) {
    final horasMinimas = data['horas_minimas'] ?? 20;
    final horasCumplidas = data['horas_cumplidas'] ?? 0;
    final TextEditingController controller = TextEditingController(text: horasCumplidas.toString());

    final ref = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('requisitos_adicionales')
        .doc('servicio_comunitario');

    final completado = horasCumplidas >= 120;

    void actualizarHoras(String val) {
      final parsed = int.tryParse(val);
      if (parsed != null && parsed >= 0) {
        final nuevoCompletado = parsed >= 120;
        ref.update({
          'horas_cumplidas': parsed,
          'completado': nuevoCompletado,
        });
        setState(() {});
      }
    }

    return _buildCard(
      titulo: 'Servicio Comunitario',
      descripcion: 'Completa al menos $horasMinimas horas en actividades comunitarias avaladas por la universidad.',
      estado: completado ? 'Completado' : 'Pendiente',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              labelText: 'Horas cumplidas',
              labelStyle: TextStyle(color: Colors.black),
            ),
            onSubmitted: actualizarHoras,
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (horasCumplidas / horasMinimas).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildTesis(Map<String, dynamic> data) {
    final List<String> opciones = [
      'No Iniciado',
      'Enviado',
      'Aceptado',
      'Presentado',
      'Aprobado',
      'Reprobado'
    ];

    String estado = data['estado'] ?? 'No Iniciado';
    if (!opciones.contains(estado)) estado = 'No Iniciado';

    final ref = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('requisitos_adicionales')
        .doc('trabajo_de_tesis');

    final Map<String, double> progresoPorEstado = {
      'No Iniciado': 0.0,
      'Enviado': 0.25,
      'Aceptado': 0.50,
      'Presentado': 0.75,
      'Aprobado': 1.0,
      'Reprobado': 0.0,
    };

    final progreso = progresoPorEstado[estado] ?? 0.0;
    final completado = estado == 'Aprobado';
    final entregado = estado != 'No Iniciado';

    // ✅ Texto que se muestra en la tarjeta
    final estadoMostrar = completado ? 'Completado' : 'Pendiente';

    return _buildCard(
      titulo: 'Trabajo de Tesis',
      descripcion: 'Selecciona el estado de tu tesis.',
      estado: estadoMostrar,
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButton<String>(
            value: estado,
            style: GoogleFonts.poppins(color: Colors.black),
            items: opciones.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) {
              if (val != null) {
                final nuevoCompletado = val == 'Aprobado';
                final nuevoEntregado = val != 'No Iniciado';

                ref.update({
                  'estado': val,
                  'entregado': nuevoEntregado,
                  'completado': nuevoCompletado,
                });

                setState(() {});
              }
            },
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progreso,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFF8B5CF6),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String titulo,
    required String descripcion,
    required String estado,
    required Widget contenido,
  }) {
    Color estadoColor = const Color(0xFF64748B);
    if (estado == 'Completado') estadoColor = const Color(0xFF10B981);
    if (estado == 'Pendiente') estadoColor = const Color(0xFFFF9800);
    if (estado == 'No Iniciado') estadoColor = const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titulo, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(estado, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(descripcion, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black)),
          const SizedBox(height: 12),
          contenido,
        ],
      ),
    );
  }
}
