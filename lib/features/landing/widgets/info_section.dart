import 'package:flutter/material.dart';

class InfoSection extends StatelessWidget {
  const InfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 1926,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: -94,
                child: Container(
                  height: 2020,
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC)),
                ),
              ),
              Positioned(
                left: 60,
                top: 73,
                child: SizedBox(
                  width: 605,
                  child: Text(
                    'Tu vida universitaria más fácil que nunca',
                    style: TextStyle(
                      color: const Color(0xFF1E293B),
                      fontSize: 48,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      height: 1.20,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 60,
                top: 215,
                child: SizedBox(
                  width: 541,
                  child: Text(
                    'Gestiona tu progreso académico, planifica tus inscripciones y reserva espacios universitarios, todo desde una sola aplicación.',
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      height: 1.50,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 60,
                top: 326,
                child: Container(
                  width: 200,
                  height: 60,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFFD8305),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              Positioned(
                left: 92,
                top: 344,
                child: Text(
                  'Comenzar Ahora',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 275,
                top: 326,
                child: Container(
                  width: 145,
                  height: 60,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: const Color(0xFFFD8305),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 308,
                top: 344,
                child: Text(
                  'Ver Demo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFFD8305),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 558,
                child: Container(
                  width: 1272,
                  height: 182,
                  decoration: BoxDecoration(color: Colors.white),
                ),
              ),
              Positioned(
                left: 396,
                top: 622,
                child: Text(
                  'Características Principales',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: 36,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 60,
                top: 804,
                child: Container(
                  width: 552,
                  height: 368,
                  decoration: ShapeDecoration(
                    image: DecorationImage(
                      image: NetworkImage("https://placehold.co/552x368"),
                      fit: BoxFit.contain,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x00000000),
                        blurRadius: 0,
                        offset: Offset(0, 0),
                        spreadRadius: 0,
                      ),BoxShadow(
                        color: Color(0x00000000),
                        blurRadius: 0,
                        offset: Offset(0, 0),
                        spreadRadius: 0,
                      ),BoxShadow(
                        color: Color(0x00000000),
                        blurRadius: 0,
                        offset: Offset(0, 0),
                        spreadRadius: 0,
                      ),BoxShadow(
                        color: Color(0x00000000),
                        blurRadius: 0,
                        offset: Offset(0, 0),
                        spreadRadius: 0,
                      ),BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 6,
                        offset: Offset(0, 4),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 660,
                top: 804,
                child: Text(
                  'Visualiza tu Progreso',
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: 36,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 660,
                top: 876,
                child: SizedBox(
                  width: 538,
                  child: Text(
                    'Mantén un seguimiento detallado de tu avance académico con gráficos intuitivos y reportes personalizados.',
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      height: 1.50,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 660,
                top: 952,
                child: Container(
                  width: 24,
                  height: 24,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(),
                ),
              ),
              Positioned(
                left: 696,
                top: 952,
                child: Text(
                  'Visualización de materias aprobadas y pendientes',
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 660,
                top: 992,
                child: Container(
                  width: 24,
                  height: 24,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(),
                ),
              ),
              Positioned(
                left: 696,
                top: 992,
                child: Text(
                  'Cálculo automático de índice académico',
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 660,
                top: 1032,
                child: Container(
                  width: 24,
                  height: 24,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(),
                ),
              ),
              Positioned(
                left: 696,
                top: 1032,
                child: Text(
                  'Proyección de fecha de graduación',
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 1236,
                child: Container(
                  width: 1272,
                  height: 313,
                  decoration: BoxDecoration(color: const Color(0xFFFD8305)),
                ),
              ),
              Positioned(
                left: 434,
                top: 1300,
                child: Text(
                  '¿Listo para comenzar?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 210,
                top: 1370,
                child: Text(
                  'Únete a miles de estudiantes que ya están aprovechando todas las funcionalidades de la app',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 229),
                    fontSize: 18,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 549,
                top: 1429,
                child: Container(
                  width: 173,
                  height: 56,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              Positioned(
                left: 581,
                top: 1445,
                child: Text(
                  'Crear Cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF4318D1),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 1549,
                child: Container(
                  width: 1272,
                  height: 377,
                  decoration: BoxDecoration(color: const Color(0xFF5B2E00)),
                ),
              ),
              Positioned(
                left: 60,
                top: 1597,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: ShapeDecoration(
                    image: DecorationImage(
                      image: NetworkImage("https://placehold.co/40x40"),
                      fit: BoxFit.contain,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              Positioned(
                left: 60,
                top: 1655,
                child: SizedBox(
                  width: 239,
                  child: Text(
                    'Haciendo tu vida universitaria más fácil y organizada',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 178),
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      height: 1.50,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 360,
                top: 1597,
                child: Text(
                  'Enlaces Rápidos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 360,
                top: 1637,
                child: Text(
                  'Inicio',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 178),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 360,
                top: 1677,
                child: Text(
                  'Características',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 178),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 360,
                top: 1717,
                child: Text(
                  'Testimonios',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 178),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 360,
                top: 1757,
                child: Text(
                  'Contacto',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 178),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 660,
                top: 1597,
                child: Text(
                  'Recursos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 660,
                top: 1637,
                child: Text(
                  'Centro de Ayuda',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 178),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 660,
                top: 1677,
                child: Text(
                  'Documentación',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 178),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 660,
                top: 1717,
                child: Text(
                  'Blog',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 178),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 960,
                top: 1597,
                child: Text(
                  'Legal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 960,
                top: 1637,
                child: Text(
                  'Términos de Uso',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 178),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 960,
                top: 1677,
                child: Text(
                  'Privacidad',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 178),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 960,
                top: 1717,
                child: Text(
                  'Cookies',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 178),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 60,
                top: 1829,
                child: Container(
                  width: 1152,
                  height: 49,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: Colors.white.withValues(alpha: 26),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 430,
                top: 1854,
                child: Text(
                  '© 2024 UNIMET App. Todos los derechos reservados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 178),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
              ),
              Positioned(
                left: 660,
                top: 40,
                child: Container(
                  width: 552,
                  height: 368,
                  decoration: ShapeDecoration(
                    image: DecorationImage(
                      image: NetworkImage("https://placehold.co/552x368"),
                      fit: BoxFit.contain,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x00000000),
                        blurRadius: 0,
                        offset: Offset(0, 0),
                        spreadRadius: 0,
                      ),BoxShadow(
                        color: Color(0x00000000),
                        blurRadius: 0,
                        offset: Offset(0, 0),
                        spreadRadius: 0,
                      ),BoxShadow(
                        color: Color(0x00000000),
                        blurRadius: 0,
                        offset: Offset(0, 0),
                        spreadRadius: 0,
                      ),BoxShadow(
                        color: Color(0x00000000),
                        blurRadius: 0,
                        offset: Offset(0, 0),
                        spreadRadius: 0,
                      ),BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 6,
                        offset: Offset(0, 4),
                        spreadRadius: 0,
                      )
                    ],
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