import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/app_initializer.dart';


void main() {
  runApp(const ProviderScope(child: PersonalHavenApp()));
}

class PersonalHavenApp extends StatelessWidget {
  const PersonalHavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Haven',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF4ECDC4),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4ECDC4),
          primary: const Color(0xFF4ECDC4),
        ),
        useMaterial3: true,
      ),
      home: const AppInitializer(),
    );
  }
}
