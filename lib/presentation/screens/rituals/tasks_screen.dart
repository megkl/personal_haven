import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/data/models/task.dart';
import 'package:personal_haven/presentation/screens/rituals/add_tasks_screen.dart';
import 'package:personal_haven/providers/task_provider.dart';

/// Tasks Screen - Complete todo list management (Standalone)
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);
    final pendingTasks = taskState.tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = taskState.tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tasks'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      
      body: taskState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress Card
                _buildProgressCard(taskState),
                
                // Filter Chips
                _buildFilterChips(),
                
                // Tasks List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(taskProvider.notifier).refresh();
                    },
                    child: pendingTasks.isEmpty && completedTasks.isEmpty
                        ? _buildEmptyState()
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (pendingTasks.isNotEmpty) ...[
                                _buildSectionHeader('Pending', pendingTasks.length),
                                ...pendingTasks.map((task) => _buildTaskItem(task)),
                              ],
                              if (completedTasks.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildSectionHeader('Completed', completedTasks.length),
                                ...completedTasks.map((task) => _buildTaskItem(task)),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProgressCard(TaskState taskState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${taskState.completedCount} / ${taskState.tasks.length}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Tasks Completed',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: taskState.completionPercentage / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${taskState.completionPercentage.toInt()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (taskState.urgentCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${taskState.urgentCount} Urgent Tasks',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All', 'value': 'all'},
      {'label': 'Today', 'value': 'today'},
      {'label': 'Urgent', 'value': 'urgent'},
      {'label': 'Pending', 'value': 'pending'},
      {'label': 'Completed', 'value': 'completed'},
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['value'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter['value']!);
                  ref.read(taskProvider.notifier).setFilter(filter['value']!);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        ref.read(taskProvider.notifier).deleteTask(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${task.title} deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // TODO: Implement undo
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: task.isUrgent
              ? Border.all(color: Colors.red, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () {
                ref.read(taskProvider.notifier).toggleTask(task);
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: task.isCompleted ? AppColors.primary : Colors.grey,
                    width: 2,
                  ),
                  color: task.isCompleted ? AppColors.primary : Colors.transparent,
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Task Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (task.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (task.dueDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: task.isOverdue ? Colors.red : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(task.dueDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: task.isOverdue ? Colors.red : AppColors.textSecondary,
                          ),
                        ),
                        if (task.isOverdue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Overdue',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Priority Badge
            _buildPriorityBadge(task.priority),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority) {
      case 'urgent':
        color = Colors.red;
        break;
      case 'high':
        color = Colors.orange;
        break;
      case 'medium':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: 8,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first task',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    // TODO: Implement advanced filter dialog
  }
}

// ============================================================================
// Tasks Screen Content (Without AppBar - for use in Tabs)
// ============================================================================

class TasksScreenContent extends ConsumerStatefulWidget {
  const TasksScreenContent({super.key});

  @override
  ConsumerState<TasksScreenContent> createState() => _TasksScreenContentState();
}

class _TasksScreenContentState extends ConsumerState<TasksScreenContent> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);
    final pendingTasks = taskState.tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = taskState.tasks.where((t) => t.isCompleted).toList();

    return taskState.isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Progress Card
              _buildProgressCard(taskState),
              
              // Filter Chips
              _buildFilterChips(),
              
              // Tasks List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(taskProvider.notifier).refresh();
                  },
                  child: pendingTasks.isEmpty && completedTasks.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (pendingTasks.isNotEmpty) ...[
                              _buildSectionHeader('Pending', pendingTasks.length),
                              ...pendingTasks.map((task) => _buildTaskItem(task)),
                            ],
                            if (completedTasks.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildSectionHeader('Completed', completedTasks.length),
                              ...completedTasks.map((task) => _buildTaskItem(task)),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          );
  }

  Widget _buildProgressCard(TaskState taskState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${taskState.completedCount} / ${taskState.tasks.length}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Tasks Completed',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: taskState.completionPercentage / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${taskState.completionPercentage.toInt()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (taskState.urgentCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${taskState.urgentCount} Urgent Tasks',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All', 'value': 'all'},
      {'label': 'Today', 'value': 'today'},
      {'label': 'Urgent', 'value': 'urgent'},
      {'label': 'Pending', 'value': 'pending'},
      {'label': 'Completed', 'value': 'completed'},
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['value'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter['value']!);
                  ref.read(taskProvider.notifier).setFilter(filter['value']!);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        ref.read(taskProvider.notifier).deleteTask(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${task.title} deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // TODO: Implement undo
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: task.isUrgent
              ? Border.all(color: Colors.red, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () {
                ref.read(taskProvider.notifier).toggleTask(task);
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: task.isCompleted ? AppColors.primary : Colors.grey,
                    width: 2,
                  ),
                  color: task.isCompleted ? AppColors.primary : Colors.transparent,
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Task Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (task.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (task.dueDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: task.isOverdue ? Colors.red : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(task.dueDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: task.isOverdue ? Colors.red : AppColors.textSecondary,
                          ),
                        ),
                        if (task.isOverdue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Overdue',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Priority Badge
            _buildPriorityBadge(task.priority),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority) {
      case 'urgent':
        color = Colors.red;
        break;
      case 'high':
        color = Colors.orange;
        break;
      case 'medium':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: 8,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first task',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}