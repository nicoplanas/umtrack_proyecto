import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Flowgram extends StatefulWidget {
  final String carreraId;

  const Flowgram({super.key, required this.carreraId});

  @override
  State<Flowgram> createState() => _FlowgramState();
}

enum SelectionMode {
  none,
  approved,  // verde
  current,   // amarillo
}

class _FlowgramState extends State<Flowgram> {
  late Future<List<Map<String, dynamic>>> _materiasDesdeUsuario;
  Set<String> _materiasAprobadas = {};
  Map<String, int> _notasAprobadas = {};

  final Set<String> _materiasTrimestreActual = {};
  int _totalMaterias = 0;
  int _totalCreditos = 0;

  SelectionMode _selectionMode = SelectionMode.none;

  @override
  void initState() {
    super.initState();
    _materiasDesdeUsuario = _cargarMateriasDesdeFlujogramaCompuesto();
    _obtenerMateriasAprobadas();
    _obtenerMateriasTrimestreActual();
  }

  Future<int?> _solicitarNotaFinal(BuildContext context, String codigo) async {
    final TextEditingController _notaController = TextEditingController();

    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Nota final'),
          content: TextField(
            controller: _notaController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Ingrese la nota...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final text = _notaController.text.trim();
                final nota = int.tryParse(text);
                if (nota != null && nota >= 0 && nota <= 20) {
                  Navigator.of(context).pop(nota);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingrese una nota válida entre 0 y 20')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _obtenerMateriasAprobadas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
    final data = userDoc.data();
    if (data == null) return;

    final passed = data['passedCourses'];
    if (passed == null || passed is! Map<String, dynamic>) return;

    final Map<String, int> aprobadasConNotas = {};
    passed.forEach((codigo, info) {
      if (info is Map && info.containsKey('nota')) {
        aprobadasConNotas[codigo] = info['nota'];
      }
    });

    setState(() {
      _materiasAprobadas = aprobadasConNotas.keys.toSet();
      _notasAprobadas = aprobadasConNotas;
    });
  }

  Future<void> _obtenerMateriasTrimestreActual() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final usuarioDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    final data = usuarioDoc.data();
    final current = data?['currentCourses'] as Map<String, dynamic>?;

    if (current != null) {
      setState(() {
        _materiasTrimestreActual.clear();
        _materiasTrimestreActual.addAll(current.keys);
      });
    }
  }

  double? _calcularPromedioNotas() {
    if (_notasAprobadas.isEmpty) return null;
    final total = _notasAprobadas.values.reduce((a, b) => a + b);
    return total / _notasAprobadas.length;
  }

  Future<void> _toggleMateriaAprobada(String codigo, int creditos) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
    final yaAprobada = _materiasAprobadas.contains(codigo);

    if (yaAprobada) {
      // La estás removiendo de materias aprobadas (regresa a cursando o ninguna)
      await ref.set({
        'passedCourses': {codigo: FieldValue.delete()},
        'credits': FieldValue.increment(-creditos),
      }, SetOptions(merge: true));

      setState(() {
        _materiasAprobadas.remove(codigo);
        _notasAprobadas.remove(codigo);
        _totalCreditos -= creditos;
      });
    } else {
      final nota = await _solicitarNotaFinal(context, codigo);
      if (nota == null) return;

      // La estás agregando como materia aprobada, eliminarla de cursando y sumar créditos
      await ref.set({
        'passedCourses': {
          codigo: {
            'codigo': codigo,
            'nota': nota,
          }
        },
        'currentCourses': {codigo: FieldValue.delete()},
        'credits': FieldValue.increment(creditos),
      }, SetOptions(merge: true));

      setState(() {
        _materiasAprobadas.add(codigo);
        _materiasTrimestreActual.remove(codigo);
        _notasAprobadas[codigo] = nota;
        _totalCreditos += creditos;
      });

      await _obtenerMateriasAprobadas();
    }
  }

  Future<void> _toggleMateriaActual(String codigo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
    final yaEsta = _materiasTrimestreActual.contains(codigo);
    const creditos = 3; // O cámbialo si usas créditos dinámicos

    if (yaEsta) {
      await ref.set({
        'currentCourses': {codigo: FieldValue.delete()}
      }, SetOptions(merge: true));

      setState(() {
        _materiasTrimestreActual.remove(codigo);
      });
    } else {
      final estabaAprobada = _materiasAprobadas.contains(codigo);

      final batch = FirebaseFirestore.instance.batch();

      if (estabaAprobada) {
        // Si estaba en aprobadas, la removemos y restamos créditos
        batch.set(ref, {
          'passedCourses': {codigo: FieldValue.delete()},
          'credits': FieldValue.increment(-creditos)
        }, SetOptions(merge: true));
      }

      // La añadimos a currentCourses
      batch.set(ref, {
        'currentCourses': {codigo: codigo}
      }, SetOptions(merge: true));

      await batch.commit();

      setState(() {
        _materiasTrimestreActual.add(codigo);
        if (estabaAprobada) {
          _materiasAprobadas.remove(codigo);
          _notasAprobadas.remove(codigo);
          _totalCreditos -= creditos;
        }
      });
    }
  }

  Widget _buildLegendButton({
    required Color color,
    required String text,
    required int count,
    required SelectionMode mode,
  }) {
    final isSelected = _selectionMode == mode;

    return InkWell(
      onTap: () {
        setState(() {
          _selectionMode = isSelected ? SelectionMode.none : mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              '$text: $count',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _cargarMateriasDesdeFlujogramaCompuesto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      final usuarioDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      final carreraId = usuarioDoc.data()?['major'];
      if (carreraId == null || carreraId == 'Sin carrera') {
        throw Exception('⚠️ El usuario no tiene carrera asignada.');
      }

      final carreraDoc = await FirebaseFirestore.instance
          .collection('carreras')
          .doc(carreraId)
          .get();

      final flujogramaId = carreraDoc.data()?['flujograma'];
      if (flujogramaId == null) throw Exception('⚠️ No se encontró flujograma para $carreraId');

      final flujogramaDoc = await FirebaseFirestore.instance
          .collection('flujogramas')
          .doc(flujogramaId)
          .get();

      final materiaCodigos = flujogramaDoc.data()?.keys.toList();
      if (materiaCodigos == null || materiaCodigos.isEmpty) {
        throw Exception('⚠️ Flujograma vacío para $flujogramaId');
      }

      final firestore = FirebaseFirestore.instance;

      final refs = materiaCodigos
          .map((codigo) => firestore.collection('materias').doc(codigo))
          .toList();

      final snapshots = await Future.wait(refs.map((ref) => ref.get()));

      final materias = <Map<String, dynamic>>[];

      for (final snap in snapshots) {
        if (snap.exists) {
          final data = snap.data()!;
          materias.add({
            'codigo': snap.id,
            'nombre': data['nombre'] ?? snap.id,
            'creditos': data['creditos'] ?? 0,
            'prerequisitos': data['prerequisitos'] ?? [],
          });
        }
      }

      setState(() {
        _totalMaterias = materias.length;
      });

      return materias;
    } catch (e) {
      debugPrint('❌ Error al cargar materias: $e');
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CustomPaint(
                            painter: DualProgressPainter(
                              approvedFraction: _totalMaterias == 0 ? 0 : _materiasAprobadas.length / _totalMaterias,
                              currentFraction: 0,
                            ),
                          ),
                        ),
                        Text(
                          '${((_materiasAprobadas.length / _totalMaterias) * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 40),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendButton(
                          color: Colors.green,
                          text: 'Materias Aprobadas',
                          count: _materiasAprobadas.length,
                          mode: SelectionMode.approved,
                        ),
                        const SizedBox(height: 12),
                        _buildLegendButton(
                          color: Colors.yellow[700]!,
                          text: 'Materias Trimestre-actual',
                          count: _materiasTrimestreActual.length,
                          mode: SelectionMode.current,
                        ),

                        const SizedBox(height: 12),
                        // Botón para total de créditos con estilo personalizado
                        InkWell(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.grade, color: Colors.black, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Créditos Aprobados: $_totalCreditos',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_notasAprobadas.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'Promedio de notas aprobadas: ${_calcularPromedioNotas()!.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.blueGrey[900],
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Cantidad de materias: $_totalMaterias',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 🔹AGREGADO: Mostrar materias por cursar
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Materias por cursar: ${_totalMaterias - _materiasAprobadas.length}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Contenedor de materias con columnas por trimestre
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        offset: Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),

                ),

                const SizedBox(height: 30),

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
                            final creditos = materia['creditos'];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: SizedBox(
                                width: 225,
                                height: 70,
                                child: ElevatedButton(
                                    onPressed: () {
                                      final creditos = int.parse(materia['creditos'].toString());
                                      if (_selectionMode == SelectionMode.approved) {
                                        _toggleMateriaAprobada(codigo, creditos);
                                        setState(() {
                                          if (_materiasAprobadas.contains(codigo)) {
                                            _materiasAprobadas.remove(codigo);
                                          } else {
                                            _materiasAprobadas.add(codigo);
                                          }
                                        });
                                      } else if (_selectionMode == SelectionMode.current) {
                                        _toggleMateriaActual(codigo);
                                      }
                                    },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _materiasAprobadas.contains(codigo)
                                        ? Colors.green
                                        : _materiasTrimestreActual.contains(codigo)
                                        ? Colors.yellow[700]
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
                                    _notasAprobadas.containsKey(codigo)
                                        ? '$nombre (${_notasAprobadas[codigo]})'
                                        : nombre,
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

class DualProgressPainter extends CustomPainter {
  final double approvedFraction;
  final double currentFraction;

  DualProgressPainter({
    required this.approvedFraction,
    required this.currentFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2 - strokeWidth / 2;

    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final approvedPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final currentPaint = Paint()
      ..color = Colors.yellow[700]!
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final totalAngle = 2 * 3.141592653589793;
    final approvedAngle = totalAngle * approvedFraction;
    final currentAngle = totalAngle * currentFraction;

    double startAngle = -3.141592653589793 / 2;
    if (approvedFraction > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, approvedAngle, false, approvedPaint);
      startAngle += approvedAngle;
    }

    if (currentFraction > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, currentAngle, false, currentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
