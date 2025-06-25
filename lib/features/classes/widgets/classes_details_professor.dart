import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../student/views/manage_student_page.dart';
import '../widgets/manage_evaluations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

class ClassesDetailsProfessor extends StatelessWidget {
  final String claseId;
  final Map<String, dynamic> claseData;

  const ClassesDetailsProfessor({
    super.key,
    required this.claseId,
    required this.claseData,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // TopBar con botón, texto y título integrado
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Volver a Asignaturas',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    claseData['nombreMateria'] ?? 'Materia',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const TabBar(
            labelColor: Color(0xFFFB923C),
            unselectedLabelColor: Color(0xFF94A3B8),
            indicatorColor: Color(0xFFFB923C),
            tabs: [
              Tab(text: 'Estudiantes'),
              Tab(text: 'Evaluaciones'),
              Tab(text: 'Contenidos'),
              Tab(text: 'Reportes'),
            ],
          ),

          SizedBox(
            height: 500,
            child: TabBarView(
              children: [
                StudentsTab(claseId: claseId),
                EvaluacionesTab(claseId: claseId),
                ContenidosTab(claseId: claseId),
                Center(child: Text('Reportes')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContenidosTab extends StatefulWidget {
  final String claseId;

  const ContenidosTab({Key? key, required this.claseId}) : super(key: key);

  @override
  State<ContenidosTab> createState() => _ContenidosTabState();
}

class _ContenidosTabState extends State<ContenidosTab> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String linkArchivo = '';
  bool isUploading = false;
  Map<String, dynamic> contenidosMap = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContenidos();
  }

  Future<void> _loadContenidos() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('clases')
        .doc(widget.claseId)
        .get();

    final data = snapshot.data() as Map<String, dynamic>?;
    setState(() {
      contenidosMap = Map<String, dynamic>.from(data?['contenidos'] ?? {});
      isLoading = false;
    });
  }

  void _showAgregarContenidoDialog() {
    String titulo = '';
    String descripcion = '';
    String linkArchivo = '';
    bool isUploading = false;

    Future<void> _uploadFileFromDevice() async {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se seleccionó archivo')),
        );
        return;
      }

      final picked = result.files.first;
      final mimeType = lookupMimeType(picked.name);

      if (mimeType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipo de archivo desconocido')),
        );
        return;
      }

      String resourceType = 'image';
      if (mimeType.startsWith('video/')) {
        resourceType = 'video';
      } else if (!mimeType.startsWith('image/')) {
        resourceType = 'raw';
      }

      final uploadUrl = Uri.parse(
        'https://api.cloudinary.com/v1_1/doyt5r47e/$resourceType/upload',
      );

      final request = http.MultipartRequest('POST', uploadUrl)
        ..fields['upload_preset'] = 'UMTrack';

      if (kIsWeb || picked.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          picked.bytes!,
          filename: picked.name,
          contentType: MediaType.parse(mimeType),
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          picked.path!,
          contentType: MediaType.parse(mimeType),
        ));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subiendo archivo...')),
      );

      try {
        final response = await request.send();
        final res = await http.Response.fromStream(response);

        if (response.statusCode == 200) {
          final responseData = json.decode(res.body);
          final uploadedUrl = responseData['secure_url'];

          // ✅ GUARDAR EN FIRESTORE
          await FirebaseFirestore.instance
              .collection('clases')
              .doc(widget.claseId) // usa el classId pasado al widget
              .collection('contenidos')
              .add({
            'titulo': titleController.text,
            'descripcion': descriptionController.text,
            'link': uploadedUrl,
            'tipo': resourceType,
            'fecha': Timestamp.now(),
          });

          setState(() {
            linkArchivo = uploadedUrl;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archivo subido y guardado con éxito')),
          );
        } else {
          print(res.body);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al subir a Cloudinary')),
          );
        }
      } catch (e) {
        print('❌ Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: $e')),
        );
      }
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Agregar contenido', style: GoogleFonts.poppins()),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Título del contenido'),
                      onChanged: (value) => titulo = value.trim(),
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Descripción'),
                      onChanged: (value) => descripcion = value.trim(),
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Link o URL del archivo'),
                      onChanged: (value) => linkArchivo = value.trim(),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Subir archivo desde dispositivo'),
                      onPressed: () async {
                        setState(() => isUploading = true);
                        await _uploadFileFromDevice();
                        setState(() => isUploading = false);
                      },
                    ),
                    if (isUploading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text('Guardar'),
                  onPressed: () async {
                    if (titulo.isNotEmpty && descripcion.isNotEmpty && linkArchivo.isNotEmpty) {
                      final idContenido = FirebaseFirestore.instance.collection('tmp').doc().id;
                      final ref = FirebaseFirestore.instance.collection('clases').doc(widget.claseId);

                      final nuevoContenido = {
                        'titulo': titulo,
                        'descripcion': descripcion,
                        'archivo': linkArchivo,
                        'tipo': linkArchivo.endsWith('.mp4') ? 'video' : 'image',
                        'fecha': FieldValue.serverTimestamp(),
                      };

                      await ref.update({
                        'contenidos.$idContenido': nuevoContenido,
                      });

                      Navigator.pop(context);
                      await _loadContenidos();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contenido agregado')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        if (contenidosMap.isEmpty)
          _emptyState()
        else
          ListView(
            padding: const EdgeInsets.all(24),
            children: contenidosMap.entries.map((entry) {
              final contenido = entry.value;
              final tipo = contenido['tipo'] ?? '';
              final archivoUrl = contenido['archivo'] ?? contenido['link'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // 📸 Miniatura
                      if (tipo == 'image' && archivoUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            archivoUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, color: Colors.red),
                            ),
                          ),
                        )
                      else if (tipo == 'video')
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(child: Icon(Icons.videocam, color: Color(0xFFFB923C))),
                        )
                      else
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(child: Icon(Icons.insert_drive_file, color: Color(0xFF94A3B8))),
                        ),

                      const SizedBox(width: 12),

                      // 📝 Texto y acciones
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contenido['titulo'] ?? 'Sin título',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              contenido['descripcion'] ?? '',
                              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.link, size: 20, color: Color(0xFFFB923C)),
                                  onPressed: () {
                                    if (archivoUrl.isNotEmpty) {
                                      launchUrl(Uri.parse(archivoUrl));
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('¿Eliminar contenido?'),
                                        content: const Text('Esta acción no se puede deshacer.'),
                                        actions: [
                                          TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(ctx, false)),
                                          TextButton(child: const Text('Eliminar'), onPressed: () => Navigator.pop(ctx, true)),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      final docRef = FirebaseFirestore.instance.collection('clases').doc(widget.claseId);
                                      await docRef.update({'contenidos.${entry.key}': FieldValue.delete()});
                                      await _loadContenidos();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),


        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFFFB923C),
            onPressed: _showAgregarContenidoDialog,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book, size: 48, color: Color(0xFFFB923C)),
          const SizedBox(height: 12),
          Text(
            'No hay contenidos agregados',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class StudentsTab extends StatefulWidget {
  final String claseId;

  const StudentsTab({super.key, required this.claseId});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic> _estudiantes = {};
  List<MapEntry<String, dynamic>> _filteredEstudiantes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterEstudiantes);
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance.collection('clases').doc(widget.claseId).get();
    final data = doc.data() as Map<String, dynamic>?;

    if (data != null) {
      final estudiantes = data['estudiantes'] as Map<String, dynamic>? ?? {};
      setState(() {
        _estudiantes = estudiantes;
        _filteredEstudiantes = estudiantes.entries.toList();
      });
    }
  }

  void _filterEstudiantes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEstudiantes = _estudiantes.entries
          .where((e) => (e.value['nombre'] ?? '').toString().toLowerCase().contains(query))
          .toList();
    });
  }

  void _showAddStudentModal(BuildContext context) async {
    final estudiantesGlobales = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('role', isEqualTo: 'student')
        .get();

    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final filtrados = estudiantesGlobales.docs.where((doc) {
              final nombre = (doc['fullName'] ?? '').toString().toLowerCase();
              return nombre.contains(searchQuery);
            }).toList();

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Agregar estudiante al curso',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar estudiante...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Expanded(
                        child: ListView.builder(
                          itemCount: filtrados.length,
                          itemBuilder: (context, index) {
                            final estudiante = filtrados[index];
                            final uid = estudiante.id;
                            final nombre = estudiante['fullName'] ?? 'Sin nombre';
                            final yaInscrito = _estudiantes.containsKey(uid);

                            return ListTile(
                              title: Text(nombre, style: GoogleFonts.poppins()),
                              trailing: yaInscrito
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : IconButton(
                                icon: const Icon(Icons.person_add_alt_1),
                                  onPressed: () async {
                                    Timestamp _convertirFecha(dynamic fecha) {
                                      if (fecha is Timestamp) return fecha;
                                      if (fecha is int) return Timestamp.fromMillisecondsSinceEpoch(fecha);
                                      if (fecha is String) {
                                        try {
                                          final parsed = DateFormat('dd/MM/yyyy').parseStrict(fecha);
                                          return Timestamp.fromDate(parsed);
                                        } catch (_) {
                                          return Timestamp.now(); // fallback si falla el parseo
                                        }
                                      }
                                      return Timestamp.now();
                                    }
                                    try {
                                      final claseRef = FirebaseFirestore.instance.collection('clases').doc(widget.claseId);
                                      final claseSnapshot = await claseRef.get();
                                      final claseData = claseSnapshot.data() as Map<String, dynamic>;

                                      final evaluaciones = claseData['evaluaciones'] as Map<String, dynamic>? ?? {};
                                      final infoClases = claseData['infoClases'] as Map<String, dynamic>? ?? {};

                                      final evaluacionesEstudiante = {
                                        for (var entry in evaluaciones.entries)
                                          entry.key: {'nota': null, 'comentarios': ''}
                                      };

                                      final asistenciasClases = {
                                        for (var entry in infoClases.entries)
                                          entry.key: {
                                            'fecha': _convertirFecha(entry.value),
                                            'asistencia': false,
                                          }
                                      };

                                      final nuevo = {
                                        'nombre': estudiante['fullName'] ?? '',
                                        'correo': estudiante['email'] ?? '',
                                        'estado': 'inscrito',
                                        'asistencias': 0,
                                        'asistenciasClases': asistenciasClases,
                                        'inasistencias': 0,
                                        'notaFinal': 0,
                                        'evaluaciones': evaluacionesEstudiante,
                                        'acumulado': 0,
                                      };

                                      await claseRef.update({
                                        'estudiantes.$uid': nuevo,
                                      });

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('$nombre agregado al curso')),
                                        );
                                      }

                                      await _loadData();
                                    } catch (e) {
                                      print('❌ Error al agregar estudiante: $e');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Error al agregar estudiante')),
                                        );
                                      }
                                    }
                                  }
                              ),
                            );
                          },
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
    );
  }

  Future<void> _deleteEstudiante(String id) async {
    final ref = FirebaseFirestore.instance.collection('clases').doc(widget.claseId);
    await ref.update({'estudiantes.$id': FieldValue.delete()});
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: _estudiantes.isEmpty
            ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_add,
                  size: 48,
                  color: Color(0xFFFB923C),
                ),
                const SizedBox(height: 12),
                Text(
                  'No hay estudiantes inscritos',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddStudentModal(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar estudiante'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFB923C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lista completa de los estudiantes del curso',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Buscar estudiante...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFFFB923C)),
                  onPressed: () => _showAddStudentModal(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Total: ${_filteredEstudiantes.length} estudiante${_filteredEstudiantes.length == 1 ? '' : 's'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredEstudiantes.length,
                itemBuilder: (context, index) {
                  final entry = _filteredEstudiantes[index];
                  final id = entry.key;
                  final estudiante = entry.value;
                  final nombre = estudiante['nombre'] ?? 'Estudiante';
                  final acumulado = estudiante['acumulado'];
                  final avatarColor = estudiante['color'] ?? Colors.greenAccent;

                  return GestureDetector( // ← 🔸 Envoltura añadida aquí
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManageStudentPage(
                            claseId: widget.claseId,
                            studentId: id,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: _parseColor(avatarColor),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nombre,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ver detalles',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                acumulado != null ? "$acumulado%" : 'Pendiente',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: acumulado != null
                                      ? (acumulado >= 90
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFFB923C))
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                                onPressed: () => _deleteEstudiante(id),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(dynamic value) {
    if (value is int) return Color(value);
    if (value is String && value.startsWith('#')) {
      return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
    }
    return Colors.grey;
  }
}
