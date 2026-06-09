import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/data/models/task.dart';
import 'package:personal_haven/providers/task_provider.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header with search
          _buildHeader(taskState),

          // Progress Card
          _buildProgressCard(taskState),

          // Tab Bar
          _buildTabBar(),

          // Task Lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(taskState.tasks, 'all'),
                _buildTaskList(taskState.pendingTasks, 'pending'),
                _buildTaskList(taskState.completedTasks, 'completed'),
                _buildTaskList(taskState.urgentTasks, 'urgent'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Task', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader(TaskState taskState) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: _isSearching
          ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (query) {
                      ref.read(taskProvider.notifier).searchTasks(query);
                    },
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _isSearching = false);
                    _searchController.clear();
                    ref.read(taskProvider.notifier).clearSearch();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Tasks',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3E40),
                      ),
                    ),
                    Text(
                      '${taskState.pendingCount} pending, ${taskState.completedCount} completed',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => setState(() => _isSearching = true),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'clear_completed') {
                          _confirmClearCompleted();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'clear_completed',
                          child: Row(
                            children: [
                              Icon(Icons.delete_sweep, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Clear completed'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildProgressCard(TaskState taskState) {
    final percentage = taskState.completionPercentage;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: taskState.urgentCount > 0
              ? [Colors.orange.shade400, Colors.red.shade400]
              : [const Color(0xFF6BCB77), const Color(0xFF4AA96C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (taskState.urgentCount > 0 ? Colors.orange : const Color(0xFF6BCB77))
                .withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taskState.urgentCount > 0
                          ? '⚡ ${taskState.urgentCount} Urgent Tasks'
                          : '✨ Great Progress!',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${taskState.completedCount}/${taskState.tasks.length}',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'tasks completed',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress circle
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${percentage.toInt()}%',
                        style: const TextStyle(
                          fontSize: 22,
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
          if (taskState.overdueCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${taskState.overdueCount} overdue task${taskState.overdueCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Pending'),
          Tab(text: 'Done'),
          Tab(text: 'Urgent'),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, String type) {
    if (tasks.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(taskProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return _buildTaskCard(tasks[index]);
        },
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final priorityColors = {
      'urgent': Colors.red,
      'high': Colors.orange,
      'medium': Colors.blue,
      'low': Colors.grey,
    };

    final priorityEmojis = {
      'urgent': '🔴',
      'high': '🟠',
      'medium': '🔵',
      'low': '⚪',
    };

    final categoryEmojis = {
      'personal': '🏠',
      'work': '💼',
      'wellness': '💪',
      'finance': '💰',
    };

    final color = priorityColors[task.priority] ?? Colors.grey;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Toggle completion
          ref.read(taskProvider.notifier).toggleTask(task);
          return false;
        } else {
          // Delete
          return await _confirmDelete(task);
        }
      },
      child: GestureDetector(
        onTap: () => _showTaskDetailsSheet(task),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: task.isUrgent || task.isOverdue
                ? Border.all(color: Colors.red, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Priority color bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Checkbox
                    GestureDetector(
                      onTap: () {
                        ref.read(taskProvider.notifier).toggleTask(task);
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: task.isCompleted ? AppColors.primary : color,
                            width: 2,
                          ),
                          color: task.isCompleted
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                        child: task.isCompleted
                            ? const Icon(Icons.check,
                                size: 18, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Task content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                categoryEmojis[task.category] ?? '📋',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2D3E40),
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (task.description != null &&
                              task.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              task.description!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),

                          // Footer: due date, priority
                          Row(
                            children: [
                              if (task.dueDate != null) ...[
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: task.isOverdue
                                      ? Colors.red
                                      : Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDueDate(task.dueDate!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: task.isOverdue
                                        ? Colors.red
                                        : Colors.grey.shade500,
                                    fontWeight: task.isOverdue
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      priorityEmojis[task.priority] ?? '⚪',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      task.priority.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // More options
                    IconButton(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                      onPressed: () => _showTaskOptionsSheet(task),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate.isBefore(today)) {
      final daysAgo = today.difference(taskDate).inDays;
      return daysAgo == 1 ? 'Yesterday' : '$daysAgo days ago';
    } else if (taskDate == today) {
      return 'Today';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM d').format(dueDate);
    }
  }

  Widget _buildEmptyState(String type) {
    String message;
    String emoji;

    switch (type) {
      case 'pending':
        message = 'No pending tasks';
        emoji = '🎉';
        break;
      case 'completed':
        message = 'No completed tasks yet';
        emoji = '📋';
        break;
      case 'urgent':
        message = 'No urgent tasks';
        emoji = '✨';
        break;
      default:
        message = 'No tasks yet';
        emoji = '📝';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            type == 'pending' || type == 'urgent'
                ? 'You\'re all caught up!'
                : 'Tap + to add your first task',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DIALOGS & SHEETS
  // ─────────────────────────────────────────────────────────────

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditTaskSheet(
        onSave: (title, description, dueDate, priority, category) {
          ref.read(taskProvider.notifier).addTask(
                title: title,
                description: description,
                dueDate: dueDate,
                priority: priority,
                category: category,
              );
        },
      ),
    );
  }

  void _showTaskDetailsSheet(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskDetailsSheet(
        task: task,
        onEdit: () {
          Navigator.pop(context);
          _showEditTaskSheet(task);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(task);
        },
        onToggle: () {
          ref.read(taskProvider.notifier).toggleTask(task);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditTaskSheet(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditTaskSheet(
        task: task,
        onSave: (title, description, dueDate, priority, category) {
          final updatedTask = task.copyWith(
            title: title,
            description: description,
            dueDate: dueDate,
            priority: priority,
            category: category,
          );
          ref.read(taskProvider.notifier).updateTask(updatedTask);
        },
      ),
    );
  }

  void _showTaskOptionsSheet(Task task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(
                task.isCompleted ? Icons.undo : Icons.check_circle,
                color: AppColors.primary,
              ),
              title: Text(
                  task.isCompleted ? 'Mark as incomplete' : 'Mark as complete'),
              onTap: () {
                ref.read(taskProvider.notifier).toggleTask(task);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit task'),
              onTap: () {
                Navigator.pop(context);
                _showEditTaskSheet(task);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.orange),
              title: const Text('Change priority'),
              onTap: () {
                Navigator.pop(context);
                _showChangePriorityDialog(task);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete task', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(task);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showChangePriorityDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPriorityOption(task, 'urgent', '🔴', 'Urgent', Colors.red),
            _buildPriorityOption(task, 'high', '🟠', 'High', Colors.orange),
            _buildPriorityOption(task, 'medium', '🔵', 'Medium', Colors.blue),
            _buildPriorityOption(task, 'low', '⚪', 'Low', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityOption(
    Task task,
    String priority,
    String emoji,
    String label,
    Color color,
  ) {
    final isSelected = task.priority == priority;

    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 20)),
      title: Text(label),
      trailing: isSelected ? Icon(Icons.check, color: color) : null,
      onTap: () {
        ref.read(taskProvider.notifier).updatePriority(task, priority);
        Navigator.pop(context);
      },
    );
  }

  Future<bool> _confirmDelete(Task task) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task?'),
            content: Text('Are you sure you want to delete "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(taskProvider.notifier).deleteTask(task.id);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _confirmClearCompleted() {
    final taskState = ref.read(taskProvider);
    if (taskState.completedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No completed tasks to clear')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Completed Tasks?'),
        content: Text(
            'This will permanently delete ${taskState.completedCount} completed task${taskState.completedCount > 1 ? 's' : ''}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(taskProvider.notifier).deleteCompletedTasks();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Completed tasks cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TASK DETAILS SHEET
// ─────────────────────────────────────────────────────────────

class _TaskDetailsSheet extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _TaskDetailsSheet({
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColors = {
      'urgent': Colors.red,
      'high': Colors.orange,
      'medium': Colors.blue,
      'low': Colors.grey,
    };

    final categoryEmojis = {
      'personal': '🏠',
      'work': '💼',
      'wellness': '💪',
      'finance': '💰',
    };

    final color = priorityColors[task.priority] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title with status
          Row(
            children: [
              Text(
                categoryEmojis[task.category] ?? '📋',
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        decoration:
                            task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (task.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'COMPLETED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              task.description!,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Info row
          Row(
            children: [
              if (task.dueDate != null)
                Expanded(
                  child: _buildInfoTile(
                    task.isOverdue ? 'Overdue' : 'Due Date',
                    DateFormat('MMM d, yyyy').format(task.dueDate!),
                    Icons.calendar_today,
                    task.isOverdue ? Colors.red : Colors.grey.shade600,
                  ),
                ),
              if (task.dueDate != null) const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile(
                  'Category',
                  task.category[0].toUpperCase() + task.category.substring(1),
                  Icons.folder_outlined,
                  Colors.grey.shade600,
                ),
              ),
            ],
          ),

          if (task.completedAt != null) ...[
            const SizedBox(height: 12),
            _buildInfoTile(
              'Completed',
              DateFormat('MMM d, yyyy at h:mm a').format(task.completedAt!),
              Icons.check_circle_outline,
              Colors.green,
            ),
          ],

          const SizedBox(height: 24),

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onToggle,
              icon: Icon(task.isCompleted ? Icons.undo : Icons.check),
              label: Text(task.isCompleted
                  ? 'Mark as Incomplete'
                  : 'Mark as Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    task.isCompleted ? Colors.grey : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ADD/EDIT TASK SHEET
// ─────────────────────────────────────────────────────────────

class _AddEditTaskSheet extends StatefulWidget {
  final Task? task;
  final Function(String title, String? description, DateTime? dueDate,
      String priority, String category) onSave;

  const _AddEditTaskSheet({
    this.task,
    required this.onSave,
  });

  @override
  State<_AddEditTaskSheet> createState() => _AddEditTaskSheetState();
}

class _AddEditTaskSheetState extends State<_AddEditTaskSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedPriority;
  late String _selectedCategory;
  DateTime? _dueDate;

  final _priorities = ['low', 'medium', 'high', 'urgent'];
  final _categories = ['personal', 'work', 'wellness', 'finance'];

  final _priorityEmojis = {
    'urgent': '🔴',
    'high': '🟠',
    'medium': '🔵',
    'low': '⚪',
  };

  final _categoryEmojis = {
    'personal': '🏠',
    'work': '💼',
    'wellness': '💪',
    'finance': '💰',
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _selectedPriority = widget.task?.priority ?? 'medium';
    _selectedCategory = widget.task?.category ?? 'personal';
    _dueDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                isEditing ? '✏️ Edit Task' : '➕ New Task',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'What needs to be done?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add details...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Priority
              const Text(
                'Priority',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedPriority = priority),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              _priorityEmojis[priority] ?? '⚪',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              priority[0].toUpperCase() + priority.substring(1),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Text(_categoryEmojis[cat] ?? '📋'),
                        const SizedBox(width: 8),
                        Text(cat[0].toUpperCase() + cat.substring(1)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),
              const SizedBox(height: 16),

              // Due date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _dueDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dueDate != null
                              ? DateFormat('EEEE, MMM d, yyyy').format(_dueDate!)
                              : 'Set due date (optional)',
                          style: TextStyle(
                            fontSize: 15,
                            color: _dueDate != null
                                ? Colors.black
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setState(() => _dueDate = null),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Add Task',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    widget.onSave(
      _titleController.text.trim(),
      _descriptionController.text.isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      _dueDate,
      _selectedPriority,
      _selectedCategory,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.task != null ? 'Task updated!' : 'Task added!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}