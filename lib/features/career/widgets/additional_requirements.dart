import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AdditionalRequirements extends StatefulWidget {
  final String carreraId;

  const AdditionalRequirements({super.key, required this.carreraId});

  @override
  State<AdditionalRequirements> createState() => _AdditionalRequirementsState();
}

class _AdditionalRequirementsState extends State<AdditionalRequirements> {
  late String flujogramaId;

  Future<String?> _obtenerIdFlujograma(String carreraId) async {
    print('🔍 Buscando flujograma para carrera: $carreraId');
    try {
      final doc = await FirebaseFirestore.instance.collection('carreras').doc(carreraId).get();
      final flujograma = doc.data()?['flujograma'];
      print('✅ Flujograma encontrado: $flujograma');
      return flujograma;
    } catch (e) {
      print('❌ Error obteniendo flujograma: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _obtenerIdFlujograma(widget.carreraId),
      builder: (context, snapshotFlujo) {
        if (snapshotFlujo.hasError) {
          print('❌ Error en snapshotFlujo: ${snapshotFlujo.error}');
          return const Center(child: Text('Error cargando flujograma'));
        }
        if (!snapshotFlujo.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        flujogramaId = snapshotFlujo.data!;
        print('📦 Usando flujogramaId: $flujogramaId');

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('flujogramas')
              .doc(flujogramaId)
              .collection('requisitos_adicionales')
              .get(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error cargando requisitos'));
            }
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!.docs;
            print('📄 Documentos encontrados: ${docs.length}');
            final Map<String, Map<String, dynamic>> dataMap = {
              for (var doc in docs) doc.id: doc.data() as Map<String, dynamic>
            };

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requerimientos Adicionales',
                    style: GoogleFonts.poppins(
                      fontSize: 35,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestiona y visualiza el progreso de tus requerimientos académicos adicionales',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
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
    final horasServicio = (servicio?['horas'] ?? 0) as int;
    final entregado = tesis?['entregado'] == true;
    final progresoTesis = entregado ? 1.0 : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildResumenItem('Idiomas', '${aprobado1 + aprobado2}/$idiomasCantidad', const Color(0xFF2563EB), 'Completados/Total'),
          _buildResumenItem('Servicio', '$horasServicio/120', const Color(0xFF10B981), 'Horas Completadas'),
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
        .collection('flujogramas')
        .doc(flujogramaId)
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
    final horas = data['horas'] ?? 0;
    final TextEditingController controller = TextEditingController(text: horas.toString());

    final ref = FirebaseFirestore.instance
        .collection('flujogramas')
        .doc(flujogramaId)
        .collection('requisitos_adicionales')
        .doc('servicio_comunitario');

    return _buildCard(
      titulo: 'Servicio Comunitario',
      descripcion: 'Completa 120 horas en actividades comunitarias avaladas por la universidad.',
      estado: (horas >= 120) ? 'Completado' : 'Pendiente',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Horas completadas',
              labelStyle: TextStyle(color: Colors.black),
            ),
            onSubmitted: (val) {
              final parsed = int.tryParse(val);
              if (parsed != null) {
                ref.update({'horas': parsed});
                setState(() {});
              }
            },
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (horas / 120).clamp(0.0, 1.0),
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
    if (!opciones.contains(estado)) {
      estado = 'No Iniciado'; // valor por defecto si hay un valor inválido
    }

    final entregado = data['entregado'] ?? false;

    final ref = FirebaseFirestore.instance
        .collection('flujogramas')
        .doc(flujogramaId)
        .collection('requisitos_adicionales')
        .doc('trabajo_de_tesis');

    return _buildCard(
      titulo: 'Trabajo de Tesis',
      descripcion: 'Selecciona el estado de tu tesis.',
      estado: estado,
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButton<String>(
            value: estado,
            style: GoogleFonts.poppins(color: Colors.black),
            items: opciones
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                ref.update({'estado': val, 'entregado': val != 'No Iniciado'});
                setState(() {});
              }
            },
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: entregado ? 1.0 : 0.0,
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
    if (estado == 'En Progreso') estadoColor = const Color(0xFFF59E0B);
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
