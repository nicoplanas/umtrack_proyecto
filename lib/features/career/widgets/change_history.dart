import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangeHistory extends StatefulWidget {
  final String carreraId;

  const ChangeHistory({super.key, required this.carreraId});

  @override
  State<ChangeHistory> createState() => _ChangeHistoryState();
}

class _ChangeHistoryState extends State<ChangeHistory> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _tipoFiltro = 'todos';
  List<Map<String, dynamic>> _todosLosCambios = [];
  bool _loading = true;
  String? _fechaFormatoCorto;

  @override
  void initState() {
    super.initState();
    _cargarCambios();
  }

  Future<void> _cargarCambios() async {
    final firestore = FirebaseFirestore.instance;

    final carreraSnapshot = await firestore.collection('carreras').doc(widget.carreraId).get();
    if (!carreraSnapshot.exists) return;

    final carreraData = carreraSnapshot.data() as Map<String, dynamic>;
    final flujogramaId = carreraData['flujograma'];

    if (flujogramaId == null || flujogramaId.isEmpty) return;

    final snapshot = await firestore
        .collection('flujogramas')
        .doc(flujogramaId)
        .collection('historial_cambios')
        .orderBy('fecha', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;

    final doc = snapshot.docs.first;
    final data = doc.data() as Map<String, dynamic>;
    final Timestamp fecha = data['fecha'];
    _fechaFormatoCorto = DateFormat('dd/MM/yy').format(fecha.toDate());

    final nuevas = List<Map<String, dynamic>>.from(data['asignaturas_incorporadas'] ?? []);
    final removidas = List<Map<String, dynamic>>.from(data['asignaturas_sustituidas'] ?? []);
    final prelaciones = List<Map<String, dynamic>>.from(data['cambios_prelaciones'] ?? []);

    _todosLosCambios = [
      ...nuevas.map((e) => {...e, 'tipo': 'nueva'}),
      ...removidas.map((e) => {...e, 'tipo': 'removida'}),
      ...prelaciones.map((e) => {...e, 'tipo': 'prelacion'}),
    ];

    setState(() {
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _cambiosFiltrados {
    return _todosLosCambios.where((cambio) {
      final nombre = (cambio['nombre'] ?? '').toString().toLowerCase();
      final coincideTexto = nombre.contains(_searchQuery.toLowerCase());
      final coincideTipo = _tipoFiltro == 'todos' || cambio['tipo'] == _tipoFiltro;
      return coincideTexto && coincideTipo;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial de Cambios – $_fechaFormatoCorto',
            style: GoogleFonts.poppins(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            'Seguimiento detallado de todas las modificaciones en el pensum académico',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          Center(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildResumenBox('Total de Cambios', _todosLosCambios.length, Color(0xFF031130)),
                _buildResumenBox('Materias Nuevas', _todosLosCambios.where((e) => e['tipo'] == 'nueva').length, Color(0xFF10B981)),
                _buildResumenBox('Prerrequisitos', _todosLosCambios.where((e) => e['tipo'] == 'prelacion').length, Colors.orange),
                _buildResumenBox('Removidas', _todosLosCambios.where((e) => e['tipo'] == 'removida').length, Colors.red),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtros de Búsqueda',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value),
                        style: GoogleFonts.poppins(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Buscar por materia...',
                          hintStyle: GoogleFonts.poppins(color: Colors.black45),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          filled: true,
                          fillColor: Colors.grey.shade300,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        value: _tipoFiltro,
                        onChanged: (value) => setState(() => _tipoFiltro = value!),
                        style: GoogleFonts.poppins(color: Colors.black87),
                        icon: const Icon(Icons.arrow_drop_down),
                        items: const [
                          DropdownMenuItem(value: 'todos', child: Text('Todos')),
                          DropdownMenuItem(value: 'nueva', child: Text('Nuevas')),
                          DropdownMenuItem(value: 'removida', child: Text('Removidas')),
                          DropdownMenuItem(value: 'prelacion', child: Text('Prerrequisitos')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${_cambiosFiltrados.length} cambios encontrados',
                  style: GoogleFonts.poppins(fontSize: 14, color: Color(0xFFFD8305)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (var cambio in _cambiosFiltrados) _buildCambioCard(cambio),
        ],
      ),
    );
  }

  Widget _buildResumenBox(String label, int count, Color color) {
    return Container(
      width: 300,
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildCambioCard(Map<String, dynamic> cambio) {
    final tipo = cambio['tipo'];
    final codigo = cambio['codigo'] ?? '';
    final nombre = cambio['nombre'] ?? '';
    final sustituye = cambio['sustituye'];
    final nuevaPrelacion = cambio['nueva_prelacion'] as List<dynamic>?;

    IconData icon;
    Color color;
    String titulo;
    String subtitulo = '';
    List<Widget> chips = [];

    switch (tipo) {
      case 'nueva':
        icon = Icons.add_circle;
        color = Color(0xFF10B981);
        titulo = nombre;
        if (sustituye != null && sustituye is Map && sustituye['nombre'] != null) {
          subtitulo = 'Sustituye a: ${sustituye['nombre']}';
        }
        chips.add(_chip('Nueva Materia', color));
        chips.add(_chip('Alto Impacto', Colors.red));
        break;
      case 'removida':
        icon = Icons.remove_circle;
        color = Colors.red;
        titulo = nombre;
        subtitulo = 'Materia eliminada del pensum';
        chips.add(_chip('Materia Removida', color));
        chips.add(_chip('Alto Impacto', Colors.red));
        break;
      case 'prelacion':
        icon = Icons.compare_arrows;
        color = Colors.orange;
        titulo = nombre;
        subtitulo = 'Actualización de prerrequisitos';
        chips.add(_chip('Prerrequisito Modificado', color));
        if (nuevaPrelacion != null) {
          chips.addAll(nuevaPrelacion.map((e) => _chip(e.toString(), Colors.blue)));
        }
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
        titulo = nombre;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$titulo ($codigo)',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                if (subtitulo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: chips),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}
