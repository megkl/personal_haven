import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/providers/food_provider.dart';

class FoodDiaryScreen extends ConsumerWidget {
  const FoodDiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodState = ref.watch(foodProvider);
    final todayCalories = foodState.todayCalories;

    // Group entries by meal type
    final breakfast = foodState.entries.where((e) => e.mealType == 'breakfast').toList();
    final lunch = foodState.entries.where((e) => e.mealType == 'lunch').toList();
    final dinner = foodState.entries.where((e) => e.mealType == 'dinner').toList();
    final snacks = foodState.entries.where((e) => e.mealType == 'snack').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: foodState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalorieCard(todayCalories),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(foodProvider.notifier).loadEntries();
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildMealSection(context, ref, '🌅 Breakfast', breakfast, 'breakfast'),
                        const SizedBox(height: 16),
                        _buildMealSection(context, ref, '☀️ Lunch', lunch, 'lunch'),
                        const SizedBox(height: 16),
                        _buildMealSection(context, ref, '🌙 Dinner', dinner, 'dinner'),
                        const SizedBox(height: 16),
                        _buildMealSection(context, ref, '🍎 Snacks', snacks, 'snack'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFoodDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCalorieCard(int todayCalories) {
    final calorieGoal = 2000;
    final percentage = (todayCalories / calorieGoal * 100).clamp(0, 100).toInt();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Calories',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$todayCalories / $calorieGoal',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${calorieGoal - todayCalories} remaining',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    List entries,
    String mealType,
  ) {
    final totalCalories = entries.fold(0, (sum, entry) => sum);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$totalCalories cal',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (entries.isEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => _showAddFoodDialog(context, ref, mealType: mealType),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Add food'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ...entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.foodName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (entry.description != null)
                              Text(
                                entry.description!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${entry.calories ?? 0} cal',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () {
                          ref.read(foodProvider.notifier).deleteEntry(entry.id);
                        },
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  void _showAddFoodDialog(BuildContext context, WidgetRef ref, {String? mealType}) {
    final foodController = TextEditingController();
    final caloriesController = TextEditingController();
    String selectedMealType = mealType ?? 'breakfast';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Food'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: foodController,
              decoration: const InputDecoration(
                labelText: 'Food name',
                hintText: 'e.g., Oatmeal',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories',
                hintText: 'e.g., 300',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            if (mealType == null)
              DropdownButtonFormField<String>(
                value: selectedMealType,
                decoration: const InputDecoration(labelText: 'Meal type'),
                items: const [
                  DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
                  DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                  DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                  DropdownMenuItem(value: 'snack', child: Text('Snack')),
                ],
                onChanged: (value) {
                  if (value != null) selectedMealType = value;
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (foodController.text.isNotEmpty) {
                ref.read(foodProvider.notifier).addEntry(
                      mealType: selectedMealType,
                      foodName: foodController.text,
                      calories: int.tryParse(caloriesController.text),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

