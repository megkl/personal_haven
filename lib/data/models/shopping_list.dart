import 'package:equatable/equatable.dart';

class ShoppingItem extends Equatable {
  final String id;
  final String name;
  final String quantity;
  final String category;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.quantity = '',
    this.category = 'other',
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? quantity,
    String? category,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'category': category,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    quantity,
    category,
    isCompleted,
    createdAt,
    completedAt,
  ];
}

class ShoppingList extends Equatable {
  final String id;
  final String userId;
  final String title;
  final List<ShoppingItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShoppingList({
    required this.id,
    required this.userId,
    required this.title,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  int get completedCount => items.where((item) => item.isCompleted).length;
  int get pendingCount => items.length - completedCount;

  Map<String, List<ShoppingItem>> get itemsByCategory {
    final grouped = <String, List<ShoppingItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }

  ShoppingList copyWith({
    String? id,
    String? userId,
    String? title,
    List<ShoppingItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'title': title,
    'items': items.map((item) => item.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ShoppingList.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingList.fromJson({...data, 'id': doc.id});
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      items: json['items'] is List
          ? (json['items'] as List)
                .whereType<Map>()
                .map(
                  (item) =>
                      ShoppingItem.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, userId, title, items, createdAt, updatedAt];
}
