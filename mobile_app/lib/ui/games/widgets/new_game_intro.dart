import 'package:flutter/material.dart';

class NewGameIntro extends StatelessWidget {
  const NewGameIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rakibini Seç',
          style: TextStyle(
            color: Color(0xFF153725),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Nasıl bir düelloya girmek istediğini seç.',
          style: TextStyle(color: Color(0xFF738078), fontSize: 14),
        ),
      ],
    );
  }
}
