import 'package:flutter/material.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/providers/task_provider.dart';
import 'package:personal_haven/presentation/widgets/voice_dictation_button.dart';

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
  TimeOfDay? _selectedTime;
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
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    if (_selectedDate == null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  DateTime? get _dueDateTime {
    if (_selectedDate == null) return null;
    if (_selectedTime == null) {
      return DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
    }
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
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

    await ref
        .read(taskProvider.notifier)
        .addTask(
          title: _titleController.text,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          dueDate: _dueDateTime,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('New Task'),
        backgroundColor: AppColors.primary,
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: Text(
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
              decoration: InputDecoration(
                labelText: 'Task Title',
                hintText: 'e.g., Buy groceries',
                prefixIcon: const Icon(Icons.edit, color: AppColors.primary),
                suffixIcon: VoiceDictationButton(
                  controller: _titleController,
                  tooltip: 'Dictate task title',
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Description Field
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add more details...',
                prefixIcon: const Icon(Icons.notes, color: AppColors.primary),
                suffixIcon: VoiceDictationButton(
                  controller: _descriptionController,
                  tooltip: 'Dictate task details',
                ),
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Due Date
            Text(
              'Due Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? DateFormat('MMMM dd, yyyy').format(_selectedDate!)
                          : 'Select due date',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate != null
                            ? context.colors.textPrimary
                            : context.colors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedDate != null)
                      IconButton(
                        icon: Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                            _selectedTime = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedTime == null
                              ? 'Due by end of day'
                              : 'Due at ${_selectedTime!.format(context)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                      if (_selectedTime != null)
                        IconButton(
                          tooltip: 'Remove due time',
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => setState(() => _selectedTime = null),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Priority
            Text(
              'Priority',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
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
                  backgroundColor: context.colors.cardColor,
                  selectedColor: priority['color'],
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : context.colors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? priority['color']
                        : context.colors.divider,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Category
            Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
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
                            : context.colors.divider,
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
                              : context.colors.textSecondary,
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
                                : context.colors.textPrimary,
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
