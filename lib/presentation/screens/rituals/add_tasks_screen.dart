import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/providers/task_provider.dart';

/// Add Task Screen - Create new tasks
class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedPriority = 'medium';
  String _selectedCategory = 'personal';

  final List<Map<String, dynamic>> _priorities = [
    {'label': 'Low', 'value': 'low', 'color': Colors.grey},
    {'label': 'Medium', 'value': 'medium', 'color': Colors.blue},
    {'label': 'High', 'value': 'high', 'color': Colors.orange},
    {'label': 'Urgent', 'value': 'urgent', 'color': Colors.red},
  ];

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Personal', 'value': 'personal', 'icon': Icons.person},
    {'label': 'Work', 'value': 'work', 'icon': Icons.work},
    {'label': 'Wellness', 'value': 'wellness', 'icon': Icons.spa},
    {'label': 'Finance', 'value': 'finance', 'icon': Icons.attach_money},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await ref.read(taskProvider.notifier).addTask(
          title: _titleController.text,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          dueDate: _selectedDate,
          priority: _selectedPriority,
          category: _selectedCategory,
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Task'),
        backgroundColor: AppColors.primary,
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
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
            // Title Field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'e.g., Buy groceries',
                prefixIcon: Icon(Icons.edit, color: AppColors.primary),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            
            // Description Field
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add more details...',
                prefixIcon: Icon(Icons.notes, color: AppColors.primary),
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            
            // Due Date
            const Text(
              'Due Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? DateFormat('MMMM dd, yyyy').format(_selectedDate!)
                          : 'Select due date',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() => _selectedDate = null);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Priority
            const Text(
              'Priority',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _priorities.map((priority) {
                final isSelected = _selectedPriority == priority['value'];
                return ChoiceChip(
                  label: Text(priority['label']),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedPriority = priority['value']);
                    }
                  },
                  backgroundColor: Colors.white,
                  selectedColor: priority['color'],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? priority['color']
                        : Colors.grey.shade300,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // Category
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['value'];
                
                return InkWell(
                  onTap: () {
                    setState(() => _selectedCategory = category['value']);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category['icon'],
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category['label'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}