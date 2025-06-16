import 'package:flutter/material.dart';
import '../models/faq_item.dart';

class FAQCard extends StatefulWidget {
  final FAQItem item;

  const FAQCard({super.key, required this.item});

  @override
  State<FAQCard> createState() => _FAQCardState();
}

class _FAQCardState extends State<FAQCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          widget.item.question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.item.answer),
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
}