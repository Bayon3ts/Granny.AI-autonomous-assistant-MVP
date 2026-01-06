import 'package:flutter/material.dart';

class FloatingHelpBubble extends StatelessWidget {
  const FloatingHelpBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // placeholder
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Help requested')));
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF6C5CE7).withOpacity(0.28),
                  blurRadius: 16)
            ],
          ),
          child: Row(
            children: const [
              Icon(Icons.mic, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Help Me',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
