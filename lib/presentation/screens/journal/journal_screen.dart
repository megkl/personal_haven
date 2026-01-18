import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/presentation/screens/journal/edit_entry_screen.dart';
import 'package:personal_haven/providers/event_provider.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Notes', 'Goals', 'Food', 'Health'];

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(journalEntriesProvider);
    final filteredEntries = _selectedCategory == 'All'
        ? entries
        : entries.where((e) => e.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Search journal entries...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () {},
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Category Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Journal Entries List
          Expanded(
            child: filteredEntries.isEmpty
                ? const Center(
                    child: Text(
                      'No entries yet.\nTap + to create your first entry!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditJournalEntryScreen(entry: entry),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
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
                                  Expanded(
                                    child: Text(
                                      entry.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D3E40),
                                      ),
                                    ),
                                  ),
                                  if (entry.emoji != null)
                                    Text(
                                      entry.emoji!,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                entry.content,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MMM dd').format(entry.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (entry.category != 'All')
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: entry.tags.contains('Health')
                                            ? Colors.red.shade100
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        entry.category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: entry.tags.contains('Health')
                                              ? Colors.red
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
