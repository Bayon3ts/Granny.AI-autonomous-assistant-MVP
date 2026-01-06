import 'package:flutter/material.dart';

class QuickChip extends StatelessWidget {
  final String label;
  final bool active;
  const QuickChip({super.key, required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEEF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFF6B21A8) : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
