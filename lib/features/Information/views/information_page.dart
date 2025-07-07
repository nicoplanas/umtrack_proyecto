import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/footer.dart';
import '../../../core/widgets/navbar.dart';
import '../models/faq_item.dart';
import '../widgets/faq_card.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({super.key});

  @override
  State<InformationPage> createState() => _InformationPageState();
}

// Debes definir esta clase en tu archivo para que funcione el TabBar fijo al hacer scroll
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverTabBarDelegate(this._tabBar);
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: Colors.white, child: _tabBar);
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override bool shouldRebuild(covariant _SliverTabBarDelegate old) => false;
}

class _InformationPageState extends State<InformationPage> {
  // Controladores de búsqueda
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchFeriaController = TextEditingController();

  // FAQs Feria clasificadas justo como los definiste
  final Map<String, List<FAQItem>> _categorizedFeriaFaqItems = {
    'Desayuno': [
      FAQItem(
        question: 'Local A',
        answer: 'Nombre:Empanaditas, Horario: 7am a 5pm, Tipo de comida: empanadas y desayunos, Precios(dolares):empanadas 1,5/cafe 1/cachitos 2/jugos 2,5',
      ),
      FAQItem(
        question: 'Local E',
        answer: 'Nombre:UnimetTotal ,Horario:8am a 7:30pm , Tipo de comida: desayunos y almuerzos , Precios(dolares):empanadas 1,5/Hamburguesas 5,5/tequeños 4',
      ),
      FAQItem(
        question: 'Local F',
        answer: 'Nombre:PanUnimet ,Horario:8am a 5pm , Tipo de comida: Pasteleria , Precios(dolares):Cachitos 3,5/Panes 5/MiniLunch 5',
      ),
      FAQItem(
        question: 'Local H',
        answer: 'Nombre:EmpanadasUnimet ,Horario:7am a 4pm , Tipo de comida: empanadas , Precios(dolares):Empanada de queso 1,5/Empanada de carne 2,5/Empanada de pollo 2,5',
      ),
    ],
    'Almuerzos': [
      FAQItem(
        question: 'Local B',
        answer: 'Nombre:PinchoPan ,Horario:10am a 6pm , Tipo de comida: Shawarmas y hamburguesas , Precios(dolares):Shawarmas 6/Hamburguesas 6/ Combo Shawarmma 11/ Combo Hamburguesas 11,5',
      ),
      FAQItem(
        question: 'Local D',
        answer: 'Nombre:PizzasUnimet ,Horario:11am a 7pm , Tipo de comida: Pizzas , Precios(dolares):Un Slice 3,5/Dos Slice 6,5/Pizza completa 16',
      ),
      FAQItem(
        question: 'Local G',
        answer: 'Nombre:Bowl ,Horario:10am a 7pm , Tipo de comida: Bowls de sushi/pollo/carne , Precios(dolares):Bowl pollo 7,5/Bowl carne 7,5/Bowl sushi(pescado) 8,5',
      ),
      FAQItem(
        question: 'Local J',
        answer: 'Nombre:PokeSushi ,Horario:10am a 6:30pm , Tipo de comida: Pokes y sushi , Precios(dolares):Poke pequeño 6/Poke mediano 8,5/Poke grande 12',
      ),
    ],
    'Dulces': [
      FAQItem(
        question: 'Local C',
        answer: 'Nombre: Chip a Cookie\nHorario: 9:30am a 6pm\nTipo de comida: galletas\nPrecios: 3 galletas 4,5 USD/6 galletas 7 USD/12 galletas 12 USD',
      ),
      FAQItem(
        question: 'Local I',
        answer: 'Nombre:Dey Donuts ,Horario: 10am a 6:30pm , Tipo de comida: donas , Precios(dolares):dona glaseada 2/dona rellena 3,5/ dona con chispas 3',
      ),
    ],
    'Ubicaciones Extra': [
      FAQItem(
        question: 'Baños',
        answer: 'Los baños se situan debajo del local J, tanto para mujeres y hombres, esta abierto mientras la universidad este abierta',
      ),
      FAQItem(
        question: 'Microondas',
        answer: 'Los microondas se situan debajo de los baños, justo a su derecha, hay varios microondas que se pueden utilizar',
      ),
    ],
  };
  late Map<String, List<FAQItem>> _filteredFeriaFaqItems;

  // FAQs generales categorizadas (tu lista original completa)
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
        question: 'Contactos Clave de la UNIMET',
        answer: '''
Contactos Generales y Administrativos**
  * Central Telefónica UNIMET:
    * (0212) 241.48.33
    * (0212) 242.33.42
    * (0212) 241.59.85
  * Admisiones:
    * Teléfono: (0412)-240.32.01
    * Correo: admision@unimet.edu.ve
  * Vicerrectorado Administrativo:
    * Correo: mescalona@unimet.edu.ve (María Gabriela Escalona, Vicerrectora)
    * Asistentes:
      * Teresa Guedez: tguedez@unimet.edu.ve / (0212)-240.32.51
      * Gloria Carballeira: gcarballeira@unimet.edu.ve / (0212)-240.34.01
  * Secretaría General:
    * Correo: sperera@unimet.edu.ve (Luis Santiago Perera, Secretario General)
  * Dirección de Finanzas (Caja UNIMET):
    * Correo: anieves@unimet.edu.ve (Alexandra Nieves, Directora)
    * Gerencia de Tesorería y Cobranzas: (0212)-240.36.82
    * Gerencia de Contabilidad: (0212)-240.34.56
  * Servicios (Infraestructura, etc.):
    * Correo: igmendozar@unimet.edu.ve (Indira Mendoza, Directora)
    * Teléfono: (0212)-240.37.13
    * Asistente: (0212)-240.37.11

**Contactos para Estudiantes**
  * Decanato de Estudiantes:
    * Correo: dec-est@unimet.edu.ve
    * Correo de Vinculación Universitaria: vinculacionuniversitaria@unimet.edu.ve
  * Dirección de Desarrollo y Bienestar Estudiantil (DDBE):
    * Correo: ddbe@unimet.edu.ve
    * Teléfono: (0212)-240.32.71 (Gerencia)
    * Asesoramiento Grupal: (0212)-240.37.96
    * Asesoramiento Individual: (0212)-240.39.19 / (0212)-240.32.84 (Recepción)
  * Control de Estudios (Dirección de Registro y Control de Estudios):
    * Pregrado: pregrado@unimet.edu.ve / (0212)-240.32.93 / 240.32.58
    * Postgrado: postgrado@unimet.edu.ve / (0212)-240.36.51 / 240.36.06
  * Pasantías:
    * Correo general de Pasantías: pasantias@unimet.edu.ve
    * Correo Internship UNIMET: internship@unimet.edu.ve
    * Feria de Empleos y Pasantías: empleamet@unimet.edu.ve
  * Solicitud de Documentos (Notas Certificadas, Programas):
    * Teléfonos: (0212)-240.32.60 / 240.32.61 / 0212)-240.32.93 / 240.36.51 / 240.36.06
    * Correo para programas certificados: programas@unimet.edu.ve
    * Correo para revisión de expediente: revisiondedocumentos@unimet.edu.ve
    * Taquilla de Grado (entrega de documentos): (0212)-240.32.98 / 240.32.54
  * Biblioteca Pedro Grases:
    * Teléfonos: (0212)- 240 3433 / 3434
    * Correo para solvencias: solvenciasbpg@unimet.edu.ve
  * CIUNIMET (Objetos perdidos y encontrados):
    * Correo: ciunimet@unimet.edu.ve
    * Teléfonos: (0212)-240.39.76 / 240.32.76

**Decanatos y Facultades (Ejemplos)**
  * Facultad de Ciencias (Decano):
    * Correo: pcertad@unimet.edu.ve (Pedro Certad)
    * Teléfonos: (0212)-240.38.79 / 240.39.97
  * Facultad de Humanidades (Decano):
    * Correo: mbriceno@unimet.edu.ve (Milagros Briceño)
    * Teléfono: (0212)-240.34.94
            ''',
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
        answer: 'La UNIMET cuenta con diversos laboratorios de computación distribuidos, siendo el Centro Mundo X un ejemplo de un espacio dedicado a la experimentación con tecnologías avanzadas. Algunos laboratorios especializados, como el Laboratorio de Neurociencias, que utiliza equipos de computación de alto desempeño, se encuentran adscritos a sus respectivos departamentos dentro del campus.',
      ),
    ],
    'Servicios Generales': [
      FAQItem(
        question: '¿Qué puedo comer en la feria?',
        answer: 'La feria de la universidad es un espacio vibrante con una gran diversidad de opciones gastronómicas. Podrás disfrutar desde platos tradicionales como arepas y empanadas, hasta almuerzos completos, pasando por una variada selección de postres y bebidas. Hay locales para todos los gustos y presupuestos.',
      ),
    ],
  };
  late Map<String, List<FAQItem>> _filteredCategorizedFaqItems;

  @override
  void initState() {
    super.initState();

    // Inicializar filtros Feria y FAQ generales
    _filteredFeriaFaqItems = _categorizedFeriaFaqItems;
    _filteredCategorizedFaqItems = _allCategorizedFaqItems;

    _searchFeriaController.addListener(() {
      final q = _normalize(_searchFeriaController.text.trim().toLowerCase());
      setState(() {
        _filteredFeriaFaqItems = {};
        _categorizedFeriaFaqItems.forEach((category, items) {
          final filtered = items.where((item) => _normalize(item.question.toLowerCase()).contains(q)).toList();
          if (filtered.isNotEmpty) {
            _filteredFeriaFaqItems[category] = filtered;
          }
        });
      });
    });

    _searchController.addListener(() {
      final q = _normalize(_searchController.text.trim().toLowerCase());
      setState(() {
        _filteredCategorizedFaqItems = {};
        _allCategorizedFaqItems.forEach((category, items) {
          final filtered = items.where((item) => _normalize(item.question.toLowerCase()).contains(q)).toList();
          if (filtered.isNotEmpty) {
            _filteredCategorizedFaqItems[category] = filtered;
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFeriaController.dispose();
    super.dispose();
  }

  String selectedTab = 'Feria';

  Widget _buildTabButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _normalize(String input) {
    const withDiacritics = 'áéíóúüñÁÉÍÓÚÜÑ';
    const withoutDiacritics = 'aeiouunAEIOUUN';
    for (var i = 0; i < withDiacritics.length; i++) {
      input = input.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return input;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(child: const Navbar()),
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFFF6F00),
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Text(
                      'Centro de Ayuda',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Encuentra respuestas a las preguntas más frecuentes sobre la\naplicación universitaria',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverTabBarDelegate(
                TabBar(
                  labelColor: Colors.deepOrange,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: Colors.deepOrange,
                  tabs: const [
                    Tab(text: 'Feria'),
                    Tab(text: 'Universidad'),
                    Tab(text: 'Contactos'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ],
          body: TabBarView(
            children: [
              // FERIA
              ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 24),
                  Center(child: Text('MAPA', style: GoogleFonts.poppins(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black))),
                  const SizedBox(height: 12),
                  Image.asset('assets/mapaferia.png', height: 300, fit: BoxFit.contain),
                  const SizedBox(height: 24),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 45),
                    child: TextField(
                      controller: _searchFeriaController,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar en Feria...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._filteredFeriaFaqItems.entries.expand((entry) => [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(45, 16, 45, 4),
                      child: Text(entry.key, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFFD8305))),
                    ),
                    ...entry.value.map((item) => FAQCard(item: item, backgroundColor: Colors.white, questionColor: Colors.black, answerColor: Colors.black)),
                  ]).toList(),
                  const SizedBox(height: 40),
                  const Footer(),
                ],
              ),

              // UNIVERSIDAD
              ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 24),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 45),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar pregunta...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._filteredCategorizedFaqItems.entries.expand((entry) => [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(45, 16, 45, 4),
                      child: Text(entry.key, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFFD8305))),
                    ),
                    ...entry.value
                        .where((item) => item.question != 'Contactos Clave de la UNIMET')
                        .map((item) => FAQCard(
                      item: item,
                      backgroundColor: const Color(0xFFFFF3E0),
                      questionColor: Colors.black,
                      answerColor: Colors.black,
                    )),
                  ]).toList(),
                  const SizedBox(height: 40),
                  const Footer(),
                ],
              ),
              // Contactos
              ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Directorio de Contactos',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFD8305),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._allCategorizedFaqItems['Servicios y Trámites']!
                      .where((item) => item.question.contains('Contactos'))
                      .map((item) => FAQCard(item: item, backgroundColor: Colors.white)),
                  const SizedBox(height: 40),
                  const Footer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
