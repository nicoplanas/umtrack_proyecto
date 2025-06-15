import 'package:flutter/material.dart';
import '../models/faq_item.dart';
import '../widgets/faq_card.dart';

class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(
        title: const Text('Información de la Universidad'),
      ),
      body: ListView(
        children: faqList.map((faq) => FAQCard(item: faq)).toList(),
      ),
    );
  }
}