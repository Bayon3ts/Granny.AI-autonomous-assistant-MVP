import 'dart:ui';

import 'package:flutter/material.dart';

class GlowingOrb extends StatelessWidget {
  final AnimationController controller;
  final String label;

  const GlowingOrb({super.key, required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        final scale = lerpDouble(0.98, 1.06, Curves.easeInOut.transform(t))!;
        final glow = lerpDouble(0.2, 0.9, Curves.easeInOut.transform(t))!;
        return Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // outer soft halo
              Container(
                width: 220 * scale,
                height: 220 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF585BBC).withOpacity(0.12 * glow),
                      const Color(0xFFA5F3FC).withOpacity(0.06 * glow),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
              ),

              // faint ring / stroke
              Container(
                width: 180 * scale,
                height: 180 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 8,
                    color: Colors.white.withOpacity(0.06 + 0.06 * glow),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6EE7F9).withOpacity(0.08 * glow),
                      blurRadius: 36 * glow,
                      spreadRadius: 2 * glow,
                    )
                  ],
                ),
              ),

              // center circle
              Container(
                width: 128 * scale,
                height: 128 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.2, -0.2),
                    colors: [Color(0xFF6EE7F9), Color(0xFFA5F3FC)],
                    stops: [0.0, 1.0],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // tiny core point
              Positioned(
                child: Container(
                  width: 12 * (1 + glow * 0.4),
                  height: 12 * (1 + glow * 0.4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.95),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.white.withOpacity(0.7),
                          blurRadius: 8 * glow)
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
