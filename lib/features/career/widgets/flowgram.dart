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
  List<Map<String, dynamic>> _materiasLocales = [];
  bool _cargandoMaterias = true;
  Set<String> _materiasAprobadas = {};
  Map<String, int> _notasAprobadas = {};

  final Set<String> _materiasTrimestreActual = {};
  int _totalMaterias = 0;
  int _totalCreditos = 0;
  int _creditosDesdeBD = 0;

  SelectionMode _selectionMode = SelectionMode.none;

  @override
  void initState() {
    super.initState();
    _cargarMateriasYActualizarEstado();
    _obtenerMateriasAprobadas();
    _obtenerMateriasTrimestreActual();
    _obtenerCreditosDesdeBD();
  }

  Widget _buildMateriasUI() {
    final Map<int, List<Map<String, dynamic>>> materiasPorTrimestre = {};

    for (final materia in _materiasLocales) {
      final trimestre = materia['trimestre'] as int?;
      if (trimestre == null) continue;
      materiasPorTrimestre.putIfAbsent(trimestre, () => []).add(materia);
    }

    materiasPorTrimestre.forEach((_, lista) {
      lista.sort((a, b) {
        final aOrden = a['ordenEnColumna'] as int? ?? 999;
        final bOrden = b['ordenEnColumna'] as int? ?? 999;
        return aOrden.compareTo(bOrden);
      });
    });

    final columnasOrdenadas = materiasPorTrimestre.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final trimestresLabels = [
      '1er Trimestre', '2do Trimestre', '3er Trimestre', '4to Trimestre',
      '5to Trimestre', '6to Trimestre', '7mo Trimestre', '8vo Trimestre',
      '9no Trimestre', '10mo Trimestre', '11vo Trimestre', '12vo Trimestre'
    ];

    return GestureDetector(
      onHorizontalDragStart: (_) {}, // evita gesto de retroceso en iOS/Android
      child: InteractiveViewer(
        constrained: false,
        scaleEnabled: false,
        panEnabled: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columnasOrdenadas.map((entry) {
            final trimestreIndex = entry.key;
            final grupo = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trimestreIndex <= trimestresLabels.length
                          ? trimestresLabels[trimestreIndex - 1]
                          : 'Trimestre $trimestreIndex',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...grupo.asMap().entries.take(7).map((entryMateria) {
                      final materia = entryMateria.value;
                      final indexMateria = entryMateria.key;

                      return DragTarget<Map<String, dynamic>>(
                        onWillAccept: (_) => true,
                        onAccept: (dragged) async {
                          final nuevaPosicion = indexMateria;

                          if (grupo.length >= 7 &&
                              !_materiaYaExisteEnGrupo(grupo, dragged['codigo'])) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                Text('⚠️ Máximo 7 materias por trimestre alcanzado.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          await _actualizarPosicionMateria(
                            dragged['codigo'],
                            trimestreIndex,
                            nuevaPosicion,
                          );
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Draggable<Map<String, dynamic>>(
                              data: materia,
                              feedback: Opacity(
                                opacity: 0.8,
                                child: _buildMateriaButton(materia),
                              ),
                              childWhenDragging: const SizedBox.shrink(),
                              child: _buildMateriaButton(materia),
                            ),
                          );
                        },
                      );
                    }).toList(),
                    DragTarget<Map<String, dynamic>>(
                      onWillAccept: (_) => true,
                      onAccept: (dragged) async {
                        if (grupo.length >= 7 &&
                            !_materiaYaExisteEnGrupo(grupo, dragged['codigo'])) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                              Text('⚠️ Máximo 7 materias por trimestre alcanzado.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }

                        final nuevaPosicion = grupo.length;

                        await _actualizarPosicionMateria(
                          dragged['codigo'],
                          trimestreIndex,
                          nuevaPosicion,
                        );
                      },
                      builder: (context, candidateData, rejectedData) =>
                      const SizedBox(height: 24),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

// Ayudante opcional para evitar falso positivo en el conteo
  bool _materiaYaExisteEnGrupo(List<Map<String, dynamic>> grupo, String codigo) {
    return grupo.any((m) => m['codigo'] == codigo);
  }

  Future<void> _obtenerCreditosDesdeBD() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
    final data = userDoc.data();
    if (data == null) return;

    final creditos = data['credits'];
    if (creditos is int) {
      setState(() {
        _creditosDesdeBD = creditos;
      });
    }
  }

  Future<void> _cargarMateriasYActualizarEstado() async {
    _cargandoMaterias = true;
    final materias = await _cargarMateriasDesdeFlujogramaCompuesto();
    setState(() {
      _materiasLocales = materias;
      _cargandoMaterias = false;
    });
  }

  Future<void> _actualizarPosicionMateria(String codigo, int nuevoTrimestre, int nuevoOrden) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final usuarioDoc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
    final carreraId = usuarioDoc.data()?['major'];
    final carreraDoc = await FirebaseFirestore.instance.collection('carreras').doc(carreraId).get();
    final flujogramaId = carreraDoc.data()?['flujograma'];
    if (flujogramaId == null) return;

    final ref = FirebaseFirestore.instance.collection('flujogramas').doc(flujogramaId);
    final flujogramaDoc = await ref.get();
    final flujograma = flujogramaDoc.data();
    if (flujograma == null) return;

    // Filtrar materias que pertenecen al trimestre destino
    final materiasEnTrimestre = flujograma.entries
        .where((e) => e.value is Map && e.value['trimestre'] == nuevoTrimestre)
        .map((e) => {
      'codigo': e.key,
      'ordenEnColumna': e.value['ordenEnColumna'] ?? 99,
    }).toList();

    // Quitar la materia que estamos moviendo (si está en la misma lista)
    materiasEnTrimestre.removeWhere((m) => m['codigo'] == codigo);

    // Insertar la materia en la nueva posición
    materiasEnTrimestre.insert(nuevoOrden, {'codigo': codigo});

    // Construir nuevo mapa con nuevos índices
    final Map<String, dynamic> actualizaciones = {};
    for (int i = 0; i < materiasEnTrimestre.length; i++) {
      final codigoMateria = materiasEnTrimestre[i]['codigo'];
      actualizaciones[codigoMateria] = {
        'trimestre': nuevoTrimestre,
        'ordenEnColumna': i,
      };
    }

    setState(() {
      // Actualización optimista
      for (final materia in _materiasLocales) {
        if (materia['codigo'] == codigo) {
          materia['trimestre'] = nuevoTrimestre;
          materia['ordenEnColumna'] = nuevoOrden;
        }
      }
    }
    );
    // Actualizar todos de una sola vez
    await ref.set(actualizaciones, SetOptions(merge: true));;
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
    }
    await _obtenerMateriasAprobadas();
    await _obtenerCreditosDesdeBD();
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

  Widget _buildMateriaButton(Map<String, dynamic> materia) {
    final nombre = materia['nombre'];
    final codigo = materia['codigo'];
    final creditos = materia['creditos'];
    final prerrequisitos = (materia['prerequisitos'] as List<dynamic>? ?? []).join(', ');

    final bool isAprobada = _materiasAprobadas.contains(codigo);
    final bool isActual = _materiasTrimestreActual.contains(codigo);

    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFE2E8F0); // gris claro
    Color textColor = const Color(0xFF0F172A); // gris oscuro

    if (isAprobada) {
      bgColor = Colors.orange[100]!;
      borderColor = Colors.orangeAccent;
      textColor = Colors.orange[900]!;
    } else if (isActual) {
      bgColor = Colors.blue[100]!;
      borderColor = Colors.blue;
      textColor = Colors.blue[900]!;
    }

    return GestureDetector(
      onTap: () {
        final creditosInt = int.tryParse(creditos.toString()) ?? 3;
        if (_selectionMode == SelectionMode.approved) {
          _toggleMateriaAprobada(codigo, creditosInt);
        } else if (_selectionMode == SelectionMode.current) {
          _toggleMateriaActual(codigo);
        }
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nombre,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            if (prerrequisitos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Prerrequisitos: $prerrequisitos',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: textColor.withOpacity(0.75),
                  ),
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

      final flujogramaData = flujogramaDoc.data();
      if (flujogramaData == null || flujogramaData.isEmpty) {
        throw Exception('⚠️ Flujograma vacío para $flujogramaId');
      }

      final materiaCodigos = flujogramaData.keys.toList();
      final firestore = FirebaseFirestore.instance;

      final refs = materiaCodigos.map((codigo) => firestore.collection('materias').doc(codigo)).toList();
      final snapshots = await Future.wait(refs.map((ref) => ref.get()));

      final materias = <Map<String, dynamic>>[];

      for (final snap in snapshots) {
        if (snap.exists) {
          final data = snap.data()!;
          final codigo = snap.id;
          final rawFlujo = flujogramaData[codigo];

          final trimestre = rawFlujo is Map && rawFlujo.containsKey('trimestre')
              ? rawFlujo['trimestre'] as int
              : 99;
          final ordenEnColumna = rawFlujo is Map && rawFlujo.containsKey('ordenEnColumna')
              ? rawFlujo['ordenEnColumna'] as int
              : 99;

          materias.add({
            'codigo': codigo,
            'nombre': data['nombre'] ?? codigo,
            'creditos': data['creditos'] ?? 0,
            'prerequisitos': data['prerequisitos'] ?? [],
            'trimestre': trimestre,
            'ordenEnColumna': ordenEnColumna,
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

    return WillPopScope(
    onWillPop: () async => false,
    child: Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  'Progreso Académico',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Visualiza y gestiona tu progreso académico de manera intuitiva',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(80, 80),
                                  painter: DualProgressPainter(
                                    approvedFraction: porcentaje,
                                    currentFraction: 0.0, // o cámbialo si quieres mostrar también materias actuales
                                    strokeWidth: 8,
                                  ),
                                ),
                                Text(
                                  '${(porcentaje * 100).toStringAsFixed(0)}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFD8305),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Completado',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Créditos',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$_creditosDesdeBD',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: const Color(0xFFFD8305),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Acumulados',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Promedio',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _calcularPromedioNotas()?.toStringAsFixed(2) ?? '0.00',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFD8305),
                            ),
                          ),
                          Text(
                            'General',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Materias',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_materiasAprobadas.length}/${_totalMaterias}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFD8305),
                            ),
                          ),
                          Text(
                            'Aprobadas',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectionMode = _selectionMode == SelectionMode.approved
                                ? SelectionMode.none
                                : SelectionMode.approved;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectionMode == SelectionMode.approved
                              ? const Color(0xFFFD8305) // Activo: Naranja
                              : Colors.white,            // Inactivo: Blanco
                          side: const BorderSide(
                            color: Color(0xFFFD8305),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                        ),
                        child: Text(
                          'Marcar Materias Aprobadas',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectionMode == SelectionMode.approved
                                ? Colors.white
                                : const Color(0xFFFD8305),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectionMode = _selectionMode == SelectionMode.current
                                ? SelectionMode.none
                                : SelectionMode.current;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectionMode == SelectionMode.current
                              ? const Color(0xFF3B82F6) // Activo: Azul
                              : Colors.white,            // Inactivo: Blanco
                          side: const BorderSide(
                            color: Color(0xFF3B82F6),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                        ),
                        child: Text(
                          'Seleccionar Materias Actuales',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectionMode == SelectionMode.current
                                ? Colors.white
                                : const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
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
                    child: _cargandoMaterias
                        ? const Center(child: CircularProgressIndicator())
                        : _materiasLocales.isEmpty
                        ? const Center(child: Text('No se encontraron materias'))
                        : _buildMateriasUI(),
                  ),
                ),
              ],
            ),
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
  final Color color;
  final double strokeWidth;

  DualProgressPainter({
    required this.approvedFraction,
    required this.currentFraction,
    this.color = const Color(0xFFFD8305), // fallback
    this.strokeWidth = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2 - strokeWidth / 2;

    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final approvedPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final totalAngle = 2 * 3.141592653589793;
    final approvedAngle = totalAngle * approvedFraction;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592653589793 / 2,
      approvedAngle,
      false,
      approvedPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
