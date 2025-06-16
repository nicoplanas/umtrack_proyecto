import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart'; // Importar GoogleFonts para estilos
import '/core/widgets/navbar.dart';
import '/core/widgets/footer.dart';
// import '../models/faq_item.dart'; // Comentado porque FAQItem se redefine aquí
// import '../widgets/faq_card.dart'; // Comentado porque FAQCard se redefine aquí

// --- NUEVA CLASE: LocationData para estructurar la información de ubicaciones ---
class LocationData {
  final String imagePath;
  final String title;
  final String description;

  LocationData({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

// --- MODIFICACIÓN: Clase FAQItem para soportar diferentes tipos de respuestas ---
class FAQItem {
  final String question;
  final String? textAnswer; // Para respuestas de texto simple
  final List<LocationData>? locations; // Para respuestas con datos de ubicación

  FAQItem({required this.question, this.textAnswer, this.locations})
      : assert(textAnswer != null || locations != null, 'FAQItem debe tener una respuesta de texto o datos de ubicación.');
}

// --- MODIFICACIÓN: Clase FAQCard para renderizar diferentes tipos de respuestas ---
class FAQCard extends StatelessWidget {
  final FAQItem item;

  const FAQCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2, // Añadido un poco de elevación para mejor visualización
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Bordes redondeados
      child: ExpansionTile(
        title: Text(
          item.question,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        // Contenido de la respuesta que cambia según el tipo de FAQItem
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: item.locations != null && item.locations!.isNotEmpty
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: item.locations!.map((location) {
                return Padding( // Agregado padding para cada fila de ubicación
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row( // 🔄 MODIFICADO: Cambiado de Column a Row para la distribución horizontal
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect( // Recorte de imagen con bordes redondeados
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          location.imagePath,
                          width: 220, // 🔄 MODIFICADO: Ancho aumentado para la imagen
                          height: 160, // 🔄 MODIFICADO: Altura aumentada para la imagen
                          fit: BoxFit.cover, // Cubre el espacio manteniendo la proporción
                          errorBuilder: (context, error, stackTrace) => Container( // Fallback en caso de error
                            width: 220,
                            height: 160,
                            color: Colors.grey[300],
                            child: Center(
                              child: Icon(Icons.broken_image, color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16), // Espacio entre la imagen y el texto
                      Expanded( // 🔄 MODIFICADO: Permite que el texto ocupe el espacio restante
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location.title,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700], // Color del título como en la imagen
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              location.description,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
                :
            // 🔄 NUEVO/MODIFICADO: Estilizado para respuestas de texto simple
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50], // Fondo suave para la respuesta
                borderRadius: BorderRadius.circular(8), // Bordes redondeados
                border: Border.all(color: Colors.blueGrey.shade100!), // Borde sutil
              ),
              child: Text(
                item.textAnswer ?? 'No hay respuesta disponible.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF475569),
                  height: 1.5, // Altura de línea para mejor legibilidad
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final email = user?.email ?? 'Invitado'; // Cambiado a 'Invitado' por defecto

        // --- MODIFICACIÓN: Lista de FAQItems con el nuevo formato para ubicaciones ---
        final List<FAQItem> faqList = [
          FAQItem(
            question: '¿Dónde queda ubicado el Eugenio Mendoza?',
            textAnswer: 'El edificio Eugenio Mendoza se encuentra al lado del estacionamiento norte, un punto central y de fácil acceso dentro del campus. Es una de las edificaciones principales para servicios administrativos.',
          ),
          FAQItem(
            question: '¿Qué procesos se pueden realizar en la taquilla principal?',
            textAnswer: 'En la taquilla principal de la universidad puedes realizar una amplia variedad de trámites y gestiones, incluyendo pagos de matrícula y aranceles, retiro de documentos oficiales, y consultas generales sobre procesos administrativos o académicos. Es el punto de atención central para la mayoría de las inquietudes estudiantiles.',
          ),
          FAQItem(
            question: '¿Hay un Correo al que pueda escribir por mis pasantias?',
            textAnswer: 'Sí, para todas tus consultas relacionadas con pasantías, puedes escribir directamente a la oficina de coordinación de pasantías al siguiente correo electrónico: pasantias@unimet.edu.ve. Ellos te brindarán toda la información y el apoyo necesario para tu proceso.',
          ),
          FAQItem(
            question: '¿Control de Estudios hasta que hora opera en dias de semana?',
            textAnswer: 'La oficina de Control de Estudios opera de lunes a viernes, con un horario de atención dividido en dos bloques: de 8:00 a.m. a 12:30 p.m. y de 2:00 p.m. a 4:00 p.m. Te recomendamos verificar cualquier cambio en su horario antes de tu visita.',
          ),
          FAQItem(
            question: '¿Como puedo reservar un cubiculo en la biblioteca?',
            textAnswer: 'Reservar un cubículo en la biblioteca es un proceso sencillo. Puedes hacerlo a través del sistema de reservas en línea, accesible desde el portal oficial de la biblioteca, o si lo prefieres, puedes dirigirte directamente al mostrador de atención al usuario para consultar la disponibilidad y realizar tu reserva de forma presencial.',
          ),
          FAQItem(
            question: '¿Que puedo comer en la feria?',
            textAnswer: 'La feria de la universidad es un espacio vibrante con una gran diversidad de opciones gastronómicas. Podrás disfrutar desde platos tradicionales como arepas y empanadas, hasta almuerzos completos, pasando por una variada selección de postres y bebidas. Hay locales para todos los gustos y presupuestos.',
          ),
          FAQItem(
            question: 'Ubicaciones claves de la universidad',
            locations: [
              LocationData(
                imagePath: 'assets/eugenio_mendoza.png', // 📌 IMPORTANTE: REEMPLAZA CON LA RUTA DE TU IMAGEN
                title: 'Edif. Eugenio Mendoza',
                description: 'Edificio de Servicios, adyacente al Decanato de Estudiantes y frente a la Feria. Contiene diversas oficinas y departamentos, incluyendo la sede de Caja UNIMET en el sótano 1 y algunas oficinas de postgrado en el piso 4.',
              ),
              LocationData(
                imagePath: 'assets/edif_a1.png', // 📌 IMPORTANTE: REEMPLAZA CON LA RUTA DE TU IMAGEN
                title: 'Edif A1',
                description: 'El edificio A1 en la UNIMET es uno de los módulos de aulas principales que forman parte del campus. Se utiliza para impartir clases y, a menudo, es un punto de referencia para actividades académicas específicas, como talleres en su azotea.',
              ),
              // 🔄 NUEVO: Información del Edificio A2
              LocationData(
                imagePath: 'assets/edif_a2.png', // 📌 IMPORTANTE: REEMPLAZA CON LA RUTA DE TU IMAGEN
                title: 'Edif. A2',
                description: 'El edificio A2 forma parte de los módulos de aulas de la universidad. Es una de las estructuras principales dedicadas a la enseñanza, y se encuentra en una zona céntrica del campus junto a otros edificios de aulas. La Dirección de Decanato de Estudiantes, por ejemplo, está adyacente a este edificio, frente al área donde tradicionalmente se realizan las ferias.',
              ),
              // 🔄 NUEVO: Información de Laboratorios de Química
              LocationData(
                imagePath: 'assets/lab_quimica.png', // 📌 IMPORTANTE: REEMPLAZA CON LA RUTA DE TU IMAGEN
                title: 'Laboratorios de Química',
                description: 'Estos laboratorios están ubicados principalmente en el Edificio de Laboratorios Corimón, Nivel Plaza. Son espacios esenciales para las prácticas de ingeniería y ciencias, dando apoyo a materias como Ingeniería Ambiental y Química.',
              ),
              // 🔄 NUEVO: Información de Laboratorios de Computación
              LocationData(
                imagePath: 'assets/lab_computacion.png', // 📌 IMPORTANTE: REEMPLAZA CON LA RUTA DE TU IMAGEN
                title: 'Laboratorios de Computación',
                description: 'La UNIMET cuenta con diversos laboratorios de computación distribuidos, siendo el Centro Mundo X un ejemplo de un espacio dedicado a la experimentación con tecnologías avanzadas. Algunos laboratorios especializados, como el Laboratorio de Neurociencias, que utiliza equipos de computación de alto desempeño, se encuentran adscritos a sus respectivos departamentos dentro del campus.',
              ),
            ],
          ),
          FAQItem(
            question: 'Contactos claves',
            textAnswer: 'Numeros: ',
          ),
        ];

        return Scaffold(
          body: ListView(
            children: [
              Navbar(email: email),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Preguntas Frecuentes',
                    style: GoogleFonts.poppins( // Usando GoogleFonts
                      fontSize: 32, // Ajustado el tamaño para que se vea mejor
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B), // Color de texto
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar pregunta...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: Colors.grey[100], // Fondo ligeramente gris
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none, // Quitamos el borde visible
                    ),
                    focusedBorder: OutlineInputBorder( // Borde cuando está enfocado
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2), // Color de enfoque
                    ),
                    enabledBorder: OutlineInputBorder( // Borde normal
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)), // Color de borde sutil
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 16, color: const Color(0xFF1E293B)),
                  onChanged: (value) {
                    // Puedes implementar filtrado aquí en el futuro
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Mapea la lista de FAQItem a FAQCard
              ...faqList.map((faq) => FAQCard(item: faq)).toList(),
              const SizedBox(height: 24),
              const Footer(),
            ],
          ),
        );
      },
    );
  }
}