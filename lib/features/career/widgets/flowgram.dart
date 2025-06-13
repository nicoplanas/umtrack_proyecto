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

  Set<String> _materiasTrimestreActual = {};
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

    final trimestresOriginalesOrdenados = materiasPorTrimestre.keys.toList()..sort();
    final Map<int, List<Map<String, dynamic>>> materiasReasignadas = {};
    for (int i = 0; i < trimestresOriginalesOrdenados.length; i++) {
      final nuevaClave = i + 1;
      final viejaClave = trimestresOriginalesOrdenados[i];
      final lista = materiasPorTrimestre[viejaClave]!;
      for (final materia in lista) {
        materia['trimestre'] = nuevaClave;
      }
      materiasReasignadas[nuevaClave] = lista;
    }

    final trimestresLabels = [
      '1er Trimestre', '2do Trimestre', '3er Trimestre', '4to Trimestre',
      '5to Trimestre', '6to Trimestre', '7mo Trimestre', '8vo Trimestre',
      '9no Trimestre', '10mo Trimestre', '11vo Trimestre', '12vo Trimestre'
    ];

    final ultimoTrimestre = materiasReasignadas.keys.isEmpty
        ? 1
        : materiasReasignadas.keys.reduce((a, b) => a > b ? a : b);

    return GestureDetector(
      onHorizontalDragStart: (_) {},
      child: InteractiveViewer(
        constrained: false,
        scaleEnabled: false,
        panEnabled: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...materiasReasignadas.entries.map((entry) {
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
                            if (grupo.length >= 7 &&
                                !_materiaYaExisteEnGrupo(grupo, dragged['codigo'])) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('⚠️ Máximo 7 materias por trimestre alcanzado.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            await _actualizarPosicionMateria(
                              dragged['codigo'],
                              trimestreIndex,
                              indexMateria,
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
                                content: Text('⚠️ Máximo 7 materias por trimestre alcanzado.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          await _actualizarPosicionMateria(
                            dragged['codigo'],
                            trimestreIndex,
                            grupo.length,
                          );
                        },
                        builder: (context, candidateData, rejectedData) =>
                        const SizedBox(height: 24),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // NUEVO TRIMESTRE DINÁMICO: espacio adicional al final para crear nuevo trimestre
            // Al final del Row de columnas
            Padding(
              padding: const EdgeInsets.only(top: 52), // Ajusta este valor hasta que esté alineado
              child: SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DragTarget<Map<String, dynamic>>(
                      onWillAccept: (_) => true,
                      onAccept: (dragged) async {
                        await _actualizarPosicionMateria(
                          dragged['codigo'],
                          _materiasLocales.map((m) => m['trimestre'] as int).fold(0, (prev, e) => e > prev ? e : prev) + 1,
                          0,
                        );
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+ Agregar trimestre nuevo',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    final materias = await _cargarMateriasDesdeFlujogramaPersonalizado();

    setState(() {
      _materiasLocales = materias;
      _totalMaterias = materias.length; // ✅ Calcula el total real
      _cargandoMaterias = false;
    });
  }


  Future<void> _actualizarPosicionMateria(String codigo, int nuevoTrimestre, int nuevoOrden) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final usuarioDoc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
    final carreraId = usuarioDoc.data()?['major'];
    if (carreraId == null) return;

    final flujogramaId = carreraId.replaceFirst(RegExp(r'^[A-Z]+'), 'FLU');

    final refFlujograma = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('flujogramas')
        .doc(flujogramaId);

    final flujogramaDoc = await refFlujograma.get();
    final flujograma = flujogramaDoc.data();
    if (flujograma == null) return;

    // Obtener el trimestre original de la materia antes del movimiento
    final trimestreOriginal = flujograma[codigo]?['trimestre'];

    // Filtrar materias que pertenecerán al nuevo trimestre
    final materiasEnTrimestre = flujograma.entries
        .where((e) => e.value is Map && e.value['trimestre'] == nuevoTrimestre)
        .map((e) => {
      'codigo': e.key,
      'ordenEnColumna': e.value['ordenEnColumna'] ?? 99,
    })
        .toList();

    // Quitar la materia que estamos moviendo (si está en la misma lista)
    materiasEnTrimestre.removeWhere((m) => m['codigo'] == codigo);

    // Insertar la materia en la nueva posición
    materiasEnTrimestre.insert(nuevoOrden, {'codigo': codigo});

    // Construir nuevo mapa con nuevos índices
    final Map<String, dynamic> actualizaciones = {};
    for (int i = 0; i < materiasEnTrimestre.length; i++) {
      final codigoMateria = materiasEnTrimestre[i]['codigo'];
      actualizaciones[codigoMateria] = {
        'ordenEnColumna': i,
        'trimestre': nuevoTrimestre,
      };
    }

    // Actualizar la UI inmediatamente
    setState(() {
      for (final materia in _materiasLocales) {
        if (actualizaciones.containsKey(materia['codigo'])) {
          materia['ordenEnColumna'] = actualizaciones[materia['codigo']]['ordenEnColumna'];
          materia['trimestre'] = actualizaciones[materia['codigo']]['trimestre'];
        }
      }
    });

    final batch = FirebaseFirestore.instance.batch();

    // Aplicar actualizaciones normales
    for (final entry in actualizaciones.entries) {
      final codigo = entry.key;
      final data = entry.value;
      batch.update(refFlujograma, {
        '$codigo.trimestre': data['trimestre'],
        '$codigo.ordenEnColumna': data['ordenEnColumna'],
      });
    }

    // Verificar si el trimestre original quedó vacío
    if (trimestreOriginal != null && trimestreOriginal != nuevoTrimestre) {
      final materiasEnOriginal = flujograma.entries.where((e) =>
      e.key != codigo &&
          e.value is Map &&
          e.value['trimestre'] == trimestreOriginal);

      if (materiasEnOriginal.isEmpty) {
        // Si no quedan materias, ajustar todos los trimestres posteriores
        for (final entry in flujograma.entries) {
          final data = entry.value;
          if (data is Map &&
              data.containsKey('trimestre') &&
              data['trimestre'] > trimestreOriginal) {
            final codigoMateria = entry.key;
            batch.update(refFlujograma, {
              '$codigoMateria.trimestre': data['trimestre'] - 1,
            });
          }
        }
      }
    }

    await batch.commit();
    _cargarMateriasYActualizarEstado();
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

  // ACTUALIZADO!!!!!!!!
  Future<void> _obtenerMateriasAprobadas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
    final carreraId = userDoc.data()?['major'];
    if (carreraId == null) return;

    final flujogramaId = carreraId.replaceFirst(RegExp(r'^[A-Z]+'), 'FLU');
    final flujogramaDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('flujogramas')
        .doc(flujogramaId)
        .get();

    final flujogramaData = flujogramaDoc.data();
    if (flujogramaData == null) return;

    final Set<String> aprobadas = {};
    final Map<String, int> notas = {};

    flujogramaData.forEach((codigo, info) {
      if (info is Map<String, dynamic>) {
        if (info['estado'] == 'aprobada' && info.containsKey('nota')) {
          aprobadas.add(codigo);
          final nota = int.tryParse(info['nota'].toString());
          if (nota != null) notas[codigo] = nota;
        }
      }
    });

    setState(() {
      _materiasAprobadas = aprobadas;
      _notasAprobadas = notas;
    });
  }

  // ACTUALIZADO!!!
  Future<void> _obtenerMateriasTrimestreActual() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
    final carreraId = userDoc.data()?['major'];
    if (carreraId == null) return;

    final flujogramaId = carreraId.replaceFirst(RegExp(r'^[A-Z]+'), 'FLU');
    final flujogramaRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('flujogramas')
        .doc(flujogramaId);

    final flujogramaDoc = await flujogramaRef.get();
    final flujogramaData = flujogramaDoc.data();
    if (flujogramaData == null) return;

    final Set<String> cursando = {};
    final Map<String, dynamic> actualizaciones = {};

    flujogramaData.forEach((codigo, info) {
      if (info is Map<String, dynamic>) {
        final estado = info['estado'];

        if (estado == 'cursando') {
          cursando.add(codigo);
        }
        // Solo actualizar si el estado es null
        else if (estado == null) {
          actualizaciones[codigo] = {'estado': 'cursando'};
          cursando.add(codigo);
        }
      }
    });

    if (actualizaciones.isNotEmpty) {
      await flujogramaRef.set(actualizaciones, SetOptions(merge: true));
    }

    setState(() {
      _materiasTrimestreActual = cursando;
    });
  }

  double? _calcularPromedioNotas() {
    if (_notasAprobadas.isEmpty) return null;
    final total = _notasAprobadas.values.reduce((a, b) => a + b);
    return total / _notasAprobadas.length;
  }

  // ACTUALIZADO!!!
  Future<void> _toggleMateriaAprobada(String codigo, int _) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);

    // Obtener el major del usuario
    final userDoc = await userRef.get();
    final carreraId = userDoc.data()?['major'];
    if (carreraId == null) return;

    final flujogramaId = carreraId.replaceFirst(RegExp(r'^[A-Z]+'), 'FLU');
    final materiaRef = userRef.collection('flujogramas').doc(flujogramaId);

    final flujogramaDoc = await materiaRef.get();
    final flujogramaData = flujogramaDoc.data();
    if (flujogramaData == null) return;

    final datosMateria = flujogramaData[codigo];
    final creditosMateria = (datosMateria is Map && datosMateria['creditos'] is int)
        ? datosMateria['creditos'] as int
        : 3;

    final yaAprobada = _materiasAprobadas.contains(codigo);

    if (yaAprobada) {
      // Cambiar estado a no_aprobada y nota a null
      await Future.wait([
        materiaRef.update({
          '$codigo.estado': 'no_aprobada',
          '$codigo.nota': null,
        }),
        userRef.update({
          'credits': FieldValue.increment(-creditosMateria),
        }),
      ]);

      setState(() {
        _materiasAprobadas.remove(codigo);
        _notasAprobadas.remove(codigo);
        _totalCreditos -= creditosMateria;
      });
    } else {
      final nota = await _solicitarNotaFinal(context, codigo);
      if (nota == null) return;

      // Cambiar estado a aprobada y guardar nota
      await Future.wait([
        materiaRef.update({
          '$codigo.estado': 'aprobada',
          '$codigo.nota': nota,
        }),
        userRef.update({
          'credits': FieldValue.increment(creditosMateria),
        }),
      ]);

      setState(() {
        _materiasAprobadas.add(codigo);
        _materiasTrimestreActual.remove(codigo);
        _notasAprobadas[codigo] = nota;
        _totalCreditos += creditosMateria;
      });
    }

    await _obtenerMateriasAprobadas();
    await _obtenerCreditosDesdeBD();
  }

  // ACTUALIZADO!!!
  Future<void> _toggleMateriaActual(String codigo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    // Obtener major → convertir a ID de flujograma
    final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    final carreraId = userDoc.data()?['major'];
    if (carreraId == null) return;

    final flujogramaId = carreraId.replaceFirst(RegExp(r'^[A-Z]+'), 'FLU');
    final ref = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('flujogramas')
        .doc(flujogramaId);

    final flujogramaDoc = await ref.get();
    final data = flujogramaDoc.data();
    if (data == null || !data.containsKey(codigo)) return;

    final estadoActual = data[codigo]['estado'];
    final int creditos = (data[codigo]['creditos'] ?? 3) as int;

    final batch = FirebaseFirestore.instance.batch();
    final userRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);

    if (estadoActual == 'cursando') {
      batch.set(ref, {
        codigo: {'estado': 'no_aprobada'}
      }, SetOptions(merge: true));

      setState(() {
        _materiasTrimestreActual.remove(codigo);
      });
    } else {
      final estabaAprobada = _materiasAprobadas.contains(codigo);

      if (estabaAprobada) {
        // Borramos nota y restamos créditos
        batch.set(ref, {
          codigo: {
            'estado': 'cursando',
            'nota': null
          }
        }, SetOptions(merge: true));

        batch.set(userRef, {
          'credits': FieldValue.increment(-creditos)
        }, SetOptions(merge: true));

        setState(() {
          _materiasAprobadas.remove(codigo);
          _notasAprobadas.remove(codigo);
          _totalCreditos -= creditos;
        });
      } else {
        batch.set(ref, {
          codigo: {'estado': 'cursando'}
        }, SetOptions(merge: true));
      }

      setState(() {
        _materiasTrimestreActual.add(codigo);
      });
    }

    await batch.commit();

    await _obtenerMateriasTrimestreActual();
    await _obtenerCreditosDesdeBD();
  }

  // ACTUALIZADO!!!!!!!!
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final creditosInt = int.tryParse(creditos.toString()) ?? 3;
          if (_selectionMode == SelectionMode.approved) {
            _toggleMateriaAprobada(codigo, creditosInt);
          } else if (_selectionMode == SelectionMode.current) {
            _toggleMateriaActual(codigo);
          }
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
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
      ),
    );
  }

  // ACTUALIZADO!!!!!!!!
  Future<List<Map<String, dynamic>>> _cargarMateriasDesdeFlujogramaPersonalizado() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    final carreraId = userDoc.data()?['major'];
    if (carreraId == null) return [];

    final flujogramaId = carreraId.replaceFirst(RegExp(r'^[A-Z]+'), 'FLU');

    final flujogramaDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('flujogramas')
        .doc(flujogramaId)
        .get();

    final flujogramaData = flujogramaDoc.data();
    if (flujogramaData == null || flujogramaData.isEmpty) return [];

    final firestore = FirebaseFirestore.instance;
    final List<String> codigosMaterias = flujogramaData.keys.toList();

    // 🚀 Ejecutar consultas en paralelo con Future.wait
    List<Future<QuerySnapshot>> futureBatches = [];
    const batchSize = 10;

    for (var i = 0; i < codigosMaterias.length; i += batchSize) {
      final batch = codigosMaterias.sublist(
        i,
        i + batchSize > codigosMaterias.length ? codigosMaterias.length : i + batchSize,
      );

      futureBatches.add(
        firestore
            .collection('materias')
            .where(FieldPath.documentId, whereIn: batch)
            .get(),
      );
    }

    final querySnapshots = await Future.wait(futureBatches);

    List<DocumentSnapshot> documentosMaterias = [];
    for (final snapshot in querySnapshots) {
      documentosMaterias.addAll(snapshot.docs);
    }

    // 🔁 Crear un mapa rápido para acceder por código
    final Map<String, Map<String, dynamic>> materiasGlobales = {
      for (var doc in documentosMaterias) doc.id: doc.data() as Map<String, dynamic>,
    };

    // 🔧 Combinar datos del flujograma personalizado + colección materias
    final List<Map<String, dynamic>> materiasCompletas = [];

    for (final entry in flujogramaData.entries) {
      final codigo = entry.key;
      final datosFlujo = Map<String, dynamic>.from(entry.value);
      final datosMateria = materiasGlobales[codigo];

      materiasCompletas.add({
        'codigo': codigo,
        'estado': datosFlujo['estado'] ?? 'no_aprobada',
        'nota': datosFlujo['nota'],
        'trimestre': datosFlujo['trimestre'] ?? 99,
        'ordenEnColumna': datosFlujo['ordenEnColumna'] ?? 99,
        'nombre': datosMateria?['nombre'] ?? codigo,
        'prerequisitos': datosMateria?['prerequisitos'] ?? [],
        'creditos': datosMateria?['creditos'] ?? 3,
      });
    }

    return materiasCompletas;
  }

  Widget _buildHistorialAcademico() {
    // Agrupar materias aprobadas por trimestre
    final Map<int, List<Map<String, dynamic>>> materiasPorTrimestre = {};

    for (final materia in _materiasLocales) {
      final int? trimestre = materia['trimestre'];
      final int? nota = _notasAprobadas[materia['codigo']];
      if (trimestre != null && nota != null) {
        materiasPorTrimestre.putIfAbsent(trimestre, () => []).add({
          'nombre': materia['nombre'],
          'nota': nota,
        });
      }
    }

    // Ordenar trimestres
    final trimestresOrdenados = materiasPorTrimestre.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Text(
            'Historial Académico',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: trimestresOrdenados.map((entry) {
                  final trimestre = entry.key;
                  final materias = entry.value;

                  final promedio = materias.isNotEmpty
                      ? (materias.map((m) => m['nota'] as int).reduce((a, b) => a + b) / materias.length)
                      : 0.0;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Trimestre $trimestre',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Prom: ${promedio.toStringAsFixed(1)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...materias.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${m['nombre']}: ${m['nota']}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        )),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
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
                const SizedBox(height: 32), // Espaciado visual
                _buildHistorialAcademico(),
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
