import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../../career/widgets/additional_requirements.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

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
  int _vistaSeleccionada = 0;
  String? _carreraId;
  bool _modoEdicion = false;
  final GlobalKey _flujogramaKey = GlobalKey();

  SelectionMode _selectionMode = SelectionMode.none;

  @override
  void initState() {
    super.initState();
    _cargarMateriasYActualizarEstado();
    _obtenerMateriasAprobadas();
    _obtenerMateriasTrimestreActual();
    _obtenerCreditosDesdeBD();
    _loadCarreraId();
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
      child: RepaintBoundary(
        key: _flujogramaKey, // <-- asegúrate de tener esto definido arriba
        child: InteractiveViewer(
          constrained: false,
          scaleEnabled: false,
          panEnabled: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 56), // para no tapar los títulos
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            ...materiasReasignadas.entries.map((entry) {
              final trimestreIndex = entry.key;
              final grupo = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFE2E8F0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
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
                          onAccept: _modoEdicion
                              ? (dragged) async {
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
                          }
                              : null,
                          builder: (context, candidateData, rejectedData) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: _modoEdicion
                                  ? Draggable<Map<String, dynamic>>(
                                data: materia,
                                feedback: Opacity(
                                  opacity: 0.8,
                                  child: _buildMateriaButton(materia),
                                ),
                                childWhenDragging: const SizedBox.shrink(),
                                child: _buildMateriaButton(materia),
                              )
                                  : _buildMateriaButton(materia),
                            );
                          },
                        );
                      }).toList(),
                      DragTarget<Map<String, dynamic>>(
                        onWillAccept: (_) => true,
                        onAccept: _modoEdicion
                            ? (dragged) async {
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
                        }
                            : null,
                        builder: (context, candidateData, rejectedData) =>
                        const SizedBox(height: 24),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // NUEVO TRIMESTRE DINÁMICO: espacio adicional al final para crear nuevo trimestre
            if (_modoEdicion)
              Padding(
                padding: const EdgeInsets.only(top: 52),
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
                            _materiasLocales
                                .map((m) => m['trimestre'] as int)
                                .fold(0, (prev, e) => e > prev ? e : prev) +
                                1,
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
    ),
    ),
    );
  }

// Ayudante opcional para evitar falso positivo en el conteo
  bool _materiaYaExisteEnGrupo(List<Map<String, dynamic>> grupo, String codigo) {
    return grupo.any((m) => m['codigo'] == codigo);
  }

  Future<void> _loadCarreraId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      final data = doc.data();
      if (data != null && data['major'] != null) {
        setState(() {
          _carreraId = data['major'];
        });
      }
    }
  }

  void _mostrarCargando(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text("Generando PDF...")),
          ],
        ),
      ),
    );
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

  void _cambiarVista(int index) {
    setState(() {
      _vistaSeleccionada = index;
    });
  }

  Future<void> _exportarFlujogramaComoPDF() async {
    try {
      final boundary = _flujogramaKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0); // Usa 2.0–3.0 para mejor calidad
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();

      final pdf = pw.Document();
      final imageProvider = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(imageWidth, imageHeight), // ¡Se ajusta al tamaño exacto!
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(imageProvider, fit: pw.BoxFit.contain),
            );
          },
        ),
      );

      Navigator.of(context, rootNavigator: true).pop(); // Cierra loading

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar PDF: $e')),
      );
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

  Future<int?> _solicitarNotaFinal(BuildContext context, String nombreMateria) async {
    final TextEditingController _notaController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    return showDialog<int>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox( // 👈 limita el ancho
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ingresar Nota',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa la nota con la que aprobaste:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nombreMateria,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notaController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Nota (0–20)',
                        hintText: 'Ej: 17',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        labelStyle: const TextStyle(color: Color(0xFF64748B)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      validator: (value) {
                        final nota = int.tryParse(value ?? '');
                        if (nota == null || nota < 0 || nota > 20) {
                          return 'Ingrese un número entero entre 0 y 20';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                final nota = int.parse(_notaController.text);
                                Navigator.of(context).pop(nota);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Guardar',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

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

  Widget _buildToggleButton(String text, int index) {
    final bool selected = _vistaSeleccionada == index;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _vistaSeleccionada = index;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFFFD8305) : const Color(0xFFE2E8F0),
        foregroundColor: selected ? Colors.white : const Color(0xFF1E293B),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
    );
  }

  double? _calcularPromedioNotas() {
    if (_notasAprobadas.isEmpty) return null;
    final total = _notasAprobadas.values.reduce((a, b) => a + b);
    return total / _notasAprobadas.length;
  }

  Future<void> _toggleMateriaAprobada(String codigo, int _) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
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

    // ✅ OBTENER PRERREQUISITOS DESDE LA COLECCIÓN GLOBAL
    final globalMateriaDoc = await FirebaseFirestore.instance
        .collection('materias')
        .doc(codigo)
        .get();

    final globalData = globalMateriaDoc.data();
    final prerequisitos = (globalData?['prerequisitos'] as List<dynamic>?) ?? [];

    // ✅ VALIDAR PRERREQUISITOS
    if (prerequisitos.isNotEmpty) {
      List<String> faltantes = [];

      for (final cod in prerequisitos) {
        if (!_materiasAprobadas.contains(cod)) {
          faltantes.add(cod.toString());
        }
      }

      if (faltantes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '❌ No puedes aprobar esta materia. Faltan prerrequisitos: ${faltantes.join(', ')}'),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    final yaAprobada = _materiasAprobadas.contains(codigo);

    if (yaAprobada) {
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
      final materia = _materiasLocales.firstWhere((m) => m['codigo'] == codigo);
      final nota = await _solicitarNotaFinal(context, materia['nombre']);
      if (nota == null) return;

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

  Future<void> _toggleMateriaActual(String codigo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
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
      // Si ya estaba cursando, se remueve y vuelve a no_aprobada
      batch.set(ref, {
        codigo: {'estado': 'no_aprobada'}
      }, SetOptions(merge: true));

      setState(() {
        _materiasTrimestreActual.remove(codigo);
      });
    } else {
      // 🔒 NUEVA VALIDACIÓN: máximo 7 materias cursando
      if (_materiasTrimestreActual.length >= 7) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Solo puedes cursar un máximo de 7 materias a la vez.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final estabaAprobada = _materiasAprobadas.contains(codigo);

      if (estabaAprobada) {
        // Si estaba aprobada, revertir estado y restar créditos
        batch.set(ref, {
          codigo: {
            'estado': 'cursando',
            'nota': null,
          }
        }, SetOptions(merge: true));

        batch.set(userRef, {
          'credits': FieldValue.increment(-creditos),
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

  Widget _buildVistaButton(String titulo, int index) {
    final bool activo = _vistaSeleccionada == index;
    return GestureDetector(
      onTap: () => _cambiarVista(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFFD8305) : Colors.white,
          border: Border.all(color: const Color(0xFFFD8305)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          titulo,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: activo ? Colors.white : const Color(0xFFFD8305),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorialAcademico() {
    final Map<int, List<Map<String, dynamic>>> materiasPorTrimestre = {};
    final Map<int, double> promedios = {};
    final Map<int, int> cantidadMaterias = {};
    final Map<int, bool> desplegado = {};

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

    materiasPorTrimestre.forEach((trimestre, materias) {
      final promedio = materias.map((m) => m['nota'] as int).reduce((a, b) => a + b) / materias.length;
      promedios[trimestre] = promedio;
      cantidadMaterias[trimestre] = materias.length;
    });

    final sortedEntries = materiasPorTrimestre.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Text(
                'Historial Académico',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Visualiza cada trimestre, materias cursadas y calificaciones obtenidas.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: sortedEntries.map((entry) {
                  final trimestre = entry.key;
                  final promedio = promedios[trimestre]!;
                  final materias = entry.value;
                  final estaDesplegado = desplegado[trimestre] ?? false;

                  Color colorNota;
                  if (promedio >= 18) {
                    colorNota = Colors.green;
                  } else if (promedio >= 15) {
                    colorNota = Colors.yellow;
                  } else if (promedio >= 12) {
                    colorNota = Colors.orange;
                  } else if (promedio >= 10) {
                    colorNota = Colors.red.shade300;
                  } else {
                    colorNota = Colors.red;
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Trimestre $trimestre – 2024',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Promedio: ',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              TextSpan(
                                text: '${promedio.toStringAsFixed(1)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorNota,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${materias.length} ${materias.length == 1 ? 'materia' : 'materias'}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              desplegado[trimestre] = !estaDesplegado;
                            });
                          },
                          child: AnimatedRotation(
                            turns: estaDesplegado ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.expand_more, size: 24),
                          ),
                        ),
                        if (estaDesplegado) ...[
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: materias.map((m) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '• ${m['nombre']}: ${m['nota']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leyenda de Calificaciones',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Columna izquierda (2 items)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _leyendaItem('Excelente (18–20)', Colors.green),
                            const SizedBox(height: 12),
                            _leyendaItem('Bueno (15–17)', Colors.yellow),
                          ],
                        ),

                        // Columna centro (2 items)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _leyendaItem('Regular (12–14)', Colors.orange),
                            const SizedBox(height: 12),
                            _leyendaItem('Deficiente (10-11)', Colors.red.shade300), // slate gray
                          ],
                        ),

                        // Columna derecha (1 item)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _leyendaItem('Grave (0–9)', Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequerimientosAdicionales() {
    if (_carreraId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AdditionalRequirements(carreraId: _carreraId!);
  }

  Widget _leyendaItem(String texto, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          texto,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
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
                    fontSize: 35,
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

                if (!_modoEdicion)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildVistaButton('Flujograma', 0),
                        const SizedBox(width: 16),
                        _buildVistaButton('Historial Académico', 1),
                        const SizedBox(width: 16),
                        _buildVistaButton('Requerimientos Adicionales', 2),
                      ],
                    ),
                  ),
                if (_vistaSeleccionada == 0 && _modoEdicion)
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
                                ? const Color(0xFFFD8305)
                                : Colors.white,
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
                                ? const Color(0xFF3B82F6)
                                : Colors.white,
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
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _cargandoMaterias
                            ? const Center(child: CircularProgressIndicator())
                            : _materiasLocales.isEmpty
                            ? const Center(child: Text('No se encontraron materias'))
                            : _vistaSeleccionada == 0
                            ? _buildMateriasUI()
                            : _vistaSeleccionada == 1
                            ? _buildHistorialAcademico()
                            : _buildRequerimientosAdicionales(),
                      ),
                      // Menú de tres puntos
                      if (_vistaSeleccionada == 0)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x11000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.fullscreen, color: Color(0xFF475569)),
                                  tooltip: 'Expandir Flujograma',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (_) {
                                        return Dialog(
                                          insetPadding: const EdgeInsets.all(16),
                                          backgroundColor: Colors.white,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context).size.width * 0.95,
                                              maxHeight: MediaQuery.of(context).size.height * 0.85,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Header con cerrar
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Vista Ampliada del Flujograma',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.w600,
                                                          color: const Color(0xFF1E293B),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.close),
                                                        onPressed: () => Navigator.of(context).pop(),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  // Flujograma expandido con scroll horizontal
                                                  Flexible(
                                                    child: SingleChildScrollView(
                                                      scrollDirection: Axis.horizontal,
                                                      child: _buildMateriasUI(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                PopupMenuButton<String>(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onSelected: (value) {
                                    if (value == 'editar') {
                                      setState(() {
                                        _modoEdicion = !_modoEdicion;
                                        _selectionMode = SelectionMode.none;
                                      });
                                    } else if (value == 'pdf') {
                                      _exportarFlujogramaComoPDF();
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'editar',
                                      child: Text(_modoEdicion ? 'Salir del Modo Edición' : 'Editar'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'pdf',
                                      child: Text('Descargar PDF'),
                                    ),
                                  ],
                                  icon: const Icon(Icons.more_vert),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32), // Espaciado visual
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
