import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../student/views/manage_student_page.dart';
import '../widgets/manage_evaluations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:math';

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
                ReportesTab(claseId: claseId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReportesTab extends StatefulWidget {
  final String claseId;
  const ReportesTab({Key? key, required this.claseId}) : super(key: key);

  @override
  State<ReportesTab> createState() => _ReportesTabState();
}

class _ReportesTabState extends State<ReportesTab> {
  bool isLoading = true;
  Map<String, dynamic> evaluacionesMap = {};
  Map<String, dynamic> estudiantesMap = {};
  Map<String, ReporteEval> reportes = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection('clases')
        .doc(widget.claseId)
        .get();
    final data = doc.data() as Map<String, dynamic>? ?? {};

    evaluacionesMap = Map.from(data['evaluaciones'] ?? {});
    estudiantesMap = Map.from(data['estudiantes'] ?? {});
    _computeReportes();

    setState(() => isLoading = false);
  }

  void _computeReportes() {
    reportes.clear();
    evaluacionesMap.forEach((evalId, evalData) {
      final titulo = (evalData is Map && evalData['nombre'] != null)
          ? evalData['nombre']
          : evalId;

      final List<double> notas = [];
      estudiantesMap.forEach((_, stuData) {
        final evals = (stuData['evaluaciones'] ?? {}) as Map<String, dynamic>;
        final nota = evals[evalId]?['nota'];
        if (nota is num) notas.add(nota.toDouble());
      });

      double mode = 0;
      int maxCount = 0;
      final freq = <double,int>{};
      for (var n in notas) freq[n] = (freq[n] ?? 0) + 1;
      freq.forEach((score, count) {
        if (count > maxCount) {
          maxCount = count;
          mode = score;
        }
      });

      if (notas.isEmpty) {
        reportes[evalId] = ReporteEval(
          titulo: titulo,
          max: 0, min: 0, avg: 0, median: 0,
          desv: 0, count: 0, mode: 0,
        );
      } else {
        notas.sort();
        final n = notas.length;
        final sum = notas.reduce((a, b) => a + b);
        final avg = sum / n;
        final min = notas.first, max = notas.last;
        final median = (n % 2 == 1)
            ? notas[n ~/ 2]
            : (notas[n ~/ 2 - 1] + notas[n ~/ 2]) / 2;
        final variance = notas.fold<double>(0, (v, e) => v + pow(e - avg, 2)) / n;
        final desv = sqrt(variance);

        reportes[evalId] = ReporteEval(
          titulo: titulo,
          max: max, min: min, avg: avg, median: median,
          desv: desv, count: n, mode: mode,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (reportes.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos de evaluaciones',
          style: TextStyle(color: Colors.black),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      children: reportes.entries.map((entry) {
        final r = entry.value;
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre de la evaluación en lugar del ID
                Text(
                  r.titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),

                // Estadísticas en negro
                Text(
                  'Cantidad de notas: ${r.count}',
                  style: GoogleFonts.poppins(color: Colors.black),
                ),
                Text(
                  'Mayor: ${r.max.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(color: Colors.black),
                ),
                Text(
                  'Menor: ${r.min.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(color: Colors.black),
                ),
                Text(
                  'Promedio: ${r.avg.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(color: Colors.black),
                ),
                Text(
                  'Mediana: ${r.median.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(color: Colors.black),
                ),
                Text(
                  'Moda: ${r.mode.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(color: Colors.black),
                ),
                Text(
                  'Desv. estándar: ${r.desv.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(color: Colors.black),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Modelo de reporte
class ReporteEval {
  final String titulo;
  final double max, min, avg, median, desv, mode;
  final int count;

  ReporteEval({
    required this.titulo,
    required this.max,
    required this.min,
    required this.avg,
    required this.median,
    required this.desv,
    required this.count,
    required this.mode,
  });
}

class ContenidosTab extends StatefulWidget {
  final String claseId;
  const ContenidosTab({Key? key, required this.claseId}) : super(key: key);

  @override
  State<ContenidosTab> createState() => _ContenidosTabState();
}

class _ContenidosTabState extends State<ContenidosTab> {
  late CollectionReference contenidosRef;
  List<DocumentSnapshot> contenidos = [];
  List<DocumentSnapshot> _filteredContenidos = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, TextEditingController> _replyControllers = {};

  @override
  void initState() {
    super.initState();
    contenidosRef = FirebaseFirestore.instance
        .collection('clases')
        .doc(widget.claseId)
        .collection('contenidos');
    _searchController.addListener(_filterContenidos);
    _loadContenidos();
  }

  Future<void> _loadContenidos() async {
    setState(() => isLoading = true);
    final snapshot =
    await contenidosRef.orderBy('fecha', descending: true).get();
    setState(() {
      contenidos = snapshot.docs;
      _filteredContenidos = List.from(contenidos);
      for (var doc in contenidos) {
        _commentControllers.putIfAbsent(
            doc.id, () => TextEditingController());
      }
      isLoading = false;
    });
  }

  void _filterContenidos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContenidos = contenidos.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final title = (data['titulo'] ?? '').toString().toLowerCase();
        final desc = (data['descripcion'] ?? '').toString().toLowerCase();
        return title.contains(query) || desc.contains(query);
      }).toList();
    });
  }

  Future<void> _deleteContenido(String id) async {
    await contenidosRef.doc(id).delete();
    await _loadContenidos();
  }

  Future<void> _postComment(String contenidoId) async {
    final controller = _commentControllers[contenidoId]!;
    final text = controller.text.trim();
    if (text.isEmpty) return;

    // Obtener información del usuario actual
    final user = FirebaseAuth.instance.currentUser;
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user?.uid)
        .get();

    final comentariosRef = contenidosRef.doc(contenidoId).collection('comentarios');
    await comentariosRef.add({
      'texto': text,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': user?.uid,
      'userName': userDoc.data()?['fullName'] ?? 'Usuario',
    });
    controller.clear();
  }

  //  _buildCommentItem ahora recibe el ID del contenido
  Widget _buildCommentItem(String contenidoId, QueryDocumentSnapshot c) {
    bool mostrarRespuestas = false;
    final d = c.data() as Map<String, dynamic>;
    final ts = d['timestamp'] as Timestamp?;
    final time = ts != null
        ? DateFormat('dd MMM', 'es').format(ts.toDate())
        : '';
    final user = d['userName'] ?? 'Usuario';
    final comentarioId = c.id;

    //  Controlador para esta respuesta
    final replyCtrl = _replyControllers.putIfAbsent(
        comentarioId, () => TextEditingController());

    //  Referencia a las respuestas
    final respuestasRef = contenidosRef
        .doc(contenidoId)
        .collection('comentarios')
        .doc(comentarioId)
        .collection('respuestas');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Comentario principal ---
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.orange[100],
                child: Text(user[0].toUpperCase(),
                    style: const TextStyle(color: Colors.orange)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(time,
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(d['texto'] ?? '', style: GoogleFonts.poppins(fontSize: 14)),

          // --- Lista de respuestas ---
          StreamBuilder<QuerySnapshot>(
            stream: respuestasRef.orderBy('timestamp').snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: snap.data!.docs.map((r) {
                    final rd = r.data() as Map<String, dynamic>;
                    final rTime = rd['timestamp'] != null
                        ? DateFormat('dd MMM', 'es')
                        .format((rd['timestamp'] as Timestamp).toDate())
                        : '';
                    final rUser = rd['userName'] ?? 'Usuario';
                    return Padding(
                      padding: const EdgeInsets.only(left: 32, bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.reply, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$rUser  •  $rTime',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: const Color(0xFF94A3B8))),
                                const SizedBox(height: 2),
                                Text(rd['texto'] ?? '',
                                    style: GoogleFonts.poppins(fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          // --- Input para nueva respuesta ---
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 28),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: replyCtrl,
                    decoration: InputDecoration(
                      hintText: 'Responder...',
                      hintStyle: const TextStyle(fontSize: 13),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      border: const OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, size: 20, color: Color(0xFFFB923C)),
                  onPressed: () => _postRespuesta(contenidoId, comentarioId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarTodosLosComentarios(BuildContext context,
      String contenidoId, List<QueryDocumentSnapshot> docs)
  {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 600,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Comentarios',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) => _buildCommentItem(contenidoId, docs[i]),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFB923C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAgregarContenidoDialog() {
    String titulo = '';
    String descripcion = '';
    String linkArchivo = '';
    bool isUploading = false;

    Future<void> _uploadFile() async {
      try {
        final result = await FilePicker.platform.pickFiles(
          allowMultiple: false,
          withData: true,
        );

        if (result == null || result.files.isEmpty) return;

        final picked = result.files.first;
        final mimeType = lookupMimeType(picked.name);
        if (mimeType == null) return;

        String resourceType = mimeType.startsWith('video/')
            ? 'video'
            : mimeType.startsWith('image/')
            ? 'image'
            : 'raw';

        final uploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/doyt5r47e/$resourceType/upload');
        final request = http.MultipartRequest('POST', uploadUrl)
          ..fields['upload_preset'] = 'UMTrack';

        if (kIsWeb || picked.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            picked.bytes!,
            filename: picked.name,
            contentType: MediaType.parse(mimeType),
          ),);
              } else {
              request.files.add(await http.MultipartFile.fromPath(
              'file',
              picked.path!,
              contentType: MediaType.parse(mimeType),
              ),);
              }

              final response = await request.send();
          final res = await http.Response.fromStream(response);

          if (response.statusCode == 200) {
            final data = json.decode(res.body);
            setState(() {
              linkArchivo = data['secure_url'];
            });
          } else {
            throw Exception('Failed to upload file: ${res.statusCode}');
          }
        } catch (e) {
        print('Error uploading file: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir archivo: $e')),
        );
      }
    }


    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Agregar contenido', style: GoogleFonts.poppins()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Título'),
                onChanged: (v) => titulo = v.trim(),
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Descripción'),
                onChanged: (v) => descripcion = v.trim(),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Subir archivo'),
                onPressed: () async {
                  setState(() => isUploading = true);
                  await _uploadFile();
                  setState(() => isUploading = false);
                },
              ),
              if (isUploading) const CircularProgressIndicator(),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (titulo.isEmpty ||
                    descripcion.isEmpty ||
                    linkArchivo.isEmpty) return;
                final tipo =
                linkArchivo.endsWith('.mp4') ? 'video' : 'image';
                await contenidosRef.add({
                  'titulo': titulo,
                  'descripcion': descripcion,
                  'link': linkArchivo,
                  'tipo': tipo,
                  'fecha': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                await _loadContenidos();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _postRespuesta(
      String contenidoId, String comentarioId) async {
    final controller = _replyControllers[comentarioId]!;
    final texto = controller.text.trim();
    if (texto.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user?.uid)
        .get();

    await contenidosRef
        .doc(contenidoId)
        .collection('comentarios')
        .doc(comentarioId)
        .collection('respuestas')
        .add({
      'texto': texto,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': user?.uid,
      'userName': userDoc.data()?['fullName'] ?? 'Usuario',
    });

    controller.clear();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

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
        child: Column(
          children: [
            // Barra de búsqueda + botón de crear
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar contenido...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showAgregarContenidoDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFB923C),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Si no hay contenidos: estado vacío + botón ya incluido arriba
            if (_filteredContenidos.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book,
                          size: 48, color: Color(0xFFFB923C)),
                      const SizedBox(height: 12),
                      Text('No hay contenidos',
                          style: GoogleFonts.poppins(fontSize: 16)),
                    ],
                  ),
                ),
              )
            else
            // Lista filtrada de contenidos
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredContenidos.length,
                  itemBuilder: (ctx, i) {
                    final doc = _filteredContenidos[i];
                    final contenidoId = doc.id;
                    final data = doc.data() as Map<String, dynamic>;
                    final tipo = data['tipo'] ?? '';
                    final url = data['link'] ?? '';
                    final commentController =
                    _commentControllers[doc.id]!;
                    final comentariosRef = contenidosRef
                        .doc(doc.id)
                        .collection('comentarios');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Contenido principal
                            Row(
                              children: [
                                if (tipo == 'image')
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      url,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image,
                                            color: Colors.red),
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
                                    child: const Center(
                                        child: Icon(Icons.videocam,
                                            color: Color(0xFFFB923C))),
                                  )
                                else
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                        child: Icon(Icons.insert_drive_file,
                                            color: Color(0xFF94A3B8))),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data['titulo'] ?? '',
                                          style: GoogleFonts.poppins(
                                              fontWeight:
                                              FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(data['descripcion'] ?? '',
                                          style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      size: 20, color: Color(0xFFEF4444)),
                                  onPressed: () => _deleteContenido(doc.id),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            // Input de nuevo comentario
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: commentController,
                                    decoration: const InputDecoration(
                                      hintText: 'Añadir un comentario',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 12),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send,
                                      color: Color(0xFFFB923C)),
                                  onPressed: () => _postComment(doc.id),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            // Lista de comentarios
                            // Sustituye TODO el StreamBuilder original por este:
                            StreamBuilder<QuerySnapshot>(
                              stream: comentariosRef.orderBy('timestamp').snapshots(),
                              builder: (ctx, snap) {
                                if (snap.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(
                                    height: 50,
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }

                                final docs = snap.data?.docs ?? [];

                                // ---- Sin comentarios todavía ----
                                if (docs.isEmpty) {
                                  return Text(
                                    'Sé el primero en comentar',
                                    style: GoogleFonts.poppins(fontStyle: FontStyle.italic),
                                  );
                                }

                                // ---- Al menos 1 comentario ----
                                final primer = docs.first;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildCommentItem(contenidoId, primer),          // ⬅️ Primer comentario
                                    if (docs.length > 1)                // ⬅️ Botón para verlos todos
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton.icon(
                                          icon: const Icon(Icons.chat_rounded, size: 18),
                                          label: Text('Ver todos los comentarios (${docs.length})',
                                              style: GoogleFonts.poppins()),
                                          onPressed: () =>
                                              _mostrarTodosLosComentarios(context, contenidoId, docs),
                                        ),
                                      ),
                                  ],
                                );
                              },
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
      _filteredEstudiantes = estudiantes.entries.toList()
        ..sort((a, b) => a.value['nombre']
            .toString()
            .toLowerCase()
            .compareTo(b.value['nombre'].toString().toLowerCase()));
      setState(() {
        _estudiantes = estudiantes;
      });
    }
  }

  void _filterEstudiantes() {
    final query = _searchController.text.toLowerCase();
    _filteredEstudiantes = _estudiantes.entries
        .where((e) => (e.value['nombre'] ?? '')
        .toString()
        .toLowerCase()
        .contains(query))
        .toList()
      ..sort((a, b) => a.value['nombre']
          .toString()
          .toLowerCase()
          .compareTo(b.value['nombre'].toString().toLowerCase()));
    setState(() {});
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
                  final evalMap = (estudiante['evaluaciones'] ?? {}) as Map<String, dynamic>;
                  final totalAcumulado = evalMap.values
                      .map((e) => (e['puntosObtenidos'] as num? ?? 0).toDouble())
                      .fold<double>(0, (a, b) => a + b);
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
                              totalAcumulado > 0
                                  ? RichText(
                                text: TextSpan(
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'ptos: ',
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                    TextSpan(
                                      text: '${totalAcumulado.toStringAsFixed(2)}/20',
                                      style: const TextStyle(color: Color(0xFFFB923C)),
                                    ),
                                  ],
                                ),
                              )
                                  : Text(
                                'Pendiente',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.highlight_remove, color: Color(0xFFEF4444)),
                                iconSize: 25,
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
