import 'package:personal_haven/data/models/shopping_list.dart';
import 'package:personal_haven/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class ShoppingListRepository {
  final _fs = FirestoreService.instance;
  final _uuid = const Uuid();
  static const _col = 'shopping_lists';

  Future<List<ShoppingList>> getLists(String userId) async {
    final snap = await _fs.query(
      userId,
      _col,
      (c) => c.orderBy('updatedAt', descending: true),
    );
    return snap.docs.map((doc) => ShoppingList.fromFirestore(doc)).toList();
  }

  Future<ShoppingList> createList({
    required String userId,
    required String title,
  }) async {
    final now = DateTime.now();
    final list = ShoppingList(
      id: _uuid.v4(),
      userId: userId,
      title: title.trim().isEmpty ? 'Shopping list' : title.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await _fs.set(userId, _col, list.id, list.toFirestore());
    return list;
  }

  Future<ShoppingList> addItem({
    required ShoppingList list,
    required String name,
    String quantity = '',
    String? category,
  }) async {
    final now = DateTime.now();
    final item = ShoppingItem(
      id: _uuid.v4(),
      name: _titleCase(name.trim()),
      quantity: quantity.trim(),
      category: category ?? categoryForItem(name),
      createdAt: now,
    );
    final updated = list.copyWith(items: [item, ...list.items], updatedAt: now);
    await _fs.set(list.userId, _col, list.id, updated.toFirestore());
    return updated;
  }

  Future<ShoppingList> toggleItem({
    required ShoppingList list,
    required ShoppingItem item,
  }) async {
    final now = DateTime.now();
    final updatedItems = list.items.map((current) {
      if (current.id != item.id) return current;
      final isCompleted = !current.isCompleted;
      return current.copyWith(
        isCompleted: isCompleted,
        completedAt: isCompleted ? now : null,
      );
    }).toList();
    final updated = list.copyWith(items: updatedItems, updatedAt: now);
    await _fs.set(list.userId, _col, list.id, updated.toFirestore());
    return updated;
  }

  Future<ShoppingList> renameList({
    required ShoppingList list,
    required String title,
  }) async {
    final updated = list.copyWith(
      title: title.trim().isEmpty ? list.title : title.trim(),
      updatedAt: DateTime.now(),
    );
    await _fs.set(list.userId, _col, list.id, updated.toFirestore());
    return updated;
  }

  Future<void> deleteItem({
    required ShoppingList list,
    required ShoppingItem item,
  }) async {
    final updated = list.copyWith(
      items: list.items.where((current) => current.id != item.id).toList(),
      updatedAt: DateTime.now(),
    );
    await _fs.set(list.userId, _col, list.id, updated.toFirestore());
  }

  Future<void> deleteList(String userId, String listId) async {
    await _fs.delete(userId, _col, listId);
  }

  Future<void> clearCompleted(ShoppingList list) async {
    final updated = list.copyWith(
      items: list.items.where((item) => !item.isCompleted).toList(),
      updatedAt: DateTime.now(),
    );
    await _fs.set(list.userId, _col, list.id, updated.toFirestore());
  }

  Future<ShoppingList> clearAllItems(ShoppingList list) async {
    final updated = list.copyWith(items: const [], updatedAt: DateTime.now());
    await _fs.set(list.userId, _col, list.id, updated.toFirestore());
    return updated;
  }

  static String categoryForItem(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('milk') ||
        lower.contains('butter') ||
        lower.contains('cheese') ||
        lower.contains('yogurt') ||
        lower.contains('cream')) {
      return 'dairy';
    }
    if (lower.contains('bread') ||
        lower.contains('muffin') ||
        lower.contains('cake') ||
        lower.contains('croissant') ||
        lower.contains('bagel')) {
      return 'bakery';
    }
    if (lower.contains('coffee') ||
        lower.contains('juice') ||
        lower.contains('tea') ||
        lower.contains('water') ||
        lower.contains('soda')) {
      return 'drinks';
    }
    if (lower.contains('egg') ||
        lower.contains('chicken') ||
        lower.contains('beef') ||
        lower.contains('fish')) {
      return 'protein';
    }
    if (lower.contains('apple') ||
        lower.contains('banana') ||
        lower.contains('orange') ||
        lower.contains('tomato') ||
        lower.contains('lettuce') ||
        lower.contains('onion')) {
      return 'produce';
    }
    return 'other';
  }

  static String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
