import 'package:flutter/material.dart';

class Flowgram extends StatelessWidget {
  final String carreraId; // Ejemplo: "ingenieria_software"

  const Flowgram({super.key, required this.carreraId}); //Revisar atributo de la carrera

  static const Map<String, List<Map<String, dynamic>>> _materiasPorCarrera = {
    'Ingeniería de Software': [
      {'nombre': 'Cálculo I', 'semestre': 1},
      {'nombre': 'Programación Básica', 'semestre': 1},
      {'nombre': 'Física I', 'semestre': 2, 'prerrequisito': 'Cálculo I'},
      // ... más materias
    ],
    'Medicina': [
      {'nombre': 'Anatomía', 'semestre': 1},
      {'nombre': 'Biología Celular', 'semestre': 1},
      // ... más materias
    ],
  };

  @override
  Widget build(BuildContext context) {
    final materias = _materiasPorCarrera[carreraId] ?? [];

    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco obligatorio
      appBar: AppBar(
        title: Text('Flujograma - $carreraId'),
        backgroundColor: Colors.orange,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: 1000, // Asegura que haya espacio para el Stack
            child: Stack(
              children: [
                const Positioned(
                  left: 20,
                  top: 40,
                  child: Text(
                    'Flujo de Materias',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Positioned(
                  left: 20,
                  top: 90,
                  child: Text(
                    'Visualiza y gestiona tu progreso académico de manera intuitiva',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                  ),
                ),


                // Materias principales
                ...materias.map((materia) {
                  return Positioned(
                    left: materia['left'],
                    top: materia['top'],
                    child: materia['prerrequisito'] == null
                        ? materiaBox(materia['nombre'])
                        : prereqBox(
                      materia['nombre'],
                      'Prerrequisito: ${materia['prerrequisito']}',
                    ),
                  );
                }).toList(),


              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget materiaBox(String nombre) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        nombre,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 16,
        ),
      ),
    );
  }

  static Widget prereqBox(String nombre, String prerrequisitos) {
    return Opacity(
      opacity: 0.5,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nombre,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              prerrequisitos,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}