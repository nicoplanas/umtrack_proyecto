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
        ];

        return Scaffold(
          body: ListView(
            children: [
              Navbar(email: email),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Información de la Universidad',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
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