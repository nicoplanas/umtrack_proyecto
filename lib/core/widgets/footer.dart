import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF5B2E00),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 700;
                  return Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo + descripción
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: const Color(0xFFFF9100),
                              ),
                              child: const Center(
                                child: Text(
                                  'L',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 190,
                              child: Text(
                                'Haciendo tu vida universitaria más fácil y organizada',
                                style: TextStyle(
                                  color: Color.fromARGB(178, 255, 255, 255),
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Secciones del menú
                      Expanded(
                        child: Wrap(
                          spacing: 60,
                          runSpacing: 24,
                          alignment: WrapAlignment.center,
                          children: [
                            _footerSection(
                              title: 'Enlaces Rápidos',
                              items: ['Inicio', 'Características', 'Testimonios', 'Contacto'],
                            ),
                            _footerSection(
                              title: 'Recursos',
                              items: ['Centro de Ayuda', 'Documentación', 'Blog'],
                            ),
                            _footerSection(
                              title: 'Legal',
                              items: ['Términos de Uso', 'Privacidad', 'Cookies'],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              const Divider(color: Color.fromARGB(26, 255, 255, 255), thickness: 1),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  '© 2024 UNIMET App. Todos los derechos reservados.',
                  style: TextStyle(
                    color: Color.fromARGB(178, 255, 255, 255),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footerSection({required String title, required List<String> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        for (var item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              item,
              style: const TextStyle(
                color: Color.fromARGB(178, 255, 255, 255),
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
          ),
      ],
    );
  }
}