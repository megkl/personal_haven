import 'package:flutter/material.dart';

class WellnessScreen extends StatelessWidget {
  const WellnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness'),
        backgroundColor: const Color(0xFF4ECDC4),
      ),
      body: const Center(
        child: Text(
          'Wellness Screen\n(Food Diary, Budget, Goals)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}