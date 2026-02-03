import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/data/models/food_entry.dart';
import 'package:personal_haven/providers/food_provider.dart';

class FoodDiaryScreen extends ConsumerStatefulWidget {
  const FoodDiaryScreen({super.key});

  @override
  ConsumerState<FoodDiaryScreen> createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends ConsumerState<FoodDiaryScreen> {
  int _calorieGoal = 2000;

  @override
  Widget build(BuildContext context) {
    final foodState = ref.watch(foodProvider);
    final todayCalories = foodState.todayCalories;

    // Group entries by meal type
    final breakfast =
        foodState.entries.where((e) => e.mealType == 'breakfast').toList();
    final lunch =
        foodState.entries.where((e) => e.mealType == 'lunch').toList();
    final dinner =
        foodState.entries.where((e) => e.mealType == 'dinner').toList();
    final snacks =
        foodState.entries.where((e) => e.mealType == 'snack').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: foodState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalorieCard(todayCalories, foodState),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(foodProvider.notifier).loadEntries();
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Meal Prep Suggestions
                        _buildMealSuggestions(context, ref),
                        const SizedBox(height: 16),

                        // Meal sections
                        _buildMealSection(
                          context,
                          ref,
                          '🌅 Breakfast',
                          breakfast,
                          'breakfast',
                        ),
                        const SizedBox(height: 16),
                        _buildMealSection(
                          context,
                          ref,
                          '☀️ Lunch',
                          lunch,
                          'lunch',
                        ),
                        const SizedBox(height: 16),
                        _buildMealSection(
                          context,
                          ref,
                          '🌙 Dinner',
                          dinner,
                          'dinner',
                        ),
                        const SizedBox(height: 16),
                        _buildMealSection(
                          context,
                          ref,
                          '🍎 Snacks',
                          snacks,
                          'snack',
                        ),
                        const SizedBox(height: 80),
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

  Widget _buildCalorieCard(int todayCalories, FoodState foodState) {
    final percentage = (todayCalories / _calorieGoal * 100).clamp(0, 100);
    final remaining = _calorieGoal - todayCalories;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: remaining >= 0
              ? [const Color(0xFF4ECDC4), const Color(0xFF44A3AA)]
              : [Colors.orange.shade400, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ECDC4).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today\'s Calories',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$todayCalories',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 4),
                          child: Text(
                            '/ $_calorieGoal',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      remaining >= 0
                          ? '$remaining cal remaining'
                          : '${remaining.abs()} cal over',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress circle
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${percentage.toInt()}%',
                        style: const TextStyle(
                          fontSize: 18,
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
          const SizedBox(height: 16),
          // Macros row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroItem('Protein', '${foodState.todayProtein}g', '🥩'),
              _buildMacroItem('Carbs', '${foodState.todayCarbs}g', '🍞'),
              _buildMacroItem('Fat', '${foodState.todayFat}g', '🥑'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MEAL SUGGESTIONS
  // ─────────────────────────────────────────────────────────────

  Widget _buildMealSuggestions(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('💡', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    'Meal Ideas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3E40),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => setState(() {}), // Refresh suggestions
                child: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildSuggestionCard(
                  context,
                  ref,
                  MealSuggestions.getRandomSuggestion('breakfast'),
                ),
                _buildSuggestionCard(
                  context,
                  ref,
                  MealSuggestions.getRandomSuggestion('lunch'),
                ),
                _buildSuggestionCard(
                  context,
                  ref,
                  MealSuggestions.getRandomSuggestion('dinner'),
                ),
                _buildSuggestionCard(
                  context,
                  ref,
                  MealSuggestions.getRandomSuggestion('snack'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    WidgetRef ref,
    MealSuggestion suggestion,
  ) {
    return GestureDetector(
      onTap: () => _addFromSuggestion(context, ref, suggestion),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getMealTypeColor(suggestion.mealType).withOpacity(0.1),
              _getMealTypeColor(suggestion.mealType).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getMealTypeColor(suggestion.mealType).withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(suggestion.emoji, style: const TextStyle(fontSize: 24)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getMealTypeColor(suggestion.mealType),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    suggestion.mealType[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3E40),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              '${suggestion.calories} cal',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getMealTypeColor(suggestion.mealType),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.purple;
      case 'snack':
        return Colors.pink;
      default:
        return AppColors.primary;
    }
  }

  void _addFromSuggestion(
    BuildContext context,
    WidgetRef ref,
    MealSuggestion suggestion,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(suggestion.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                suggestion.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNutritionRow('Calories', '${suggestion.calories}', 'cal'),
            _buildNutritionRow('Protein', '${suggestion.protein}', 'g'),
            _buildNutritionRow('Carbs', '${suggestion.carbs}', 'g'),
            _buildNutritionRow('Fat', '${suggestion.fat}', 'g'),
            const SizedBox(height: 12),
            if (suggestion.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: suggestion.tags
                    .map((tag) => Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 11),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(foodProvider.notifier).addEntry(
                    mealType: suggestion.mealType,
                    foodName: suggestion.name,
                    calories: suggestion.calories,
                    protein: suggestion.protein,
                    carbs: suggestion.carbs,
                    fat: suggestion.fat,
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added ${suggestion.name}!'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getMealTypeColor(suggestion.mealType),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            '$value $unit',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MEAL SECTIONS
  // ─────────────────────────────────────────────────────────────

  Widget _buildMealSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<FoodEntry> entries,
    String mealType,
  ) {
    int totalCalories = 0;
    for (final entry in entries) {
      totalCalories += entry.calories ?? 0;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  color: Color(0xFF2D3E40),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getMealTypeColor(mealType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalCalories cal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getMealTypeColor(mealType),
                  ),
                ),
              ),
            ],
          ),
          if (entries.isEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  // Show random suggestion
                  _buildInlineSuggestion(context, ref, mealType),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () =>
                        _showAddFoodDialog(context, ref, mealType: mealType),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Add custom'),
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ...entries.map((entry) => _buildFoodItem(context, ref, entry)),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () =>
                    _showAddFoodDialog(context, ref, mealType: mealType),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add more'),
                style:
                    TextButton.styleFrom(foregroundColor: _getMealTypeColor(mealType)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineSuggestion(
      BuildContext context, WidgetRef ref, String mealType) {
    final suggestion = MealSuggestions.getRandomSuggestion(mealType);

    return GestureDetector(
      onTap: () => _addFromSuggestion(context, ref, suggestion),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getMealTypeColor(mealType).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getMealTypeColor(mealType).withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(suggestion.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Try this?',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  suggestion.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              '${suggestion.calories} cal',
              style: TextStyle(
                fontSize: 12,
                color: _getMealTypeColor(mealType),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.add_circle,
              color: _getMealTypeColor(mealType),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItem(
      BuildContext context, WidgetRef ref, FoodEntry entry) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) {
        ref.read(foodProvider.notifier).deleteEntry(entry.id);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getMealTypeColor(entry.mealType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('🍽️', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.foodName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (entry.protein != null || entry.carbs != null)
                    Text(
                      'P: ${entry.protein ?? 0}g • C: ${entry.carbs ?? 0}g • F: ${entry.fat ?? 0}g',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${entry.calories ?? 0} cal',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3E40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ADD FOOD DIALOG
  // ─────────────────────────────────────────────────────────────

  void _showAddFoodDialog(BuildContext context, WidgetRef ref,
      {String? mealType}) {
    final foodController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    String selectedMealType = mealType ?? 'breakfast';
    bool showMacros = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add ${_getMealTypeEmoji(selectedMealType)} Food'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: foodController,
                  decoration: InputDecoration(
                    labelText: 'Food name',
                    hintText: 'e.g., Oatmeal with berries',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: caloriesController,
                  decoration: InputDecoration(
                    labelText: 'Calories',
                    hintText: 'e.g., 300',
                    suffixText: 'cal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                if (mealType == null)
                  DropdownButtonFormField<String>(
                    value: selectedMealType,
                    decoration: InputDecoration(
                      labelText: 'Meal type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'breakfast', child: Text('🌅 Breakfast')),
                      DropdownMenuItem(value: 'lunch', child: Text('☀️ Lunch')),
                      DropdownMenuItem(
                          value: 'dinner', child: Text('🌙 Dinner')),
                      DropdownMenuItem(value: 'snack', child: Text('🍎 Snack')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedMealType = value);
                      }
                    },
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => showMacros = !showMacros),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        showMacros
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(showMacros ? 'Hide macros' : 'Add macros'),
                    ],
                  ),
                ),
                if (showMacros) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: proteinController,
                          decoration: InputDecoration(
                            labelText: 'Protein',
                            suffixText: 'g',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: carbsController,
                          decoration: InputDecoration(
                            labelText: 'Carbs',
                            suffixText: 'g',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: fatController,
                          decoration: InputDecoration(
                            labelText: 'Fat',
                            suffixText: 'g',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
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
                        foodName: foodController.text.trim(),
                        calories: int.tryParse(caloriesController.text),
                        protein: int.tryParse(proteinController.text),
                        carbs: int.tryParse(carbsController.text),
                        fat: int.tryParse(fatController.text),
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${foodController.text}!'),
                      backgroundColor: _getMealTypeColor(selectedMealType),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getMealTypeColor(selectedMealType),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  String _getMealTypeEmoji(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '☀️';
      case 'dinner':
        return '🌙';
      case 'snack':
        return '🍎';
      default:
        return '🍽️';
    }
  }
}