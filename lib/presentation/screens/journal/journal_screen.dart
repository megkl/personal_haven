import 'package:flutter/material.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/data/models/journal_entry.dart';
import 'package:personal_haven/providers/journal_provider.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _searchController = TextEditingController();
  final _categoryController = ScrollController();
  String _selectedCategory = 'All';
  bool _isSearching = false;
  String _searchQuery = '';

  final List<String> _categories = ['All', ...JournalCategories.names];

  @override
  void dispose() {
    _searchController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journalState = ref.watch(journalProvider);

    // Filter entries based on category and search
    List<JournalEntry> filteredEntries = journalState.entries;

    if (_selectedCategory != 'All') {
      filteredEntries = filteredEntries
          .where((e) => e.category == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredEntries = filteredEntries.where((e) {
        return e.title.toLowerCase().contains(query) ||
            e.content.toLowerCase().contains(query) ||
            e.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchHeader(),
          _buildCategoryFilter(journalState),
          const SizedBox(height: 4),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              reverseDuration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0.025, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: journalState.isLoading
                  ? const Center(
                      key: ValueKey('journal-loading'),
                      child: CircularProgressIndicator(),
                    )
                  : filteredEntries.isEmpty
                  ? KeyedSubtree(
                      key: ValueKey('empty-$_selectedCategory-$_searchQuery'),
                      child: _buildEmptyState(),
                    )
                  : RefreshIndicator(
                      key: ValueKey('entries-$_selectedCategory-$_searchQuery'),
                      onRefresh: () =>
                          ref.read(journalProvider.notifier).loadEntries(),
                      child: _buildEntriesList(filteredEntries),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'journal_entry_add',
        onPressed: () => _showAddEntrySheet(context),
        backgroundColor: AppColors.primary,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('New Entry', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Journals',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Pause, reflect, and reconnect with yourself',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.cardColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit_rounded, color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search journal entries',
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: context.colors.textSecondary,
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _clearSearch,
                      ),
                filled: true,
                fillColor: context.colors.cardColor,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.colors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.colors.divider),
                ),
              ),
              onChanged: (value) => setState(() {
                _searchQuery = value;
                _isSearching = value.isNotEmpty;
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
    FocusScope.of(context).unfocus();
  }

  Widget _buildCategoryFilter(JournalState journalState) {
    return Container(
      height: 52,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider),
      ),
      child: ListView.builder(
        controller: _categoryController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          // Get count for category
          int count = 0;
          if (category == 'All') {
            count = journalState.entries.length;
          } else {
            count = journalState.entries
                .where((e) => e.category == category)
                .length;
          }

          return Padding(
            padding: EdgeInsets.only(
              right: index == _categories.length - 1 ? 0 : 4,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (_selectedCategory == category) return;
                setState(() => _selectedCategory = category);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.22)
                            : context.colors.cardColor2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEntriesList(List<JournalEntry> entries) {
    // Group entries by date
    final grouped = <String, List<JournalEntry>>{};
    for (var entry in entries) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.entryDate);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final dayEntries = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _formatDateHeader(date),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            // Entries for this date
            ...dayEntries.map((entry) => _buildEntryCard(entry)),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) return 'Today';
    if (entryDate == yesterday) return 'Yesterday';
    return DateFormat('EEEE, MMMM d').format(date);
  }

  Widget _buildEntryCard(JournalEntry entry) {
    final categoryData = JournalCategories.getByName(entry.category);
    final categoryColor = Color(categoryData?.colorValue ?? 0xFF4ECDC4);

    return GestureDetector(
      onTap: () => _showEntryDetailsSheet(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.colors.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category color bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and emoji
                  Row(
                    children: [
                      if (entry.emoji != null) ...[
                        Text(entry.emoji!, style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          entry.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Content preview
                  Text(
                    entry.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Footer: time, category, tags
                  Row(
                    children: [
                      // Time
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('h:mm a').format(entry.entryDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              categoryData?.emoji ?? '📝',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              entry.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: categoryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Tags indicator
                      if (entry.tags.isNotEmpty) ...[
                        Icon(
                          Icons.label_outline,
                          size: 14,
                          color: context.colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.tags.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📔', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            _isSearching
                ? 'No entries found'
                : _selectedCategory != 'All'
                ? 'No $_selectedCategory entries yet'
                : 'No journal entries yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearching
                ? 'Try a different search term'
                : 'Tap + to create your first entry',
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DIALOGS & SHEETS
  // ─────────────────────────────────────────────────────────────

  void _showAddEntrySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditEntrySheet(
        onSave: (title, content, category, emoji, tags) {
          ref
              .read(journalProvider.notifier)
              .addEntry(
                title: title,
                content: content,
                category: category,
                emoji: emoji,
                tags: tags,
              );
        },
      ),
    );
  }

  void _showEntryDetailsSheet(JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EntryDetailsSheet(
        entry: entry,
        onEdit: () {
          Navigator.pop(context);
          _showEditEntrySheet(entry);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(entry);
        },
      ),
    );
  }

  void _showEditEntrySheet(JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditEntrySheet(
        entry: entry,
        onSave: (title, content, category, emoji, tags) {
          final updatedEntry = entry.copyWith(
            title: title,
            content: content,
            category: category,
            emoji: emoji,
            tags: tags,
            updatedAt: DateTime.now(),
          );
          ref.read(journalProvider.notifier).updateEntry(updatedEntry);
        },
      ),
    );
  }

  void _confirmDelete(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Entry?'),
        content: Text('Are you sure you want to delete "${entry.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(journalProvider.notifier).deleteEntry(entry.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entry deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ENTRY DETAILS BOTTOM SHEET
// ─────────────────────────────────────────────────────────────

class _EntryDetailsSheet extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryDetailsSheet({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final categoryData = JournalCategories.getByName(entry.category);
    final categoryColor = Color(categoryData?.colorValue ?? 0xFF4ECDC4);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.colors.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        if (entry.emoji != null) ...[
                          Text(entry.emoji!, style: TextStyle(fontSize: 36)),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat(
                                  'EEEE, MMMM d, yyyy • h:mm a',
                                ).format(entry.entryDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(categoryData?.emoji ?? '📝'),
                          const SizedBox(width: 6),
                          Text(
                            entry.category,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Content
                    Text(
                      entry.content,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Color(0xFF2D3E40),
                      ),
                    ),

                    // Tags
                    if (entry.tags.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Tags',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                backgroundColor: context.colors.cardColor2,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEdit,
                            icon: Icon(Icons.edit_outlined),
                            label: Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onDelete,
                            icon: Icon(Icons.delete_outline, color: Colors.red),
                            label: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ADD/EDIT ENTRY BOTTOM SHEET
// ─────────────────────────────────────────────────────────────

class _AddEditEntrySheet extends StatefulWidget {
  final JournalEntry? entry;
  final Function(
    String title,
    String content,
    String category,
    String? emoji,
    List<String> tags,
  )
  onSave;

  const _AddEditEntrySheet({this.entry, required this.onSave});

  @override
  State<_AddEditEntrySheet> createState() => _AddEditEntrySheetState();
}

class _AddEditEntrySheetState extends State<_AddEditEntrySheet> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  late String _selectedCategory;
  String? _selectedEmoji;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(
      text: widget.entry?.content ?? '',
    );
    _tagController = TextEditingController();
    _selectedCategory = widget.entry?.category ?? 'Notes';
    _selectedEmoji = widget.entry?.emoji;
    _tags = widget.entry?.tags.toList() ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.colors.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    Text(
                      isEditing ? 'Edit Entry' : 'New Entry',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Save'),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emoji selector
                      Text(
                        'How are you feeling?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: JournalMoods.all.length,
                          itemBuilder: (context, index) {
                            final emoji = JournalMoods.all[index];
                            final isSelected = _selectedEmoji == emoji;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedEmoji = isSelected ? null : emoji;
                                });
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : context.colors.cardColor2,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppColors.primary,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    emoji,
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          hintText: 'Give your entry a title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),

                      // Category
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: JournalCategories.all.map((c) {
                          return DropdownMenuItem(
                            value: c.name,
                            child: Row(
                              children: [
                                Text(c.emoji),
                                const SizedBox(width: 8),
                                Text(c.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedCategory = v);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Content
                      TextField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          labelText: 'Content',
                          hintText: 'Write your thoughts...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 8,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      Text(
                        'Tags',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _tagController,
                              decoration: InputDecoration(
                                hintText: 'Add a tag',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: _addTag,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _addTag(_tagController.text),
                            icon: Icon(Icons.add_circle),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      if (_tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  deleteIcon: Icon(Icons.close, size: 16),
                                  onDeleted: () {
                                    setState(() => _tags.remove(tag));
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() {
        _tags.add(trimmed);
        _tagController.clear();
      });
    }
  }

  void _save() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some content')),
      );
      return;
    }

    widget.onSave(
      _titleController.text.trim(),
      _contentController.text.trim(),
      _selectedCategory,
      _selectedEmoji,
      _tags,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.entry != null ? 'Entry updated!' : 'Entry saved!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
