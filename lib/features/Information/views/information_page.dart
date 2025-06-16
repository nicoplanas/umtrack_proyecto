import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/footer.dart';
import '../models/faq_item.dart';
import '../widgets/faq_card.dart';
import '../../../core/widgets/navbar.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({super.key});

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  final TextEditingController _searchController = TextEditingController();
  late Map<String, List<FAQItem>> _categorizedFaqItems;
  late Map<String, List<FAQItem>> _filteredCategorizedFaqItems;

  final Map<String, List<FAQItem>> _allCategorizedFaqItems = {
    'Servicios y Trámites': [
      FAQItem(
        question: '¿Qué procesos se pueden realizar en la taquilla principal?',
        answer: 'En la taquilla principal de la universidad puedes realizar una amplia variedad de trámites y gestiones, incluyendo pagos de matrícula y aranceles, retiro de documentos oficiales, y consultas generales sobre procesos administrativos o académicos. Es el punto de atención central para la mayoría de las inquietudes estudiantiles.',
      ),
      FAQItem(
        question: '¿Hay un Correo al que pueda escribir por mis pasantías?',
        answer: 'Sí, para todas tus consultas relacionadas con pasantías, puedes escribir directamente a la oficina de coordinación de pasantías al siguiente correo electrónico: pasantias@unimet.edu.ve. Ellos te brindarán toda la información y el apoyo necesario para tu proceso.',
      ),
      FAQItem(
        question: '¿Control de Estudios hasta que hora opera en días de semana?',
        answer: 'La oficina de Control de Estudios opera de lunes a viernes, con un horario de atención dividido en dos bloques: de 8:00 a.m. a 12:30 p.m. y de 2:00 p.m. a 4:00 p.m. Te recomendamos verificar cualquier cambio en su horario antes de tu visita.',
      ),
      FAQItem(
        question: '¿Cómo puedo reservar un cubículo en la biblioteca?',
        answer: 'Reservar un cubículo en la biblioteca es un proceso sencillo. Puedes hacerlo a través del sistema de reservas en línea, accesible desde el portal oficial de la biblioteca, o si lo prefieres, puedes dirigirte directamente al mostrador de atención al usuario para consultar la disponibilidad y realizar tu reserva de forma presencial.',
      ),
      FAQItem(
        question: 'Contactos claves',
        answer: 'Secretaría: secretaria@universidad.edu, Soporte TI: soporte@universidad.edu.',
      ),
    ],
    'Ubicación de Edificios y Laboratorios': [
      FAQItem(
        question: '¿Dónde queda ubicado el Eugenio Mendoza?',
        answer: 'El edificio Eugenio Mendoza se encuentra al lado del estacionamiento norte, un punto central y de fácil acceso dentro del campus. Es una de las edificaciones principales para servicios administrativos.',
      ),
      FAQItem(
        question: '¿Dónde queda ubicado el Edificio A1?',
        answer: 'El edificio A1 en la UNIMET es uno de los módulos de aulas principales que forman parte del campus. Se utiliza para impartir clases y, a menudo, es un punto de referencia para actividades académicas específicas, como talleres en su azotea.',
      ),
      FAQItem(
        question: '¿Dónde queda ubicado el Edificio A2?',
        answer: 'El edificio A2 forma parte de los módulos de aulas de la universidad. Es una de las estructuras principales dedicadas a la enseñanza, y se encuentra en una zona céntrica del campus junto a otros edificios de aulas. La Dirección de Decanato de Estudiantes, por ejemplo, está adyacente a este edificio, frente al área donde tradicionalmente se realizan las ferias.',
      ),
      FAQItem(
        question: '¿Dónde queda ubicado el Laboratorio de quimica?',
        answer: 'Estos laboratorios están ubicados principalmente en el Edificio de Laboratorios Corimón, Nivel Plaza. Son espacios esenciales para las prácticas de ingeniería y ciencias, dando apoyo a materias como Ingeniería Ambiental y Química.',
      ),
      FAQItem(
        question: '¿Dónde queda ubicado el Laboratorio de computacion?',
        answer: 'La UNIMET cuenta con diversos laboratorios de computación distribuidos, siendo el Centro Mundo X un ejemplo de un espacio dedicado a la experimentación con tecnologías avanzadas. Algunos laboratorios especializados, como el Laboratorio de Neurociencias, que utiliza equipos de computación de alto desempeño, se encuentran adscritos a sus respectivos departamentos dentro del campus. En la imagen se ve un laboratorio de Metaverso',
      ),
      FAQItem(
        question: 'Ubicaciones claves de la universidad',
        answer: 'Se divide en edificios y laboratorios, teniendo el edificio Eugenio Mendoza, el A1 y el A2, y dos laboratorios muy importantes siendo estos el laboratorio de Quimica y de computacion',
      ),
    ],
    'Servicios Generales': [
      FAQItem(
        question: '¿Qué puedo comer en la feria?',
        answer: 'La feria de la universidad es un espacio vibrante con una gran diversidad de opciones gastronómicas. Podrás disfrutar desde platos tradicionales como arepas y empanadas, hasta almuerzos completos, pasando por una variada selección de postres y bebidas. Hay locales para todos los gustos y presupuestos.',
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _categorizedFaqItems = _allCategorizedFaqItems;
    _filteredCategorizedFaqItems = _categorizedFaqItems;
    _searchController.addListener(_filterFaqItems);
  }

  void _filterFaqItems() {
    final query = _normalize(_searchController.text.trim().toLowerCase());
    setState(() {
      _filteredCategorizedFaqItems = {};
      _categorizedFaqItems.forEach((category, items) {
        final filteredItems = items.where((item) {
          final normalizedQuestion = _normalize(item.question.toLowerCase());
          return normalizedQuestion.contains(query);
        }).toList();
        if (filteredItems.isNotEmpty) {
          _filteredCategorizedFaqItems[category] = filteredItems;
        }
      });
    });
  }

  String _normalize(String input) {
    final withDiacritics = 'áéíóúüñÁÉÍÓÚÜÑ';
    final withoutDiacritics = 'aeiouunAEIOUUN';
    for (int i = 0; i < withDiacritics.length; i++) {
      input = input.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return input;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Navbar(),
            const SizedBox(height: 30),
            Text(
              'Preguntas Frecuentes',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Buscar pregunta...',
                  hintStyle: const TextStyle(color: Colors.black45),
                  prefixIcon: const Icon(Icons.search, color: Colors.black45),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurple.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurple.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: _filteredCategorizedFaqItems.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            entry.key,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange.shade900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...entry.value.map((item) => FAQCard(
                        item: item,
                        backgroundColor: const Color(0xFFFFF3E0),
                        questionColor: Colors.black,
                        answerColor: Colors.black,
                      )),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            const Footer(),
          ],
        ),
      ),
    );
  }
}