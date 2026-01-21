import 'package:equatable/equatable.dart';

class FoodEntry extends Equatable {
  final String id;
  final String userId;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final String foodName;
  final String? description;
  final int? calories;
  final DateTime consumedAt;
  final String? imageUrl;
  final Map<String, dynamic>? nutrition; // protein, carbs, fats, etc.

  const FoodEntry({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.foodName,
    this.description,
    this.calories,
    required this.consumedAt,
    this.imageUrl,
    this.nutrition,
  });

  FoodEntry copyWith({
    String? id,
    String? userId,
    String? mealType,
    String? foodName,
    String? description,
    int? calories,
    DateTime? consumedAt,
    String? imageUrl,
    Map<String, dynamic>? nutrition,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mealType: mealType ?? this.mealType,
      foodName: foodName ?? this.foodName,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      consumedAt: consumedAt ?? this.consumedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      nutrition: nutrition ?? this.nutrition,
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
      'consumed_at': consumedAt.toIso8601String(),
      'image_url': imageUrl,
      'nutrition_json': nutrition?.toString(),
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
      consumedAt: DateTime.parse(map['consumed_at'] as String),
      imageUrl: map['image_url'] as String?,
      nutrition: null, // Parse JSON if needed
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
        consumedAt,
        imageUrl,
        nutrition,
      ];
}
