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
  late List<FAQItem> _filteredFaqItems;
  final List<FAQItem> _allFaqItems = [
    FAQItem(
      question: '¿Dónde queda ubicado el Eugenio Mendoza?',
      answer: 'El edificio Eugenio Mendoza se encuentra al lado del estacionamiento norte, un punto central y de fácil acceso dentro del campus. Es una de las edificaciones principales para servicios administrativos.',
    ),
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
      answer: 'La oficina de Control de Estudios opera de lunes a viernes, con un horario de atención dividido en dos bloques: de 8:00 a.m. a 12:30 p.m. y de 2:00 p.m. a 4:00 p.m. Te recomendamos verificar cualquier cambio en su horario antes de tu visita.La oficina de Control de Estudios opera de lunes a viernes, con un horario de atención dividido en dos bloques: de 8:00 a.m. a 12:30 p.m. y de 2:00 p.m. a 4:00 p.m. Te recomendamos verificar cualquier cambio en su horario antes de tu visita.',
    ),
    FAQItem(
      question: '¿Cómo puedo reservar un cubículo en la biblioteca?',
      answer: 'Reservar un cubículo en la biblioteca es un proceso sencillo. Puedes hacerlo a través del sistema de reservas en línea, accesible desde el portal oficial de la biblioteca, o si lo prefieres, puedes dirigirte directamente al mostrador de atención al usuario para consultar la disponibilidad y realizar tu reserva de forma presencial.',
    ),
    FAQItem(
      question: '¿Qué puedo comer en la feria?',
      answer: 'La feria de la universidad es un espacio vibrante con una gran diversidad de opciones gastronómicas. Podrás disfrutar desde platos tradicionales como arepas y empanadas, hasta almuerzos completos, pasando por una variada selección de postres y bebidas. Hay locales para todos los gustos y presupuestos.',
    ),
    FAQItem(
      question: 'Ubicaciones claves de la universidad',
      answer: 'Despliega las ubicaciones específicas de los edificios y laboratorios.',
    ),
    FAQItem(
      question: 'Edificio Eugenio Mendoza',
      answer: 'Laboratorio 1A\nLaboratorio 1B',
    ),
    FAQItem(
      question: 'Edificio A1',
      answer: 'Laboratorio 2A\nLaboratorio 2B',
    ),
    FAQItem(
      question: 'Edificio A2',
      answer: 'Laboratorio 3A\nLaboratorio 3B',
    ),
    FAQItem(
      question: 'Laboratorio de quimica',
      answer: 'Laboratorio 4A\nLaboratorio 4B',
    ),
    FAQItem(
      question: 'Laboratorio de fisica',
      answer: 'Laboratorio 5A\nLaboratorio 5B',
    ),
    FAQItem(
      question: 'Contactos claves',
      answer: 'Secretaría: secretaria@universidad.edu, Soporte TI: soporte@universidad.edu.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredFaqItems = _allFaqItems;
    _searchController.addListener(_filterFaqItems);
  }

  void _filterFaqItems() {
    final query = _normalize(_searchController.text.trim().toLowerCase());
    setState(() {
      _filteredFaqItems = _allFaqItems.where((item) {
        final normalizedQuestion = _normalize(item.question.toLowerCase());
        return normalizedQuestion.contains(query);
      }).toList();
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
              children: _filteredFaqItems.map((item) => FAQCard(
                item: item,
                backgroundColor: const Color(0xFFFFF3E0), // naranja clarito
                questionColor: Colors.black,
                answerColor: Colors.black,
              )).toList(),
            ),
            const SizedBox(height: 40),
            const Footer(),
          ],
        ),
      ),
    );
  }
}