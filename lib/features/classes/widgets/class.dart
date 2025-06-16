import 'package:flutter/material.dart';

class Class extends StatelessWidget {
  final Map<String, dynamic> clase;

  const Class({super.key, required this.clase});

  @override
  Widget build(BuildContext context) {
    final horario = clase['horario'] as Map<String, dynamic>?;
    final dias = (horario?['dias'] as List<dynamic>?)?.join(', ') ?? '';
    final hora = horario?['horaInicio'] ?? '';
    final nombre = clase['nombreMateria'] ?? '';
    final profesor = clase['profesorNombre'] ?? '';
    final aula = clase['aula'] ?? '';
    final promedio = (clase['estudiantes']?['notaFinal'] ?? '0').toString();
    final creditos = clase['creditos']?.toString() ?? '4';

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Volver a Mis Asignaturas',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            )),
                        const SizedBox(height: 6),
                        Text('Prof. $profesor - Aula $aula',
                            style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _pill(hora, const Color(0xFFF97316), Colors.white),
                            const SizedBox(width: 8),
                            _pill(dias, const Color(0xFFE2E8F0), Colors.black),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _infoBox('Evaluaciones', '4'),
                            const SizedBox(width: 10),
                            _infoBox('Calificadas', '3'),
                            const SizedBox(width: 10),
                            _infoBox('Pendientes', '1'),
                            const SizedBox(width: 10),
                            _infoBox('Créditos', creditos),
                          ],
                        )
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '$promedio%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF97316),
                        ),
                      ),
                      const Text('Promedio General',
                          style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  )
                ],
              ),
            ),
            const TabBar(
              labelColor: Color(0xFFF97316),
              unselectedLabelColor: Colors.black45,
              indicatorColor: Color(0xFFF97316),
              tabs: [
                Tab(text: 'Evaluaciones'),
                Tab(text: 'Tareas'),
                Tab(text: 'Horarios'),
                Tab(text: 'Recursos'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _evaluacionesTab(),
                  const Center(child: Text('Tareas (en desarrollo)')),
                  const Center(child: Text('Horario completo')),
                  const Center(child: Text('Recursos disponibles')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _infoBox(String label, String value) {
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

  Widget _evaluacionesTab() {
    final items = [
      {
        'titulo': 'Examen Parcial 1',
        'tipo': 'Examen',
        'fecha': '2024-03-15',
        'peso': '30%',
        'estado': 'Calificada',
        'nota': '88%',
        'color': Colors.orange,
      },
      {
        'titulo': 'Tarea 1: Límites',
        'tipo': 'Tarea',
        'fecha': '2024-03-08',
        'peso': '15%',
        'estado': 'Calificada',
        'nota': '95%',
        'color': Colors.green,
      },
      {
        'titulo': 'Quiz 1: Derivadas',
        'tipo': 'Quiz',
        'fecha': '2024-03-22',
        'peso': '10%',
        'estado': 'Calificada',
        'nota': '82%',
        'color': Colors.orange,
      },
      {
        'titulo': 'Proyecto Final',
        'tipo': 'Proyecto',
        'fecha': '2024-04-15',
        'peso': '45%',
        'estado': 'Pendiente',
        'nota': '',
        'color': Colors.grey,
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Evaluaciones',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Historial completo de evaluaciones y calificaciones',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 20),
        ...items.map((e) => _evalCard(e)).toList(),
      ],
    );
  }

  Widget _evalCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                data['titulo'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  data['tipo'],
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Fecha: ${data['fecha']}   Peso: ${data['peso']}',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: data['estado'] == 'Pendiente'
                      ? const Color(0xFFFFEDD5)
                      : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  data['estado'],
                  style: TextStyle(
                    color: data['estado'] == 'Pendiente'
                        ? Colors.orange
                        : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                data['nota'].isEmpty ? 'Pendiente' : data['nota'],
                style: TextStyle(
                  fontSize: 16,
                  color: data['color'],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Ver detalles',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: data['estado'] == 'Pendiente'
                      ? Colors.orange
                      : const Color(0xFF6366F1),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}