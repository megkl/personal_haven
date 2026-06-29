import 'package:flutter/material.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/core/constants/app_colors.dart';

class AffirmationsScreen extends StatefulWidget {
  const AffirmationsScreen({super.key});

  @override
  State<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends State<AffirmationsScreen> {
  final List<Map<String, dynamic>> _affirmations = [
    {
      'text': 'You are capable of amazing things',
      'category': 'Motivation',
      'isFavorite': true,
    },
    {
      'text': 'Every day is a fresh start',
      'category': 'Positivity',
      'isFavorite': false,
    },
    {
      'text': 'I am worthy of love and respect',
      'category': 'Self-Love',
      'isFavorite': true,
    },
    {
      'text': 'I choose peace and calmness',
      'category': 'Wellness',
      'isFavorite': false,
    },
    {
      'text': 'My potential is limitless',
      'category': 'Motivation',
      'isFavorite': false,
    },
  ];

  String _selectedCategory = 'All';
  bool _showFavoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final filteredAffirmations = _getFilteredAffirmations();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildDailyAffirmation(),
          _buildFilterBar(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredAffirmations.length,
              itemBuilder: (context, index) {
                return _buildAffirmationCard(
                  filteredAffirmations[index],
                  index,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'affirmations_add',
        onPressed: () {
          _showAddAffirmationDialog();
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDailyAffirmation() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                "Today's Affirmation",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '"You are capable of amazing things"',
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.share, color: Colors.white),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.favorite_border, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final categories = [
      'All',
      'Motivation',
      'Positivity',
      'Self-Love',
      'Wellness',
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Affirmations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              FilterChip(
                label: Text('Favorites'),
                selected: _showFavoritesOnly,
                onSelected: (selected) {
                  setState(() => _showFavoritesOnly = selected);
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _showFavoritesOnly
                      ? Colors.white
                      : context.colors.textPrimary,
                ),
                avatar: Icon(
                  Icons.favorite,
                  size: 16,
                  color: _showFavoritesOnly
                      ? Colors.white
                      : context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategory == category;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                  backgroundColor: context.colors.cardColor,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : context.colors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAffirmationCard(Map<String, dynamic> affirmation, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.colors.divider,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  affirmation['category'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  affirmation['isFavorite'] as bool
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: affirmation['isFavorite'] as bool
                      ? Colors.red
                      : context.colors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    affirmation['isFavorite'] = !affirmation['isFavorite'];
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            affirmation['text'] as String,
            style: TextStyle(
              fontSize: 16,
              color: context.colors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredAffirmations() {
    var filtered = _affirmations;

    if (_showFavoritesOnly) {
      filtered = filtered.where((a) => a['isFavorite'] == true).toList();
    }

    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((a) => a['category'] == _selectedCategory)
          .toList();
    }

    return filtered;
  }

  void _showAddAffirmationDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add affirmation feature coming soon')),
    );
  }
}
