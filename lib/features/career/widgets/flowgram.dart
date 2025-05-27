import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/features/auth/models/user_model.dart';

class Flowgram extends StatefulWidget {
  final String carreraId;

  const Flowgram({super.key, required this.carreraId});

  @override
  State<Flowgram> createState() => _FlowgramState();
}

class _FlowgramState extends State<Flowgram> {
  late Future<Map<String, dynamic>> _flujogramaData;
  late Future<List<Map<String, dynamic>>> _materiasDesdeUsuario;

  @override
  void initState() {
    super.initState();
    _flujogramaData = _cargarFlujograma();
    _materiasDesdeUsuario = _cargarMateriasDesdeFlujogramaCompuesto();
  }

  Future<Map<String, dynamic>> _cargarFlujograma() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('flujogramas')
          .doc(widget.carreraId.toLowerCase().replaceAll(' ', '_'))
          .get();

      if (!doc.exists) throw Exception('Flujograma no encontrado');

      return doc.data()!;
    } catch (e) {
      debugPrint('Error cargando flujograma: $e');
      return {
        'nombre': widget.carreraId,
        'materias': [],
      };
    }
  }

  Future<List<Map<String, dynamic>>> _cargarMateriasDesdeFlujogramaCompuesto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      final usuarioDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      final baseUser = await userFromDocument(usuarioDoc);
      if (baseUser is! StudentUser) throw Exception('El usuario no es estudiante');
      final student = baseUser as StudentUser;

      // Paso 1: Obtener el flujograma asociado a su carrera
      final carrerasDoc = await FirebaseFirestore.instance
          .collection('carreras_pregrado')
          .doc('sjs34UWA7WS5CzHyvRdc') // ID fijo basado en tu estructura
          .get();

      final flujogramaId = carrerasDoc.data()?['carreras']?[student.major]?['flujograma'];
      if (flujogramaId == null) throw Exception('Flujograma no encontrado para esta carrera');

      // Paso 2: Obtener materias del flujograma
      final flujogramaDoc = await FirebaseFirestore.instance
          .collection('flujogramas_pregrado')
          .get(); // Usamos `.get()` porque el ID es dinámico

      final flujogramaMap = flujogramaDoc.docs.first.data()['flujogramas']?[flujogramaId];
      if (flujogramaMap == null) throw Exception('No se encontraron materias en flujograma');

      final materiaIds = flujogramaMap.keys.toList();

      // Paso 3: Obtener info de materias
      final materiasDoc = await FirebaseFirestore.instance
          .collection('materias_pregrado')
          .get(); // Solo hay un documento con todas

      final materiasMap = materiasDoc.docs.first.data()['materias'];

      List<Map<String, dynamic>> materias = [];

      for (final id in materiaIds) {
        if (materiasMap.containsKey(id)) {
          final info = materiasMap[id];
          materias.add({
            'nombre': info['nombre'] ?? id,
            'creditos': info['creditos'] ?? 0,
          });
        }
      }

      return materias;
    } catch (e) {
      debugPrint('❌ Error al obtener materias: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Título
                Text(
                  'Flujo de Materias',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E293B),
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Subtítulo
                Text(
                  'Visualiza y gestiona tu progreso académico de manera intuitiva',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Contenedor visual del flujograma
                Container(
                  height: 600,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FutureBuilder(
                    future: _flujogramaData,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final materias = List<Map<String, dynamic>>.from(snapshot.data!['materias'] ?? []);
                      return Stack(
                        children: materias.map((materia) {
                          final nombre = materia['nombre'] ?? '';
                          final prereq = materia['prerrequisito'];
                          final posX = (materia['posX'] ?? 0).toDouble();
                          final posY = (materia['posY'] ?? 0).toDouble();

                          return Positioned(
                            left: posX,
                            top: posY,
                            child: prereq == null
                                ? _materiaBox(nombre)
                                : _materiaBoxConPrereq(nombre, prereq),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
                // Materias dinámicas en columnas de 5
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _materiasDesdeUsuario,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    final materias = snapshot.data ?? [];

                    if (materias.isEmpty) {
                      return const Text('No se encontraron materias');
                    }

                    final columnas = <Widget>[];

                    for (int i = 0; i < materias.length; i += 5) {
                      final grupo = materias.skip(i).take(5).map((materia) {
                        final nombre = materia['nombre'];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF8FAFC),
                              foregroundColor: const Color(0xFF1E293B),
                              elevation: 0,
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: const Size(250, 58),
                            ),
                            child: Text(
                              nombre,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList();

                      columnas.add(Column(children: grupo));
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: columnas
                            .asMap()
                            .entries
                            .map((entry) => Padding(
                          padding: EdgeInsets.only(left: entry.key * 270.0),
                          child: entry.value,
                        ))
                            .toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _materiaBox(String nombre) {
    return Container(
      width: 250,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            nombre,
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _materiaBoxConPrereq(String nombre, String prerrequisito) {
    return Opacity(
      opacity: 0.7,
      child: Container(
        width: 250,
        height: 83,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Prerrequisitos: $prerrequisito',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
