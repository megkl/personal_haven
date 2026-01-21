import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/journal_entry.dart';
import 'package:personal_haven/providers/event_provider.dart';
import 'package:uuid/uuid.dart';

class AddJournalEntryScreen extends ConsumerStatefulWidget {
  const AddJournalEntryScreen({super.key});

  @override
  ConsumerState<AddJournalEntryScreen> createState() => _AddJournalEntryScreenState();
}

class _AddJournalEntryScreenState extends ConsumerState<AddJournalEntryScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedEmoji;
  String _selectedCategory = 'All';

  final List<String> _emojis = ['😢', '😐', '😊', '🥰', '💡', '😁'];

  void _saveEntry() {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      return;
    }

    final newEntry = JournalEntry(
      id: const Uuid().v4(),
      userId: '1',
      title: _titleController.text,
      content: _contentController.text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      category: _selectedCategory,
      emoji: _selectedEmoji,
    );

    ref.read(journalEntriesProvider.notifier).addEntry(newEntry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Entry',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: _saveEntry,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF4ECDC4),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Write your thoughts...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
              maxLines: null,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            const Text(
              'How are you feeling?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: _emojis.map((emoji) {
                final isSelected = _selectedEmoji == emoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4ECDC4).withOpacity(0.2)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4ECDC4)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['All', 'Notes', 'Goals', 'Food'].map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = category);
                  },
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF4ECDC4),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}


  