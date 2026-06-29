import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/data/models/shopping_list.dart';
import 'package:personal_haven/data/repositories/shopping_list_repository.dart';
import 'package:personal_haven/providers/shopping_list_provider.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shoppingListProvider);
    final list = state.selectedList;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : list == null
          ? _EmptyShoppingState(
              onCreate: () => _showCreateListSheet(context, ref),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ListSelector(state: state, selected: list),
                        const SizedBox(height: 14),
                        _ShoppingHeader(list: list),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  sliver: _ShoppingSections(list: list),
                ),
              ],
            ),
      floatingActionButton: list == null
          ? null
          : FloatingActionButton(
              heroTag: 'rituals_shopping_add',
              tooltip: 'Add shopping item',
              onPressed: () => _showAddItemSheet(context, ref, list),
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              elevation: 6,
              child: const Icon(
                Icons.add_shopping_cart_rounded,
                color: Colors.white,
              ),
            ),
    );
  }

  static Future<void> _showCreateListSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CreateListSheet(ref: ref),
    );
  }

  static Future<void> _showAddItemSheet(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddItemSheet(ref: ref, list: list),
    );
  }
}

class _ListSelector extends ConsumerWidget {
  const _ListSelector({required this.state, required this.selected});

  final ShoppingListState state;
  final ShoppingList selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.lists.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final list = state.lists[index];
                final isSelected = list.id == selected.id;
                return ChoiceChip(
                  selected: isSelected,
                  label: Text(list.title),
                  avatar: Icon(
                    Icons.shopping_basket_outlined,
                    size: 17,
                    color: isSelected ? Colors.white : AppColors.primaryDark,
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: context.isDark
                      ? context.colors.cardColor2
                      : AppColors.primaryLight.withValues(alpha: 0.22),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.22),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : context.colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  onSelected: (_) => ref
                      .read(shoppingListProvider.notifier)
                      .selectList(list.id),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'New list',
          onPressed: () =>
              ShoppingListScreen._showCreateListSheet(context, ref),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.14),
            foregroundColor: AppColors.primaryDark,
          ),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _CreateListSheet extends StatefulWidget {
  const _CreateListSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_CreateListSheet> createState() => _CreateListSheetState();
}

class _CreateListSheetState extends State<_CreateListSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'New shopping list',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'List name',
              prefixIcon: Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Tooltip(
              message: 'Create shopping list',
              child: ElevatedButton(
                onPressed: () {
                  widget.ref
                      .read(shoppingListProvider.notifier)
                      .createList(_controller.text);
                  Navigator.pop(context);
                },
                child: const Text('Create list'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet({required this.ref, required this.list});

  final WidgetRef ref;
  final ShoppingList list;

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  late final TextEditingController _itemController;
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _itemController = TextEditingController();
    _quantityController = TextEditingController();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Add item',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _itemController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Item',
              prefixIcon: Icon(Icons.local_grocery_store_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              hintText: '1 ct, 1 gal, 500 g',
              prefixIcon: Icon(Icons.scale_outlined),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Tooltip(
              message: 'Add item to shopping list',
              child: ElevatedButton(
                onPressed: () {
                  final name = _itemController.text.trim();
                  if (name.isEmpty) return;
                  widget.ref
                      .read(shoppingListProvider.notifier)
                      .addItem(
                        listId: widget.list.id,
                        name: name,
                        quantity: _quantityController.text,
                      );
                  Navigator.pop(context);
                },
                child: const Text('Add to list'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShoppingHeader extends ConsumerWidget {
  const _ShoppingHeader({required this.list});

  final ShoppingList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = list.items.isEmpty
        ? 0.0
        : list.completedCount / list.items.length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDark
              ? [context.colors.cardColor2, context.colors.cardColor]
              : [
                  const Color(0xFFFFFFFF),
                  AppColors.primaryLight.withValues(alpha: 0.35),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.isDark
              ? context.colors.divider
              : AppColors.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.18 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shopping_basket_rounded,
                  color: AppColors.primaryDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _progressMessage(list),
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'List options',
                icon: Icon(
                  Icons.more_horiz,
                  color: context.colors.textSecondary,
                ),
                onSelected: (value) {
                  if (value == 'clear') {
                    ref
                        .read(shoppingListProvider.notifier)
                        .clearCompleted(list);
                  }
                  if (value == 'clear_all') {
                    ref.read(shoppingListProvider.notifier).clearAllItems(list);
                  }
                  if (value == 'delete') {
                    ref.read(shoppingListProvider.notifier).deleteList(list);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'clear', child: Text('Clear completed')),
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Text('Clear all items'),
                  ),
                  PopupMenuItem(value: 'delete', child: Text('Delete list')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 6),
                Text(
                  '${list.completedCount} checked  •  ${list.pendingCount} left',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: Colors.white.withValues(
                alpha: context.isDark ? 0.08 : 0.75,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1 ? AppColors.success : AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _progressMessage(ShoppingList list) {
    if (list.items.isEmpty) return 'Ready for your first item';
    if (list.pendingCount == 0) return 'All packed and checked';
    if (list.completedCount == 0) return 'Tap circles as you shop';
    if (list.pendingCount <= 2) return 'Almost done';
    return 'Nice, the list is moving';
  }
}

class _ShoppingSections extends ConsumerWidget {
  const _ShoppingSections({required this.list});

  final ShoppingList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (list.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyItemsCard(listTitle: list.title),
      );
    }

    final grouped = list.itemsByCategory.entries.toList()
      ..sort((a, b) => _categoryOrder(a.key).compareTo(_categoryOrder(b.key)));

    return SliverList.separated(
      itemCount: grouped.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, sectionIndex) {
        final section = grouped[sectionIndex];
        final style = _ShoppingCategoryStyle.forCategory(section.key, context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 9),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: style.tint,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(style.icon, color: style.color, size: 17),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _categoryLabel(section.key),
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: style.tint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${section.value.length}',
                      style: TextStyle(
                        color: style.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: style.border),
                boxShadow: [
                  BoxShadow(
                    color: style.color.withValues(
                      alpha: context.isDark ? 0.08 : 0.07,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: section.value.map((item) {
                  final isLast = item == section.value.last;
                  return _ShoppingItemTile(
                    list: list,
                    item: item,
                    showDivider: !isLast,
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  static int _categoryOrder(String category) {
    return switch (category) {
      'dairy' => 0,
      'bakery' => 1,
      'drinks' => 2,
      'protein' => 3,
      'produce' => 4,
      _ => 5,
    };
  }

  static String _categoryLabel(String category) {
    return switch (category) {
      'dairy' => 'Dairy',
      'bakery' => 'Bakery',
      'drinks' => 'Drinks',
      'protein' => 'Protein',
      'produce' => 'Produce',
      _ => 'Other',
    };
  }
}

class _ShoppingItemTile extends ConsumerWidget {
  const _ShoppingItemTile({
    required this.list,
    required this.item,
    required this.showDivider,
  });

  final ShoppingList list;
  final ShoppingItem item;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = _ShoppingCategoryStyle.forCategory(item.category, context);
    final iconColor = item.isCompleted ? AppColors.primaryDark : style.color;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.delete_outline, color: AppColors.error),
        ),
      ),
      onDismissed: (_) =>
          ref.read(shoppingListProvider.notifier).deleteItem(list, item),
      child: InkWell(
        onTap: () =>
            ref.read(shoppingListProvider.notifier).toggleItem(list, item),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.isCompleted
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : Colors.transparent,
                      border: Border.all(
                        color: item.isCompleted
                            ? AppColors.primary
                            : context.colors.divider,
                        width: 1.4,
                      ),
                    ),
                    child: item.isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 17,
                            color: AppColors.primaryDark,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: item.isCompleted
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : style.tint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_iconForItem(item), color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: item.isCompleted
                                ? context.colors.textSecondary
                                : context.colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        if (!item.isCompleted)
                          Text(
                            'Tap to check off',
                            style: TextStyle(
                              color: context.colors.textSecondary.withValues(
                                alpha: 0.72,
                              ),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (item.quantity.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: style.tint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.quantity,
                        style: TextStyle(
                          color: style.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (showDivider)
              Divider(
                height: 1,
                indent: 98,
                color: context.colors.divider.withValues(alpha: 0.75),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForItem(ShoppingItem item) {
    final lower = item.name.toLowerCase();
    if (lower.contains('milk')) return Icons.local_drink_outlined;
    if (lower.contains('coffee') || lower.contains('tea')) {
      return Icons.local_cafe_outlined;
    }
    if (lower.contains('juice') || lower.contains('water')) {
      return Icons.local_bar_outlined;
    }
    if (lower.contains('egg')) return Icons.egg_alt_outlined;
    if (lower.contains('bread') || lower.contains('muffin')) {
      return Icons.bakery_dining_outlined;
    }
    if (lower.contains('cheese') || lower.contains('butter')) {
      return Icons.restaurant_outlined;
    }
    if (lower.contains('apple') ||
        lower.contains('banana') ||
        lower.contains('orange')) {
      return Icons.eco_outlined;
    }
    return switch (ShoppingListRepository.categoryForItem(item.name)) {
      'dairy' => Icons.icecream_outlined,
      'bakery' => Icons.bakery_dining_outlined,
      'drinks' => Icons.local_drink_outlined,
      'protein' => Icons.set_meal_outlined,
      'produce' => Icons.eco_outlined,
      _ => Icons.shopping_bag_outlined,
    };
  }
}

class _EmptyItemsCard extends StatelessWidget {
  const _EmptyItemsCard({required this.listTitle});

  final String listTitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: context.colors.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: context.isDark
                ? context.colors.divider
                : AppColors.primary.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: context.isDark ? 0.16 : 0.05,
              ),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.playlist_add_rounded,
                color: AppColors.primaryDark,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '$listTitle is empty',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Add the first item with the plus button, or ask Haven to add it for you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingCategoryStyle {
  const _ShoppingCategoryStyle({
    required this.color,
    required this.tint,
    required this.border,
    required this.icon,
  });

  final Color color;
  final Color tint;
  final Color border;
  final IconData icon;

  static _ShoppingCategoryStyle forCategory(
    String category,
    BuildContext context,
  ) {
    final base = switch (category) {
      'dairy' => const Color(0xFF3B82F6),
      'bakery' => const Color(0xFF4ECDC4),
      'drinks' => const Color(0xFF2563EB),
      'protein' => const Color(0xFF0EA5E9),
      'produce' => const Color(0xFF3AA99F),
      _ => AppColors.primaryDark,
    };
    final icon = switch (category) {
      'dairy' => Icons.icecream_outlined,
      'bakery' => Icons.bakery_dining_outlined,
      'drinks' => Icons.local_drink_outlined,
      'protein' => Icons.egg_alt_outlined,
      'produce' => Icons.eco_outlined,
      _ => Icons.shopping_bag_outlined,
    };
    return _ShoppingCategoryStyle(
      color: base,
      tint: base.withValues(alpha: context.isDark ? 0.18 : 0.12),
      border: base.withValues(alpha: context.isDark ? 0.18 : 0.16),
      icon: icon,
    );
  }
}

class _EmptyShoppingState extends StatelessWidget {
  const _EmptyShoppingState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                color: AppColors.primaryDark,
                size: 42,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start a cute little list',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a list for groceries, routines, or anything you want Haven to remember.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Create list'),
            ),
          ],
        ),
      ),
    );
  }
}
