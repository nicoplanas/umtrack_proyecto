import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/faq_item.dart';

class FAQCard extends StatefulWidget {
  final FAQItem item;
  final Color backgroundColor;
  final Color questionColor;
  final Color answerColor;

  const FAQCard({
    super.key,
    required this.item,
    this.backgroundColor = Colors.white,
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
          style: GoogleFonts.poppins(
            color: widget.answerColor,
            fontSize: 14,
          ),
          textAlign: TextAlign.justify,
        );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(45, 16, 45, 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE0E0E0), // Gris claro para definir borde
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.white,
            trailing: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.black54,
              size: 24,
            ),
            title: Text(
              widget.item.question,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: widget.questionColor,
              ),
            ),
            children: [
              const Divider(
                color: Color(0xFFE0E0E0),
                thickness: 1,
                height: 1,
              ),
              const SizedBox(height: 12),
              answerWidget,
            ],
            onExpansionChanged: (expanded) {
              setState(() => _isExpanded = expanded);
            },
          ),
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
          style: GoogleFonts.poppins(
            color: widget.answerColor,
            fontSize: 14,
          ),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 12),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              assetPath,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}
