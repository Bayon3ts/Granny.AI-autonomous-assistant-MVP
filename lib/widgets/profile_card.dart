import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final int age;
  final String healthSummary;

  const ProfileCard({
    super.key,
    required this.name,
    required this.age,
    required this.healthSummary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage:
                const NetworkImage('https://i.pravatar.cc/150?img=65'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$name, $age',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(healthSummary,
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          // const Icon(Icons.chevron_right, color: Colors.black26),
        ],
      ),
    );
  }
}
