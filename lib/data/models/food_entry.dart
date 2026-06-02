import 'package:equatable/equatable.dart';

class FoodEntry extends Equatable {
  final String id;
  final String userId;
  final String mealType; // breakfast, lunch, dinner, snack
  final String foodName;
  final String? description;
  final int? calories;
  final int? protein; 
  final int? carbs; 
  final int? fat; 
  final DateTime consumedAt;

  const FoodEntry({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.foodName,
    this.description,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    required this.consumedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'mealType': mealType,
      'foodName': foodName,
      'description': description,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'consumedAt': consumedAt.toIso8601String(),
    };
  }

  static FoodEntry fromFirestore(dynamic doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FoodEntry(
      id: doc.id,
      userId: d['userId'] as String,
      mealType: d['mealType'] as String,
      foodName: d['foodName'] as String,
      description: d['description'] as String?,
      calories: d['calories'] as int?,
      protein: d['protein'] as int?,
      carbs: d['carbs'] as int?,
      fat: d['fat'] as int?,
      consumedAt: DateTime.parse(d['consumedAt'] as String),
    );
  }

  FoodEntry copyWith({
    String? id,
    String? userId,
    String? mealType,
    String? foodName,
    String? description,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    DateTime? consumedAt,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mealType: mealType ?? this.mealType,
      foodName: foodName ?? this.foodName,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      consumedAt: consumedAt ?? this.consumedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'food_entry_id': id,
      'user_id': userId,
      'meal_type': mealType,
      'food_name': foodName,
      'description': description,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'consumed_at': consumedAt.toIso8601String(),
    };
  }

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      id: map['food_entry_id'] as String,
      userId: map['user_id'] as String,
      mealType: map['meal_type'] as String,
      foodName: map['food_name'] as String,
      description: map['description'] as String?,
      calories: map['calories'] as int?,
      protein: map['protein'] as int?,
      carbs: map['carbs'] as int?,
      fat: map['fat'] as int?,
      consumedAt: DateTime.parse(map['consumed_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        mealType,
        foodName,
        description,
        calories,
        protein,
        carbs,
        fat,
        consumedAt,
      ];
}

// ─────────────────────────────────────────────────────────────
// Meal Suggestions - Random food ideas for meal prep
// ─────────────────────────────────────────────────────────────

class MealSuggestion {
  final String name;
  final String emoji;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String mealType;
  final List<String> tags;

  const MealSuggestion({
    required this.name,
    required this.emoji,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealType,
    this.tags = const [],
  });
}

class MealSuggestions {
  // ─────────────────────────────────────────────────────────────
  // BREAKFAST
  // ─────────────────────────────────────────────────────────────
  static const List<MealSuggestion> breakfast = [
    MealSuggestion(
      name: 'Oatmeal with Berries',
      emoji: '🥣',
      calories: 300,
      protein: 10,
      carbs: 54,
      fat: 6,
      mealType: 'breakfast',
      tags: ['healthy', 'fiber', 'quick'],
    ),
    MealSuggestion(
      name: 'Scrambled Eggs & Toast',
      emoji: '🍳',
      calories: 350,
      protein: 20,
      carbs: 25,
      fat: 18,
      mealType: 'breakfast',
      tags: ['protein', 'classic'],
    ),
    MealSuggestion(
      name: 'Greek Yogurt Parfait',
      emoji: '🥛',
      calories: 280,
      protein: 15,
      carbs: 35,
      fat: 8,
      mealType: 'breakfast',
      tags: ['protein', 'quick', 'healthy'],
    ),
    MealSuggestion(
      name: 'Avocado Toast',
      emoji: '🥑',
      calories: 320,
      protein: 8,
      carbs: 30,
      fat: 20,
      mealType: 'breakfast',
      tags: ['trendy', 'healthy fats'],
    ),
    MealSuggestion(
      name: 'Smoothie Bowl',
      emoji: '🫐',
      calories: 350,
      protein: 12,
      carbs: 60,
      fat: 8,
      mealType: 'breakfast',
      tags: ['fruity', 'refreshing'],
    ),
    MealSuggestion(
      name: 'Pancakes',
      emoji: '🥞',
      calories: 450,
      protein: 10,
      carbs: 70,
      fat: 15,
      mealType: 'breakfast',
      tags: ['comfort', 'weekend'],
    ),
    MealSuggestion(
      name: 'Breakfast Burrito',
      emoji: '🌯',
      calories: 500,
      protein: 25,
      carbs: 45,
      fat: 22,
      mealType: 'breakfast',
      tags: ['filling', 'protein'],
    ),
    MealSuggestion(
      name: 'Fruit & Granola',
      emoji: '🍓',
      calories: 280,
      protein: 6,
      carbs: 50,
      fat: 8,
      mealType: 'breakfast',
      tags: ['light', 'quick'],
    ),
    MealSuggestion(
      name: 'Eggs Benedict',
      emoji: '🥚',
      calories: 550,
      protein: 22,
      carbs: 30,
      fat: 35,
      mealType: 'breakfast',
      tags: ['indulgent', 'weekend'],
    ),
    MealSuggestion(
      name: 'Overnight Oats',
      emoji: '🫙',
      calories: 320,
      protein: 12,
      carbs: 55,
      fat: 7,
      mealType: 'breakfast',
      tags: ['meal prep', 'no cook'],
    ),
  ];

  // ─────────────────────────────────────────────────────────────
  // LUNCH
  // ─────────────────────────────────────────────────────────────
  static const List<MealSuggestion> lunch = [
    MealSuggestion(
      name: 'Grilled Chicken Salad',
      emoji: '🥗',
      calories: 400,
      protein: 35,
      carbs: 20,
      fat: 20,
      mealType: 'lunch',
      tags: ['healthy', 'protein', 'low carb'],
    ),
    MealSuggestion(
      name: 'Turkey Sandwich',
      emoji: '🥪',
      calories: 450,
      protein: 28,
      carbs: 40,
      fat: 18,
      mealType: 'lunch',
      tags: ['classic', 'quick'],
    ),
    MealSuggestion(
      name: 'Buddha Bowl',
      emoji: '🥙',
      calories: 480,
      protein: 18,
      carbs: 55,
      fat: 20,
      mealType: 'lunch',
      tags: ['vegetarian', 'healthy'],
    ),
    MealSuggestion(
      name: 'Chicken Wrap',
      emoji: '🌮',
      calories: 420,
      protein: 30,
      carbs: 35,
      fat: 16,
      mealType: 'lunch',
      tags: ['portable', 'protein'],
    ),
    MealSuggestion(
      name: 'Quinoa Bowl',
      emoji: '🍚',
      calories: 450,
      protein: 15,
      carbs: 60,
      fat: 15,
      mealType: 'lunch',
      tags: ['vegetarian', 'protein'],
    ),
    MealSuggestion(
      name: 'Tuna Salad',
      emoji: '🐟',
      calories: 380,
      protein: 32,
      carbs: 15,
      fat: 22,
      mealType: 'lunch',
      tags: ['omega-3', 'low carb'],
    ),
    MealSuggestion(
      name: 'Soup & Bread',
      emoji: '🍲',
      calories: 350,
      protein: 12,
      carbs: 45,
      fat: 12,
      mealType: 'lunch',
      tags: ['comfort', 'warm'],
    ),
    MealSuggestion(
      name: 'Poke Bowl',
      emoji: '🍣',
      calories: 520,
      protein: 30,
      carbs: 55,
      fat: 18,
      mealType: 'lunch',
      tags: ['trendy', 'fresh'],
    ),
    MealSuggestion(
      name: 'Caesar Salad',
      emoji: '🥬',
      calories: 380,
      protein: 20,
      carbs: 18,
      fat: 28,
      mealType: 'lunch',
      tags: ['classic', 'quick'],
    ),
    MealSuggestion(
      name: 'Burrito Bowl',
      emoji: '🌯',
      calories: 550,
      protein: 28,
      carbs: 60,
      fat: 20,
      mealType: 'lunch',
      tags: ['filling', 'customizable'],
    ),
  ];

  // ─────────────────────────────────────────────────────────────
  // DINNER
  // ─────────────────────────────────────────────────────────────
  static const List<MealSuggestion> dinner = [
    MealSuggestion(
      name: 'Grilled Salmon',
      emoji: '🍣',
      calories: 450,
      protein: 40,
      carbs: 10,
      fat: 28,
      mealType: 'dinner',
      tags: ['omega-3', 'protein', 'healthy'],
    ),
    MealSuggestion(
      name: 'Chicken Stir Fry',
      emoji: '🍜',
      calories: 480,
      protein: 35,
      carbs: 40,
      fat: 18,
      mealType: 'dinner',
      tags: ['quick', 'vegetables'],
    ),
    MealSuggestion(
      name: 'Spaghetti Bolognese',
      emoji: '🍝',
      calories: 600,
      protein: 30,
      carbs: 70,
      fat: 20,
      mealType: 'dinner',
      tags: ['comfort', 'classic'],
    ),
    MealSuggestion(
      name: 'Grilled Steak',
      emoji: '🥩',
      calories: 550,
      protein: 45,
      carbs: 5,
      fat: 38,
      mealType: 'dinner',
      tags: ['protein', 'iron'],
    ),
    MealSuggestion(
      name: 'Vegetable Curry',
      emoji: '🍛',
      calories: 420,
      protein: 12,
      carbs: 55,
      fat: 18,
      mealType: 'dinner',
      tags: ['vegetarian', 'spicy'],
    ),
    MealSuggestion(
      name: 'Roast Chicken',
      emoji: '🍗',
      calories: 480,
      protein: 42,
      carbs: 15,
      fat: 28,
      mealType: 'dinner',
      tags: ['classic', 'family'],
    ),
    MealSuggestion(
      name: 'Fish Tacos',
      emoji: '🌮',
      calories: 450,
      protein: 28,
      carbs: 40,
      fat: 20,
      mealType: 'dinner',
      tags: ['fun', 'light'],
    ),
    MealSuggestion(
      name: 'Shrimp Pasta',
      emoji: '🦐',
      calories: 520,
      protein: 30,
      carbs: 55,
      fat: 18,
      mealType: 'dinner',
      tags: ['seafood', 'quick'],
    ),
    MealSuggestion(
      name: 'BBQ Ribs',
      emoji: '🍖',
      calories: 650,
      protein: 38,
      carbs: 25,
      fat: 45,
      mealType: 'dinner',
      tags: ['indulgent', 'weekend'],
    ),
    MealSuggestion(
      name: 'Veggie Burger',
      emoji: '🍔',
      calories: 420,
      protein: 20,
      carbs: 45,
      fat: 18,
      mealType: 'dinner',
      tags: ['vegetarian', 'quick'],
    ),
  ];

  // ─────────────────────────────────────────────────────────────
  // SNACKS
  // ─────────────────────────────────────────────────────────────
  static const List<MealSuggestion> snacks = [
    MealSuggestion(
      name: 'Apple & Peanut Butter',
      emoji: '🍎',
      calories: 200,
      protein: 6,
      carbs: 25,
      fat: 10,
      mealType: 'snack',
      tags: ['healthy', 'quick'],
    ),
    MealSuggestion(
      name: 'Greek Yogurt',
      emoji: '🥛',
      calories: 150,
      protein: 15,
      carbs: 12,
      fat: 4,
      mealType: 'snack',
      tags: ['protein', 'probiotic'],
    ),
    MealSuggestion(
      name: 'Mixed Nuts',
      emoji: '🥜',
      calories: 180,
      protein: 5,
      carbs: 8,
      fat: 16,
      mealType: 'snack',
      tags: ['healthy fats', 'portable'],
    ),
    MealSuggestion(
      name: 'Protein Bar',
      emoji: '🍫',
      calories: 220,
      protein: 20,
      carbs: 22,
      fat: 8,
      mealType: 'snack',
      tags: ['protein', 'convenient'],
    ),
    MealSuggestion(
      name: 'Hummus & Veggies',
      emoji: '🥕',
      calories: 150,
      protein: 5,
      carbs: 18,
      fat: 8,
      mealType: 'snack',
      tags: ['healthy', 'fiber'],
    ),
    MealSuggestion(
      name: 'Cheese & Crackers',
      emoji: '🧀',
      calories: 200,
      protein: 8,
      carbs: 15,
      fat: 12,
      mealType: 'snack',
      tags: ['satisfying', 'calcium'],
    ),
    MealSuggestion(
      name: 'Banana',
      emoji: '🍌',
      calories: 105,
      protein: 1,
      carbs: 27,
      fat: 0,
      mealType: 'snack',
      tags: ['quick', 'energy'],
    ),
    MealSuggestion(
      name: 'Trail Mix',
      emoji: '🥜',
      calories: 175,
      protein: 5,
      carbs: 15,
      fat: 12,
      mealType: 'snack',
      tags: ['energy', 'hiking'],
    ),
    MealSuggestion(
      name: 'Dark Chocolate',
      emoji: '🍫',
      calories: 170,
      protein: 2,
      carbs: 13,
      fat: 12,
      mealType: 'snack',
      tags: ['treat', 'antioxidants'],
    ),
    MealSuggestion(
      name: 'Smoothie',
      emoji: '🥤',
      calories: 200,
      protein: 8,
      carbs: 35,
      fat: 4,
      mealType: 'snack',
      tags: ['refreshing', 'fruity'],
    ),
  ];

  // ─────────────────────────────────────────────────────────────
  // Helper Methods
  // ─────────────────────────────────────────────────────────────

  static List<MealSuggestion> getByMealType(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return breakfast;
      case 'lunch':
        return lunch;
      case 'dinner':
        return dinner;
      case 'snack':
        return snacks;
      default:
        return [];
    }
  }

  static MealSuggestion getRandomSuggestion(String mealType) {
  final suggestions = List.of(getByMealType(mealType)); 
  if (suggestions.isEmpty) return breakfast.first;
  suggestions.shuffle();
  return suggestions.first;
}

  static List<MealSuggestion> getRandomSuggestions(String mealType, {int count = 3}) {
    final suggestions = List<MealSuggestion>.from(getByMealType(mealType));
    suggestions.shuffle();
    return suggestions.take(count).toList();
  }

  static List<MealSuggestion> getDailyMealPlan() {
    return [
      getRandomSuggestion('breakfast'),
      getRandomSuggestion('lunch'),
      getRandomSuggestion('dinner'),
      getRandomSuggestion('snack'),
    ];
  }

  static List<MealSuggestion> getLowCalorieSuggestions(String mealType, {int maxCalories = 400}) {
    return getByMealType(mealType)
        .where((s) => s.calories <= maxCalories)
        .toList();
  }

  static List<MealSuggestion> getHighProteinSuggestions(String mealType, {int minProtein = 20}) {
    return getByMealType(mealType)
        .where((s) => s.protein >= minProtein)
        .toList();
  }
}