import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String details;
  final Color accent;

  const SummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.details,
    this.accent = const Color(0xFF6EE7F9),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.18), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              textStyle: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            details,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              textStyle: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
