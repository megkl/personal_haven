import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/shopping_list.dart';
import 'package:personal_haven/data/repositories/shopping_list_repository.dart';
import 'package:personal_haven/providers/auth_provider.dart';

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return ShoppingListRepository();
});

final shoppingListProvider =
    NotifierProvider<ShoppingListNotifier, ShoppingListState>(
      ShoppingListNotifier.new,
    );

class ShoppingListState {
  final List<ShoppingList> lists;
  final String? selectedListId;
  final bool isLoading;
  final String? error;

  const ShoppingListState({
    this.lists = const [],
    this.selectedListId,
    this.isLoading = false,
    this.error,
  });

  ShoppingList? get selectedList {
    if (lists.isEmpty) return null;
    if (selectedListId == null) return lists.first;
    for (final list in lists) {
      if (list.id == selectedListId) return list;
    }
    return lists.first;
  }

  ShoppingListState copyWith({
    List<ShoppingList>? lists,
    String? selectedListId,
    bool? isLoading,
    String? error,
  }) {
    return ShoppingListState(
      lists: lists ?? this.lists,
      selectedListId: selectedListId ?? this.selectedListId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ShoppingListNotifier extends Notifier<ShoppingListState> {
  ShoppingListRepository get _repo => ref.read(shoppingListRepositoryProvider);
  String get _userId => ref.read(currentUserIdProvider);

  @override
  ShoppingListState build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId.isNotEmpty) {
      Future.microtask(loadLists);
    }
    return const ShoppingListState();
  }

  Future<void> loadLists() async {
    if (_userId.isEmpty) {
      state = const ShoppingListState(isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final lists = await _repo.getLists(_userId);
      state = ShoppingListState(
        lists: lists,
        selectedListId:
            state.selectedListId ?? (lists.isEmpty ? null : lists.first.id),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectList(String listId) {
    state = state.copyWith(selectedListId: listId);
  }

  Future<ShoppingList> createList(String title) async {
    final list = await _repo.createList(userId: _userId, title: title);
    state = state.copyWith(
      lists: [list, ...state.lists],
      selectedListId: list.id,
      error: null,
    );
    return list;
  }

  Future<void> addItem({
    String? listId,
    String? listTitle,
    required String name,
    String quantity = '',
  }) async {
    ShoppingList? target = listId == null
        ? _listByTitle(listTitle) ?? state.selectedList
        : _listById(listId);
    target ??= await createList(listTitle ?? 'Shopping list');
    final updated = await _repo.addItem(
      list: target,
      name: name,
      quantity: quantity,
    );
    _replaceList(updated);
  }

  Future<void> toggleItem(ShoppingList list, ShoppingItem item) async {
    final updated = await _repo.toggleItem(list: list, item: item);
    _replaceList(updated);
  }

  Future<void> renameList(ShoppingList list, String title) async {
    final updated = await _repo.renameList(list: list, title: title);
    _replaceList(updated);
  }

  Future<void> deleteItem(ShoppingList list, ShoppingItem item) async {
    await _repo.deleteItem(list: list, item: item);
    final updated = list.copyWith(
      items: list.items.where((current) => current.id != item.id).toList(),
      updatedAt: DateTime.now(),
    );
    _replaceList(updated);
  }

  Future<void> clearCompleted(ShoppingList list) async {
    await _repo.clearCompleted(list);
    final updated = list.copyWith(
      items: list.items.where((item) => !item.isCompleted).toList(),
      updatedAt: DateTime.now(),
    );
    _replaceList(updated);
  }

  Future<void> clearAllItems(ShoppingList list) async {
    final updated = await _repo.clearAllItems(list);
    _replaceList(updated);
  }

  Future<void> deleteList(ShoppingList list) async {
    await _repo.deleteList(_userId, list.id);
    final next = state.lists.where((current) => current.id != list.id).toList();
    state = state.copyWith(
      lists: next,
      selectedListId: next.isEmpty ? null : next.first.id,
      error: null,
    );
  }

  ShoppingList? _listById(String listId) {
    for (final list in state.lists) {
      if (list.id == listId) return list;
    }
    return null;
  }

  ShoppingList? _listByTitle(String? title) {
    if (title == null || title.trim().isEmpty) return null;
    final normalized = title.toLowerCase().trim();
    for (final list in state.lists) {
      if (list.title.toLowerCase().trim() == normalized) return list;
    }
    return null;
  }

  void _replaceList(ShoppingList updated) {
    final lists = state.lists.map((list) {
      return list.id == updated.id ? updated : list;
    }).toList();
    if (!lists.any((list) => list.id == updated.id)) {
      lists.insert(0, updated);
    }
    lists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = state.copyWith(
      lists: lists,
      selectedListId: updated.id,
      error: null,
    );
  }
}
