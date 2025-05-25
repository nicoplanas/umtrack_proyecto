import 'package:flutter/material.dart';

class Flowgram extends StatelessWidget {
  const Flowgram({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Positioned(
                  left: 20,
                  top: 150,
                  child: materiaBox('Cálculo I'),
                ),
                Positioned(
                  left: 20,
                  top: 230,
                  child: materiaBox('Física I'),
                ),
                Positioned(
                  left: 20,
                  top: 310,
                  child: materiaBox('Álgebra Lineal'),
                ),
                // Materias con prerrequisitos
                Positioned(
                  left: 200,
                  top: 190,
                  child: prereqBox('Cálculo II', 'Prerrequisito: Cálculo I'),
                ),
                Positioned(
                  left: 200,
                  top: 270,
                  child: prereqBox('Física II', 'Prerrequisito: Física I'),
                ),
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