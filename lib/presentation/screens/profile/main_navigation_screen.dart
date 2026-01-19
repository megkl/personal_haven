import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/presentation/screens/home/home_screen.dart';
import 'package:personal_haven/presentation/screens/journal/add_entry_screen.dart';
import 'package:personal_haven/presentation/screens/journal/journal_screen.dart';
import 'package:personal_haven/presentation/screens/profile/profile_screen.dart';
import 'package:personal_haven/presentation/screens/rituals/rituals_screen.dart';
import 'package:personal_haven/presentation/screens/wellness/wellness_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const JournalScreen(),
    const WellnessScreen(),
    const RitualsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      // floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
      //     ? FloatingActionButton(
      //         onPressed: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (_) => const AddJournalEntryScreen()),
      //           );
      //         },
      //         backgroundColor: const Color(0xFF4ECDC4),
      //         child: const Icon(Icons.add, color: Colors.white, size: 32),
      //       )
      //     : null,
      // floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      
      bottomNavigationBar: BottomAppBar(
        height: const Size.fromHeight(70).height,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', 0),
            _buildNavItem(Icons.book, 'Journal', 1),
            //const SizedBox(width: 40),
            _buildNavItem(Icons.rice_bowl, 'Rituals', 3),
            _buildNavItem(Icons.spa, 'Wellness', 2),
            _buildNavItem(Icons.person, 'Profile', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF4ECDC4) : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFF4ECDC4) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}