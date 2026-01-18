import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/journal_entry.dart';
import 'package:personal_haven/providers/event_provider.dart';

class EditJournalEntryScreen extends ConsumerStatefulWidget {
  final JournalEntry entry;

  const EditJournalEntryScreen({super.key, required this.entry});

  @override
  ConsumerState<EditJournalEntryScreen> createState() => _EditJournalEntryScreenState();
}

class _EditJournalEntryScreenState extends ConsumerState<EditJournalEntryScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String? _selectedEmoji;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _contentController = TextEditingController(text: widget.entry.content);
    _selectedEmoji = widget.entry.emoji;
    _selectedCategory = widget.entry.category;
  }

  void _updateEntry() {
    final updatedEntry = widget.entry.copyWith(
      title: _titleController.text,
      content: _contentController.text,
      emoji: _selectedEmoji,
      category: _selectedCategory,
    );

    ref.read(journalEntriesProvider.notifier).updateEntry(updatedEntry);
    Navigator.pop(context);
  }

  void _deleteEntry() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(journalEntriesProvider.notifier).deleteEntry(widget.entry.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Entry',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteEntry,
          ),
          TextButton(
            onPressed: _updateEntry,
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
                hintText: 'Content',
                border: InputBorder.none,
              ),
              maxLines: null,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}