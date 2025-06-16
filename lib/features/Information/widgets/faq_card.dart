import 'package:flutter/material.dart';
import '../models/faq_item.dart';

class FAQCard extends StatefulWidget {
  final FAQItem item;
  final Color backgroundColor;
  final Color questionColor;
  final Color answerColor;

  const FAQCard({
    super.key,
    required this.item,
    this.backgroundColor = const Color(0xFFF3F3F3),
    this.questionColor = Colors.black,
    this.answerColor = Colors.black87,
  });

  @override
  State<FAQCard> createState() => _FAQCardState();
}

class _FAQCardState extends State<FAQCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    Widget answerWidget;

    switch (widget.item.question) {
      case '¿Dónde queda ubicado el Eugenio Mendoza?':
        answerWidget = _buildAnswerWithImage('assets/eugenio_mendoza.png');
        break;
      case '¿Dónde queda ubicado el Edificio A1?':
        answerWidget = _buildAnswerWithImage('assets/edifa1.png');
        break;
      case '¿Dónde queda ubicado el Edificio A2?':
        answerWidget = _buildAnswerWithImage('assets/edifa2.png');
        break;
      case '¿Dónde queda ubicado el Laboratorio de quimica?':
        answerWidget = _buildAnswerWithImage('assets/labquimica.png');
        break;
      case '¿Dónde queda ubicado el Laboratorio de computacion?':
        answerWidget = _buildAnswerWithImage('assets/labcompu.png');
        break;
      default:
        answerWidget = Text(
          widget.item.answer,
          style: TextStyle(color: widget.answerColor),
          textAlign: TextAlign.justify,
        );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: widget.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          widget.item.question,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: widget.questionColor,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: answerWidget,
          ),
        ],
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
        },
        trailing: Icon(
          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildAnswerWithImage(String assetPath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.item.answer,
          style: TextStyle(color: widget.answerColor),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 10),
        Center(
          child: Image.asset(
            assetPath,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}
