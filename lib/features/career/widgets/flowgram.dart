import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Flowgram extends StatefulWidget {
  final String carreraId;

  const Flowgram({super.key, required this.carreraId});

  @override
  State<Flowgram> createState() => _FlowgramState();
}

class _FlowgramState extends State<Flowgram> {
  late Future<Map<String, dynamic>> _flujogramaData;

  @override
  void initState() {
    super.initState();
    _flujogramaData = _cargarFlujograma();
  }

  Future<Map<String, dynamic>> _cargarFlujograma() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('flujogramas')
          .doc(widget.carreraId.toLowerCase().replaceAll(' ', '_'))
          .get();

      if (!doc.exists) {
        throw Exception('Flujograma no encontrado');
      }

      return doc.data()!;
    } catch (e) {
      debugPrint('Error cargando flujograma: $e');
      return {
        'nombre': widget.carreraId,
        'materias': [],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: FutureBuilder(
          future: _flujogramaData,
          builder: (context, snapshot) {
            final nombre = snapshot.hasData ? snapshot.data!['nombre'] : widget.carreraId;
            return Text('Flujograma - $nombre');
          },
        ),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder(
        future: _flujogramaData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final materias = List<Map<String, dynamic>>.from(snapshot.data!['materias'] ?? []);

          return SafeArea(
            child: SingleChildScrollView(
              child: SizedBox(
                height: 1000,
                child: Stack(
                  children: [
                    // Encabezados
                    const Positioned(
                      left: 20,
                      top: 40,
                      child: Text(
                        'Flujo de Materias',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),

                    // Materias dinámicas
                    ...materias.map((materia) {
                      return Positioned(
                        left: (materia['posX'] ?? 20).toDouble(),
                        top: (materia['posY'] ?? 150).toDouble(),
                        child: materia['prerrequisito'] == null
                            ? _buildMateriaBox(materia['nombre'])
                            : _buildPrereqBox(
                          materia['nombre'],
                          'Prerrequisito: ${materia['prerrequisito']}',
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMateriaBox(String nombre) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        nombre,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildPrereqBox(String nombre, String prerrequisito) {
    return Opacity(
      opacity: 0.7,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nombre,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              prerrequisito,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}