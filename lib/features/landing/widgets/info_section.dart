import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/views/sign_up_page.dart';
import '../../../features/Information/views/information_page.dart';

class InfoSection extends StatelessWidget {
  const InfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hero Section
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 60),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text & Buttons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu vida universitaria más fácil que nunca',
                      style: GoogleFonts.poppins(
                        fontSize: 65,
                        fontWeight: FontWeight.w700, // w700 = bold
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Gestiona tu progreso académico, planifica tus inscripciones y reserva espacios universitarios, todo desde una sola aplicación.',
                      style: TextStyle(
                        color: const Color(0xFF64748B),
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignUpPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFD8305),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Comenzar Ahora',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 20),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const InformationPage()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFD8305)),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Más Información',
                            style: TextStyle(color: Color(0xFFFD8305), fontFamily: 'Poppins', fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/student_reading.png',
                  height: 325,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),

        // Características
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 60),
          child: Column(
            children: [
              Text(
                'Características Principales',
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w700, // w700 = bold
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 55),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/unimet.png',
                      height: 325,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 40),
                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Visualiza tu Progreso',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 36,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Mantén un seguimiento detallado de tu avance académico con gráficos intuitivos y reportes personalizados.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 18,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 30),
                        ...[
                          'Visualización de materias aprobadas y pendientes',
                          'Cálculo automático de índice académico',
                          'Proyección de fecha de graduación',
                        ].map((text) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFFFD8305), size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // CTA naranja
        Container(
          width: double.infinity, // <- Asegura que use todo el ancho de pantalla
          color: const Color(0xFFFD8305),
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '¿Listo para comenzar?',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold, // w700 = bold
                  color: const Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Únete a miles de estudiantes que ya están aprovechando todas las funcionalidades de la app',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(229),
                  fontSize: 18,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    color: const Color(0xFFFD8305),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}