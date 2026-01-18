
import 'package:flutter/material.dart';

class RitualsScreen extends StatelessWidget {
  const RitualsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rituals'),
        backgroundColor: const Color(0xFF4ECDC4),
      ),
      body: const Center(
        child: Text(
          'Rituals Screen\n(Calendar, To-Do Lists, Affirmations)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}