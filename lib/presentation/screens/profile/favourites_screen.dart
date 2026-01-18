import 'package:flutter/material.dart';
import 'package:personal_haven/core/constants/app_colors.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final Map<String, dynamic> _favorites = {
    'colors': ['#4ECDC4', '#CD8B76', '#FFD700'],
    'music': 'Lo-fi Beats',
    'food': 'Sushi, Pasta',
    'scent': 'Lavender',
    'activity': 'Reading, Yoga',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildFavoriteCard(
            'Favorite Colors',
            Icons.palette,
            _buildColorsList(),
          ),
          const SizedBox(height: 16),
          _buildFavoriteCard(
            'Favorite Music',
            Icons.music_note,
            Text(_favorites['music'], style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),
          _buildFavoriteCard(
            'Favorite Foods',
            Icons.restaurant,
            Text(_favorites['food'], style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),
          _buildFavoriteCard(
            'Favorite Scent',
            Icons.spa,
            Text(_favorites['scent'], style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),
          _buildFavoriteCard(
            'Favorite Activity',
            Icons.favorite,
            Text(_favorites['activity'], style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(String title, IconData icon, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildColorsList() {
    return Wrap(
      spacing: 12,
      children: (_favorites['colors'] as List<String>).map((color) {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
        );
      }).toList(),
    );
  }
}

