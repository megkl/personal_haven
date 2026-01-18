import 'package:flutter/material.dart';
import 'package:personal_haven/presentation/screens/auth/signup_screen.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final Set<String> _selectedInterests = {};

  final List<Map<String, dynamic>> _interests = [
    {'icon': Icons.edit, 'label': 'Journaling &\nSelf-Reflection'},
    {'icon': Icons.psychology, 'label': 'Mental'},
    {'icon': Icons.self_improvement, 'label': 'Mental Wellness'},
    {'icon': Icons.bolt, 'label': 'Building New Habits'},
    {'icon': Icons.spa, 'label': 'Stress & Calm'},
    {'icon': Icons.spa, 'label': 'Stress & Calm'},
    {'icon': Icons.eco, 'label': 'Personal Growth'},
    {'icon': Icons.bar_chart, 'label': 'Finance & Goals'},
    {'icon': Icons.restaurant, 'label': 'Health & Nutrition'},
    {'icon': Icons.favorite, 'label': 'Mood Tracking'},
  ];

  Future<void> _continue() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6E3),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.spa, color: Colors.white.withOpacity(0.9)),
                const SizedBox(width: 8),
                const Text(
                  'Personal Haven',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3E40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              'What brings you here?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3E40),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Help us tailor your haven.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF2D3E40),
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: _interests.length,
                itemBuilder: (context, index) {
                  final interest = _interests[index];
                  final isSelected = _selectedInterests.contains(interest['label']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedInterests.remove(interest['label']);
                        } else {
                          _selectedInterests.add(interest['label']);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF4ECDC4)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            interest['icon'],
                            size: 36,
                            color: const Color(0xFF4ECDC4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            interest['label'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2D3E40),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _continue,
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(
                        color: Color(0xFF2D3E40),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ECDC4),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}