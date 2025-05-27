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
  late Future<List<Map<String, dynamic>>> _materiasDesdeUsuario;
  Set<String> _materiasAprobadas = {};
  int _totalMaterias = 0;

  @override
  void initState() {
    super.initState();
    _materiasDesdeUsuario = _cargarMateriasDesdeFlujogramaCompuesto();
    _obtenerMateriasAprobadas();
  }

  Future<void> _obtenerMateriasAprobadas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final usuarioDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    final data = usuarioDoc.data();
    final passed = data?['passedCourses'] as Map<String, dynamic>?;

    if (passed != null) {
      setState(() {
        _materiasAprobadas = passed.keys.toSet();
      });
    }
  }

  Future<void> _toggleMateriaAprobada(String codigo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);

    final yaAprobada = _materiasAprobadas.contains(codigo);

    if (yaAprobada) {
      await ref.update({
        'passedCourses.$codigo': FieldValue.delete(),
      });
      setState(() {
        _materiasAprobadas.remove(codigo);
      });
    } else {
      await ref.update({
        'passedCourses.$codigo': codigo,
      });
      setState(() {
        _materiasAprobadas.add(codigo);
      });
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

      final carreraDoc = await FirebaseFirestore.instance
          .collection('carreras_pregrado')
          .doc('sjs34UWA7WS5CzHyvRdc')
          .get();

      final flujogramaId = carreraDoc.data()?['carreras']?[student.major]?['flujograma'];
      if (flujogramaId == null) throw Exception('Carrera sin flujograma');

      final flujogramaDoc = await FirebaseFirestore.instance
          .collection('flujogramas_pregrado')
          .get();

      final flujogramaMap = flujogramaDoc.docs.first.data()['flujogramas']?[flujogramaId];
      if (flujogramaMap == null) throw Exception('No se encontraron materias en flujograma');

      final materiaIds = flujogramaMap.keys.toList();

      final materiasDoc = await FirebaseFirestore.instance
          .collection('materias_pregrado')
          .get();

      final materiasMap = materiasDoc.docs.first.data()['materias'];

      List<Map<String, dynamic>> materias = [];

      for (final id in materiaIds) {
        if (materiasMap.containsKey(id)) {
          final info = materiasMap[id];
          materias.add({
            'codigo': id,
            'nombre': info['nombre'] ?? id,
            'creditos': info['creditos'] ?? 0,
          });
        }
      }

      setState(() {
        _totalMaterias = materias.length;
      });

      return materias;
    } catch (e) {
      debugPrint('❌ Error al obtener materias: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final porcentaje = _totalMaterias == 0
        ? 0.0
        : (_materiasAprobadas.length / _totalMaterias).clamp(0.0, 1.0).toDouble();

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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

                // Barra de progreso circular
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: porcentaje.toDouble(),
                            strokeWidth: 10,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                        ),
                        Text(
                          '${(porcentaje * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

                // Contenedor de materias con columnas por trimestre
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _materiasDesdeUsuario,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        final materias = snapshot.data ?? [];

                        if (materias.isEmpty) {
                          return const Center(child: Text('No se encontraron materias'));
                        }

                        final columnas = <Widget>[];

                        for (int i = 0; i < materias.length; i += 5) {
                          final grupo = materias.skip(i).take(5).map((materia) {
                            final nombre = materia['nombre'];
                            final codigo = materia['codigo'];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: SizedBox(
                                width: 225,
                                height: 70,
                                child: ElevatedButton(
                                  onPressed: () => _toggleMateriaAprobada(codigo),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _materiasAprobadas.contains(codigo)
                                        ? Colors.orange
                                        : const Color(0xFFF8FAFC),
                                    foregroundColor: const Color(0xFF1E293B),
                                    elevation: 0,
                                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                  ),
                                  child: Text(
                                    nombre,
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                    maxLines: null,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList();
                          columnas.add(Column(children: grupo));
                        }

                        final trimestres = [
                          '1er Trimestre',
                          '2do Trimestre',
                          '3er Trimestre',
                          '4to Trimestre',
                          '5to Trimestre',
                          '6to Trimestre',
                          '7mo Trimestre',
                          '8vo Trimestre',
                          '9no Trimestre',
                          '10mo Trimestre'
                        ];

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < columnas.length; i++) ...[
                                if (i > 0) const SizedBox(width: 50),
                                Column(
                                  children: [
                                    Text(
                                      i < trimestres.length ? trimestres[i] : 'Trimestre ${i + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    columnas[i],
                                  ],
                                ),
                              ]
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
