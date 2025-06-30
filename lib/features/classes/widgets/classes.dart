import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:umtrack/features/classes/widgets/class.dart';

class Classes extends StatefulWidget {
  const Classes({super.key});

  @override
  State<Classes> createState() => _ClassesState();
}

class _ClassesState extends State<Classes> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late Future<List<Map<String, dynamic>>> _clasesDelUsuario;

  @override
  void initState() {
    super.initState();
    _clasesDelUsuario = _cargarClasesDelUsuario();
  }

  Future<List<Map<String, dynamic>>> _cargarClasesDelUsuario() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final querySnapshot = await _firestore.collection('clases').get();

    final clasesUsuario = querySnapshot.docs.where((doc) {
      final data = doc.data();
      final estudiantes = data['estudiantes'] as Map<String, dynamic>?;

      return data['estado'] == 'activa' &&
          estudiantes != null &&
          estudiantes.containsKey(user.uid);
    }).map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    return clasesUsuario;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _clasesDelUsuario,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final clases = snapshot.data ?? [];

        if (clases.isEmpty) {
          return const Center(child: Text('No estás inscrito en ninguna clase activa.'));
        }

        return Container(
          color: Colors.white,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: clases.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  color: const Color(0xFFF8FAFC),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Mis Asignaturas',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Selecciona una materia para ver tus evaluaciones y calificaciones',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final clase = clases[index - 1];
              final horario = clase['horario'] as Map<String, dynamic>?;

              final horaInicio = horario?['horaInicio'] ?? '';
              final dias = (horario?['dias'] as List<dynamic>?)?.join(', ') ?? '';
              final aula = clase['aula'] ?? '';
              final promedio = (clase['estudiantes'][_auth.currentUser!.uid]['notaFinal'] ?? 0).toString();

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(20, 0, 0, 0),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                  border: Border(
                    left: BorderSide(
                      color: Color(0xFFFD8305),
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Cabecera: Nombre + promedio
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          clase['nombreMateria'] ?? 'Materia',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$promedio%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: (double.tryParse(promedio) ?? 0) >= 90
                                    ? Colors.green
                                    : (double.tryParse(promedio) ?? 0) >= 85
                                    ? Colors.orange
                                    : Colors.redAccent,
                              ),
                            ),
                            const Text(
                              'Promedio',
                              style: TextStyle(fontSize: 12, color: Colors.black45),
                            )
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    /// Profesor y aula
                    Text(
                      'Prof. ${clase['profesorNombre']} - Aula $aula',
                      style: const TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 4),

                    const SizedBox(height: 12),
                    Text(
                      'Horario',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getColorByHour(horaInicio),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            horaInicio,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dias,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    /// Evaluaciones y calificadas
                    Row(
                      children: [
                        _infoBox(label: 'Evaluaciones', value: '4'), // placeholder
                        const SizedBox(width: 12),
                        _infoBox(label: 'Calificadas', value: '3'), // placeholder
                      ],
                    ),

                    const SizedBox(height: 8),
                    const Divider(height: 24),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Class(clase: clase),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Ver detalles',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFFD8305),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Color(0xFFFD8305),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _infoBox({required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorByHour(String hour) {
    if (hour.contains('8:00') || hour.contains('10:00')) return Colors.orange;
    if (hour.contains('2:00') || hour.contains('14:00')) return Colors.green;
    if (hour.contains('4:00') || hour.contains('16:00')) return Colors.deepPurpleAccent;
    return Colors.blueGrey;
  }
}