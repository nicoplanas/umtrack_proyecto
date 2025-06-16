import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/widgets/navbar.dart';
import '/core/widgets/footer.dart';
import '../models/faq_item.dart';
import '../widgets/faq_card.dart';

class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final email = user?.email ?? 'Guest';

        final List<FAQItem> faqList = [
          FAQItem(
            question: '¿Dónde queda ubicado el Eugenio Mendoza?',
            answer: 'El edificio Eugenio Mendoza se encuentra al lado del estacionamiento norte.',
          ),
          FAQItem(
            question: '¿Qué procesos se pueden realizar en la taquilla principal?',
            answer: 'Se pueden realizar pagos, retiros de documentos y consultas generales.',
          ),
          FAQItem(
            question: '¿Hay un Correo al que pueda escribir por mis pasantias',
            answer: 'Se pueden realizar pagos, retiros de documentos y consultas generales.',
          ),
          FAQItem(
            question: '¿Control de Estudios hasta que hora opera en dias de semana?',
            answer: 'Se pueden realizar pagos, retiros de documentos y consultas generales.',
          ),
          FAQItem(
            question: '¿Como puedo reservar un cubiculo en la biblioteca?',
            answer: 'Se pueden realizar pagos, retiros de documentos y consultas generales.',
          ),
          FAQItem(
            question: '¿Que puedo comer en la feria?',
            answer: 'Se pueden realizar pagos, retiros de documentos y consultas generales.',
          ),
          FAQItem(
            question: 'Ubicaciones claves de la universidad',
            answer: 'Se pueden realizar pagos, retiros de documentos y consultas generales.',
          ),
        ];

        return Scaffold(
          body: ListView(
            children: [
              Navbar(email: email),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Preguntas Frecuentes',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar pregunta...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  onChanged: (value) {
                    // Puedes implementar filtrado aquí en el futuro
                  },
                ),
              ),
              const SizedBox(height: 16),
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