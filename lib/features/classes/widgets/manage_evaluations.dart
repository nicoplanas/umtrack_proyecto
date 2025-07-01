import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import '../../classes/views/evaluation_details_page.dart';

class EvaluacionesTab extends StatefulWidget {
  final String claseId;

  const EvaluacionesTab({super.key, required this.claseId});

  @override
  _EvaluacionesTabState createState() => _EvaluacionesTabState();
}

class _EvaluacionesTabState extends State<EvaluacionesTab> {
  String searchQuery = '';
  String selectedTipo = 'Todos';
  final List<String> tipoOptions = [
    'Todos',
    'Parcial',
    'Quiz',
    'Tarea',
    'Taller',
    'Exposición',
  ];

  String _displayTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'parcial':
        return 'Parciales';
      case 'quiz':
        return 'Quizzes';
      case 'tarea':
        return 'Tareas';
      case 'taller':
        return 'Talleres';
      case 'exposición':
        return 'Exposiciones';
      default:
        final capital = tipo[0].toUpperCase() + tipo.substring(1);
        return '${capital}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: SizedBox.expand(
          child: Stack(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('clases')
                    .doc(widget.claseId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final evaluaciones =
                      (data['evaluaciones'] as Map<String, dynamic>?) ?? {};

                  if (evaluaciones.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment,
                              size: 80, color: Color(0xFFFB923C)),
                          const SizedBox(height: 16),
                          Text(
                            'No hay evaluaciones registradas',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              final newId = const Uuid().v4();
                              _showEditDialog(context, widget.claseId, newId, {});
                            },
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Agregar evaluación'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFB923C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              textStyle: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Ordenar por fechaDeCreacion desc
                  final entries = evaluaciones.entries.toList()
                    ..sort((a, b) {
                      final aTs = a.value['fechaDeCreacion'] as Timestamp;
                      final bTs = b.value['fechaDeCreacion'] as Timestamp;
                      return bTs.compareTo(aTs);
                    });

                  // Filtrar por búsqueda y tipo
                  final filtered = entries.where((e) {
                    final nombre = (e.value['nombre'] ?? '').toString().toLowerCase();
                    final matchesSearch = nombre.contains(searchQuery.toLowerCase());
                    final tipoEval = (e.value['tipo'] as String?) ?? '';
                    final matchesTipo =
                        selectedTipo == 'Todos' || tipoEval.toLowerCase() == selectedTipo.toLowerCase();
                    return matchesSearch && matchesTipo;
                  }).toList();

                  // Agrupar por tipo
                  final Map<String, List<MapEntry<String, dynamic>>> grupos = {};
                  for (var e in filtered) {
                    final tipoEval = (e.value['tipo'] as String?) ?? 'Otros';
                    grupos.putIfAbsent(tipoEval, () => []).add(e);
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            // 1️⃣ Barra de búsqueda expandida
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Buscar evaluación...',
                                  prefixIcon: const Icon(Icons.search),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                                onChanged: (v) => setState(() => searchQuery = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 2️⃣ Filtro de tipo a la derecha
                            DropdownButton<String>(
                              value: selectedTipo,
                              items: tipoOptions.map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t == 'Todos' ? 'Todos' : _displayTipo(t),
                                  style: GoogleFonts.poppins(),
                                ),
                              )).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => selectedTipo = v);
                              },
                            ),
                            const SizedBox(width: 12),
                            // 3️⃣ Icono de añadir
                            GestureDetector(
                              onTap: () {
                                final newId = const Uuid().v4();
                                _showEditDialog(context, widget.claseId, newId, {});
                              },
                              child: const Icon(Icons.add, size: 28, color: Color(0xFFFB923C)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: grupos.entries.map((grp) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _displayTipo(grp.key),
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...grp.value.map((entry) {
                                  final evalId = entry.key;
                                  final evaluacion =
                                  entry.value as Map<String, dynamic>;

                                  final nombre =
                                      evaluacion['nombre'] ?? 'Sin nombre';
                                  final rawFecha = evaluacion['fecha'];
                                  String fechaFormateada = '—';
                                  if (rawFecha is Timestamp) {
                                    fechaFormateada = DateFormat(
                                        "d 'de' MMMM 'de' y, h:mm a",
                                        'es_ES')
                                        .format(rawFecha.toDate());
                                  } else if (rawFecha is String) {
                                    fechaFormateada = rawFecha;
                                  }

                                  final dur = evaluacion['duracion']
                                  as Map<String, dynamic>? ??
                                      {};
                                  final tiempo =
                                      dur['tiempo']?.toString() ?? '—';
                                  final unidad = dur['unidad'] ?? 'minutos';

                                  final pond = evaluacion['ponderacion']
                                  as Map<String, dynamic>? ??
                                      {};
                                  final porcentaje =
                                      pond['porcentaje']?.toString() ?? '—';
                                  final puntos =
                                      pond['puntos']?.toString() ?? '—';

                                  final temas =
                                      evaluacion['temas'] ?? 'No especificados';

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EvaluationDetailsPage(
                                            claseId: widget.claseId,
                                            evalId: evalId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.white,
                                        border: Border.all(
                                            color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  nombre,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                    const Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit,
                                                    color:
                                                    Color(0xFF0F172A)),
                                                iconSize: 25,
                                                onPressed: () =>
                                                    _showEditDialog(
                                                        context,
                                                        widget.claseId,
                                                        evalId,
                                                        evaluacion),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.highlight_remove,
                                                    color: Color(
                                                        0xFFEF4444)),
                                                iconSize: 25,
                                                onPressed: () async {
                                                  try {
                                                    final claseRef =
                                                    FirebaseFirestore
                                                        .instance
                                                        .collection(
                                                        'clases')
                                                        .doc(
                                                        widget.claseId);
                                                    final claseSnapshot =
                                                    await claseRef.get();
                                                    final estudiantes = (claseSnapshot
                                                        .data()
                                                    as Map<String,
                                                        dynamic>?)?[
                                                    'estudiantes']
                                                    as Map<String, dynamic>? ??
                                                        {};
                                                    final batch = FirebaseFirestore
                                                        .instance
                                                        .batch();
                                                    batch.update(
                                                        claseRef,
                                                        {
                                                          'evaluaciones.$evalId':
                                                          FieldValue
                                                              .delete()
                                                        });
                                                    for (final sid
                                                    in estudiantes.keys) {
                                                      batch.update(
                                                          claseRef,
                                                          {
                                                            'estudiantes.$sid.evaluaciones.$evalId':
                                                            FieldValue
                                                                .delete()
                                                          });
                                                    }
                                                    await batch.commit();
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(
                                                        context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Error al borrar evaluación: $e'),
                                                        backgroundColor:
                                                        Colors.red,
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Fecha: $fechaFormateada',
                                            style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: const Color(
                                                    0xFF64748B)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Duración: $tiempo $unidad',
                                            style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: const Color(
                                                    0xFF64748B)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Ponderación: $porcentaje% ($puntos puntos)',
                                            style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: const Color(
                                                    0xFF64748B)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Temas: $temas',
                                            style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: const Color(
                                                    0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 16),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context,
      String claseId,
      String evalId,
      Map<String, dynamic> data,) {
    // Detectamos si estamos editando (data con 'nombre') o creando (data vacío)
    final bool isEditing = data.containsKey('nombre') &&
        (data['nombre'] as String).isNotEmpty;
    final String dialogTitle = isEditing
        ? 'Editar evaluación'
        : 'Crear evaluación';
    final String actionText = isEditing ? 'Guardar' : 'Crear';
    final _formKey = GlobalKey<FormState>();

    // Controladores inicializados con los datos (o vacíos)
    final nombreController = TextEditingController(text: data['nombre'] ?? '');
    final tiempoController = TextEditingController(
        text: data['duracion']?['tiempo']?.toString() ?? '');
    final porcentajeController = TextEditingController(
        text: data['ponderacion']?['porcentaje']?.toString() ?? '');
    final temasController = TextEditingController(text: data['temas'] ?? '');

    String modalidadValue = data['modalidad'] as String? ?? 'Presencial';
    String unidadValue = data['duracion']?['unidad'] as String? ?? 'minutos';

    final modalidadOptions = ['Presencial', 'Virtual'];
    final unidadOptions = ['minutos', 'horas'];

    // Fecha inicial (viene de data['fecha'] o ahora)
    DateTime selectedDateTime = data['fecha'] is Timestamp
        ? (data['fecha'] as Timestamp).toDate()
        : DateTime.now();
// ¡Sólo fecha!
    final dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(selectedDateTime),
    );
// ¡Sólo hora!
    final timeController = TextEditingController(
      text: DateFormat('HH:mm').format(selectedDateTime),
    );

// Tipo de evaluación
    String tipoValue = data['tipo'] as String? ?? 'Parcial';
    final tipoOptions = ['Parcial', 'Quiz', 'Taller', 'Tarea', 'Exposición'];

    showDialog(
      context: context,
      builder: (_) =>
          Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título dinámico
                  Text(
                    dialogTitle,
                    style: GoogleFonts.poppins(fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 20),

                  // Nombre
                  _styledTextField(nombreController, 'Nombre'),

                  // Fecha y hora por separado
                  Row(
                    children: [
                      // Día
                      Expanded(
                        child: TextField(
                          controller: dateController,
                          readOnly: true,
                          style: GoogleFonts.poppins(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Fecha',
                            labelStyle: GoogleFonts.poppins(
                                color: Colors.black87),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDateTime,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              // fuerza que el diálogo abra siempre en modo calendario
                              initialEntryMode: DatePickerEntryMode.calendar,
                            );
                            if (date == null) return;
                            selectedDateTime = DateTime(
                              date.year, date.month, date.day,
                              selectedDateTime.hour, selectedDateTime.minute,
                            );
                            dateController.text = DateFormat('dd/MM/yyyy')
                                .format(selectedDateTime);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Hora
                      Expanded(
                        child: TextField(
                          controller: timeController,
                          readOnly: true,
                          style: GoogleFonts.poppins(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Hora',
                            labelStyle: GoogleFonts.poppins(
                                color: Colors.black87),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(
                                  selectedDateTime),
                              initialEntryMode: TimePickerEntryMode
                                  .input, // ← esto fuerza el modo texto al abrir
                            );
                            if (time == null) return;
                            selectedDateTime = DateTime(
                              selectedDateTime.year,
                              selectedDateTime.month,
                              selectedDateTime.day,
                              time.hour,
                              time.minute,
                            );
                            timeController.text = DateFormat('HH:mm').format(
                                selectedDateTime);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tipo (dropdown)
                  DropdownButtonFormField<String>(
                    value: tipoValue,
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      labelStyle: GoogleFonts.poppins(color: Colors.black87),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    style: GoogleFonts.poppins(color: Colors.black),
                    dropdownColor: Colors.white,
                    items: tipoOptions.map((t) =>
                        DropdownMenuItem(value: t,
                            child: Text(
                                t, style: GoogleFonts.poppins(color: Colors
                                .black)))
                    ).toList(),
                    onChanged: (v) => tipoValue = v!,
                  ),
                  const SizedBox(height: 16),

                  // Modalidad
                  DropdownButtonFormField<String>(
                    value: modalidadValue,
                    decoration: InputDecoration(
                      labelText: 'Modalidad',
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: GoogleFonts.poppins(color: Colors.black87),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    style: GoogleFonts.poppins(color: Colors.black),
                    dropdownColor: Colors.white,
                    items: modalidadOptions.map((m) =>
                        DropdownMenuItem(value: m,
                            child: Text(
                                m, style: GoogleFonts.poppins(color: Colors
                                .black)))
                    ).toList(),
                    onChanged: (v) => modalidadValue = v!,
                  ),
                  const SizedBox(height: 16),

                  // Duración (enteros)
                  TextField(
                    controller: tiempoController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.poppins(color: Colors.black),
                    // <- color del texto
                    cursorColor: const Color(0xFFFB923C),
                    decoration: InputDecoration(
                      labelText: 'Duración',
                      labelStyle: GoogleFonts.poppins(color: Colors.black87),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Unidad
                  DropdownButtonFormField<String>(
                    value: unidadValue,
                    decoration: InputDecoration(
                      labelText: 'Unidad',
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: GoogleFonts.poppins(color: Colors.black87),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    style: GoogleFonts.poppins(color: Colors.black),
                    dropdownColor: Colors.white,
                    items: unidadOptions.map((u) =>
                        DropdownMenuItem(value: u,
                            child: Text(
                                u, style: GoogleFonts.poppins(color: Colors
                                .black)))
                    ).toList(),
                    onChanged: (v) => unidadValue = v!,
                  ),
                  const SizedBox(height: 16),

                  // Porcentaje
                  _styledTextField(porcentajeController, 'Porcentaje'),

                  // Temas
                  _styledTextField(temasController, 'Temas'),
                  const SizedBox(height: 16),

                  // Botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.black),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          // Validación de campos obligatorios
                          if (nombreController.text
                              .trim()
                              .isEmpty ||
                              dateController.text.isEmpty ||
                              timeController.text.isEmpty ||
                              tiempoController.text
                                  .trim()
                                  .isEmpty ||
                              porcentajeController.text
                                  .trim()
                                  .isEmpty ||
                              temasController.text
                                  .trim()
                                  .isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Por favor complete todos los campos'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final porcentaje = int.tryParse(
                              porcentajeController.text.trim()) ?? 0;
                          final tiempo = int.tryParse(
                              tiempoController.text.trim()) ?? 0;
                          final puntos = porcentaje * 20 / 100;

                          final evaluacionData = {
                            'nombre': nombreController.text,
                            'modalidad': modalidadValue,
                            'duracion': {
                              'tiempo': tiempo,
                              'unidad': unidadValue,
                            },
                            'ponderacion': {
                              'porcentaje': porcentaje,
                              'puntos': puntos,
                            },
                            'temas': temasController.text,
                            'fecha': selectedDateTime,
                            'tipo': tipoValue,
                            'fechaDeCreacion': data['fechaDeCreacion'] ??
                                DateTime.now(),
                          };

                          final claseRef = FirebaseFirestore.instance
                              .collection('clases').doc(claseId);

                          // Guardar la evaluación
                          await claseRef.update(
                              {'evaluaciones.$evalId': evaluacionData});

                          // Reset notas/comentarios
                          final snapshot = await claseRef.get();
                          final estudiantes = (snapshot
                              .data()?['estudiantes'] as Map<String,
                              dynamic>?) ?? {};
                          final batch = FirebaseFirestore.instance.batch();
                          estudiantes.keys.forEach((sid) {
                            batch.update(claseRef, {
                              'estudiantes.$sid.evaluaciones.$evalId': {
                                'nota': null,
                                'comentarios': '',
                              }
                            });
                          });
                          await batch.commit();

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFB923C),
                          foregroundColor: Colors.white,
                        ),
                        // Texto dinámico
                        child: Text(actionText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _styledTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.black87),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }
}
