import 'package:flutter/material.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
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
  late final TabController _tabController;
  final _searchController = TextEditingController();

  static const _taskTabs = ['All', 'Pending', 'Done', 'Urgent'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _taskTabs.length,
      vsync: this,
      animationDuration: const Duration(milliseconds: 280),
    );
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                    _buildSearchBar(),

          _buildTabBar(taskState),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'rituals_tasks_add',
        onPressed: () => _showAddTaskSheet(context),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: Colors.white),
        elevation: 4,
      ),
    );
  }

  // ─── SEARCH BAR ───────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: const Icon(
            Icons.find_replace,
            color: AppColors.primary,
            size: 20,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(taskProvider.notifier).clearSearch();
                    setState(() {});
                  },
                ),
              PopupMenuButton<String>(
                tooltip: 'Task options',
                icon: Icon(
                  Icons.more_horiz,
                  color: context.colors.textSecondary,
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'clear_completed') {
                    _confirmClearCompleted();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'clear_completed',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Clear completed'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          filled: true,
          fillColor: context.colors.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.colors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.colors.divider),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (query) {
          ref.read(taskProvider.notifier).searchTasks(query);
          setState(() {});
        },
      ),
    );
  }

  // ─── TAB BAR ──────────────────────────────────────────────────

  Widget _buildTabBar(TaskState taskState) {
    final counts = [
      taskState.tasks.length,
      taskState.pendingCount,
      taskState.completedCount,
      taskState.urgentCount,
    ];

    return Container(
      height: 46,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.colors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.divider),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / _taskTabs.length;

          return AnimatedBuilder(
            animation: _tabController.animation!,
            builder: (context, _) {
              final position = _tabController.animation!.value.clamp(
                0.0,
                (_taskTabs.length - 1).toDouble(),
              );
              final selectedIndex = position.round();

              return Stack(
                children: [
                  Positioned(
                    left: position * tabWidth,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                  Row(
                    children: _taskTabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final isSelected = selectedIndex == index;
                      final count = counts[index];

                      return Expanded(
                        child: Semantics(
                          button: true,
                          selected: isSelected,
                          label: '${entry.value} tasks, $count',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(11),
                            onTap: () => _tabController.animateTo(
                              index,
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      entry.value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
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
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : context.colors.cardColor2,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$count',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
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
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ─── TASK LIST ────────────────────────────────────────────────

  Widget _buildTaskList(List<Task> tasks, String type) {
    if (tasks.isEmpty) return _buildEmptyState(type);

    return RefreshIndicator(
      onRefresh: () async => ref.read(taskProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: tasks.length,
        itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final priorityColors = {
      'urgent': Colors.red,
      'high': Colors.orange,
      'medium': const Color(0xFF667eea),
      'low': Colors.grey,
    };
    final categoryEmojis = {
      'personal': '',
      'work': '💼',
      'wellness': '💪',
      'finance': '💰',
    };
    final color = priorityColors[task.priority] ?? Colors.grey;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.green.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(Icons.check, color: Colors.white, size: 26),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          ref.read(taskProvider.notifier).toggleTask(task);
          return false;
        }
        return await _confirmDelete(task);
      },
      child: GestureDetector(
        onTap: () => _showTaskDetailsSheet(task),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: context.colors.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: task.isOverdue
                ? Border.all(
                    color: Colors.red.withValues(alpha: 0.4),
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Priority stripe
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checkbox
                        GestureDetector(
                          onTap: () =>
                              ref.read(taskProvider.notifier).toggleTask(task),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: task.isCompleted
                                    ? AppColors.primary
                                    : color,
                                width: 2,
                              ),
                              color: task.isCompleted
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                            child: task.isCompleted
                                ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    categoryEmojis[task.category] ?? '📋',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: task.isCompleted
                                            ? context.colors.textSecondary
                                            : const Color(0xFF2D3E40),
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
                                const SizedBox(height: 3),
                                Text(
                                  task.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.colors.textSecondary,
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (task.dueDate != null) ...[
                                    Icon(
                                      Icons.schedule_outlined,
                                      size: 13,
                                      color: task.isOverdue
                                          ? Colors.red
                                          : context.colors.textSecondary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _formatDueDate(task.dueDate!),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: task.isOverdue
                                            ? Colors.red
                                            : context.colors.textSecondary,
                                        fontWeight: task.isOverdue
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      task.priority.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Options
                        GestureDetector(
                          onTap: () => _showTaskOptionsSheet(task),
                          child: Icon(
                            Icons.more_vert,
                            color: context.colors.divider,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    final data = {
      'pending': ('🎉', 'You\'re all caught up!', 'No pending tasks'),
      'completed': ('📋', 'Start completing tasks', 'Nothing done yet'),
      'urgent': ('✨', 'No urgent tasks', 'Great job staying on top!'),
      'all': ('📝', 'No tasks yet', 'Tap + to add your first task'),
    };

    final (emoji, title, subtitle) = data[type] ?? ('📝', 'Empty', '');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: TextStyle(fontSize: 56)),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3E40),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    final hasTime =
        dueDate.hour != 0 ||
        dueDate.minute != 0 ||
        dueDate.second != 0 ||
        dueDate.millisecond != 0 ||
        dueDate.microsecond != 0;
    final time = hasTime ? ' · ${DateFormat('h:mm a').format(dueDate)}' : '';

    if (taskDate.isBefore(today)) {
      final days = today.difference(taskDate).inDays;
      return '${days == 1 ? 'Yesterday' : '$days days ago'}$time';
    } else if (taskDate == today) {
      return 'Today$time';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow$time';
    }
    return '${DateFormat('MMM d').format(dueDate)}$time';
  }

  // ─── DIALOGS / SHEETS ─────────────────────────────────────────

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditTaskSheet(
        onSave: (title, description, dueDate, priority, category) {
          ref
              .read(taskProvider.notifier)
              .addTask(
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
      builder: (_) => _TaskDetailsSheet(
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
      builder: (_) => _AddEditTaskSheet(
        task: task,
        onSave: (title, description, dueDate, priority, category) {
          ref
              .read(taskProvider.notifier)
              .updateTask(
                task.copyWith(
                  title: title,
                  description: description,
                  dueDate: dueDate,
                  clearDueDate: dueDate == null,
                  priority: priority,
                  category: category,
                ),
              );
        },
      ),
    );
  }

  void _showTaskOptionsSheet(Task task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.colors.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                task.isCompleted ? Icons.undo : Icons.check_circle_outline,
                color: AppColors.primary,
              ),
              title: Text(
                task.isCompleted ? 'Mark as incomplete' : 'Mark as complete',
              ),
              onTap: () {
                ref.read(taskProvider.notifier).toggleTask(task);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: Colors.blue),
              title: Text('Edit task'),
              onTap: () {
                Navigator.pop(context);
                _showEditTaskSheet(task);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Delete task', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(task);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(Task task) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('Delete Task?'),
            content: Text('Delete "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(taskProvider.notifier).deleteTask(task.id);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Delete'),
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
        SnackBar(
          content: Text('No completed tasks to clear'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear Completed?'),
        content: Text(
          'Permanently delete ${taskState.completedCount} completed task${taskState.completedCount != 1 ? 's' : ''}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(taskProvider.notifier).deleteCompletedTasks();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// ─── TASK DETAILS SHEET ───────────────────────────────────────

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
      'medium': const Color(0xFF667eea),
      'low': Colors.grey,
    };
    final categoryEmojis = {
      'personal': '✅',
      'work': '💼',
      'wellness': '💪',
      'finance': '💰',
    };
    final color = priorityColors[task.priority] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                categoryEmojis[task.category] ?? '📋',
                style: TextStyle(fontSize: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: const Color(0xFF2D3E40),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        if (task.isCompleted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'DONE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
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
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              task.description!,
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          if (task.dueDate != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.colors.cardColor2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: task.isOverdue
                        ? Colors.red
                        : context.colors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    task.hasDueTime
                        ? DateFormat(
                            'EEEE, MMM d, yyyy · h:mm a',
                          ).format(task.dueDate!)
                        : '${DateFormat('EEEE, MMM d, yyyy').format(task.dueDate!)} · End of day',
                    style: TextStyle(
                      fontSize: 13,
                      color: task.isOverdue
                          ? Colors.red
                          : context.colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onToggle,
              icon: Icon(task.isCompleted ? Icons.undo : Icons.check),
              label: Text(
                task.isCompleted ? 'Mark as Incomplete' : 'Mark as Complete',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: task.isCompleted
                    ? context.colors.textSecondary
                    : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: 18),
                  label: Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  label: Text('Delete', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ─── ADD/EDIT TASK SHEET ──────────────────────────────────────

class _AddEditTaskSheet extends StatefulWidget {
  final Task? task;
  final Function(String, String?, DateTime?, String, String) onSave;

  const _AddEditTaskSheet({this.task, required this.onSave});

  @override
  State<_AddEditTaskSheet> createState() => _AddEditTaskSheetState();
}

class _AddEditTaskSheetState extends State<_AddEditTaskSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedPriority;
  late String _selectedCategory;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;

  final _priorities = ['low', 'medium', 'high', 'urgent'];
  final _categories = ['personal', 'work', 'wellness', 'finance'];

  final _priorityEmojis = {
    'urgent': '🔴',
    'high': '🟠',
    'medium': '🔵',
    'low': '⚪',
  };
  final _categoryEmojis = {
    'personal': '',
    'work': '💼',
    'wellness': '💪',
    'finance': '💰',
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedPriority = widget.task?.priority ?? 'medium';
    _selectedCategory = widget.task?.category ?? 'personal';
    _dueDate = widget.task?.dueDate;
    _dueTime = widget.task?.hasDueTime == true
        ? TimeOfDay.fromDateTime(widget.task!.dueDate!)
        : null;
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
        decoration: BoxDecoration(
          color: context.colors.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEditing ? '✏️ Edit Task' : '➕ New Task',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Title
              TextField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDec('What needs to be done? *'),
              ),
              const SizedBox(height: 12),

              // Description
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDec('Add details (optional)'),
              ),
              const SizedBox(height: 16),

              // Priority
              Text(
                'Priority',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((p) {
                  final isSelected = _selectedPriority == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPriority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : context.colors.cardColor2,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : Border.all(color: context.colors.divider),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _priorityEmojis[p] ?? '⚪',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              p[0].toUpperCase() + p.substring(1),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.primary
                                    : context.colors.textSecondary,
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
                decoration: _inputDec(
                  'Category',
                ).copyWith(labelText: 'Category', hintText: null),
                borderRadius: BorderRadius.circular(14),
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
              const SizedBox(height: 12),

              // Due date
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
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
                  if (date != null) {
                    setState(() {
                      _dueDate = DateTime(date.year, date.month, date.day);
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.colors.cardColor2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.colors.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _dueDate != null
                              ? DateFormat('EEE, MMM d, yyyy').format(_dueDate!)
                              : 'Set due date (optional)',
                          style: TextStyle(
                            fontSize: 14,
                            color: _dueDate != null
                                ? context.colors.textPrimary
                                : context.colors.textSecondary,
                          ),
                        ),
                      ),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() {
                            _dueDate = null;
                            _dueTime = null;
                          }),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: context.colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_dueDate != null) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _dueTime ?? TimeOfDay.now(),
                    );
                    if (time != null) setState(() => _dueTime = time);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.colors.cardColor2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.colors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _dueTime == null
                                ? 'Due by end of day'
                                : 'Due at ${_dueTime!.format(context)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ),
                        if (_dueTime != null)
                          IconButton(
                            tooltip: 'Remove due time',
                            onPressed: () => setState(() => _dueTime = null),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Add Task',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: context.colors.textSecondary, fontSize: 14),
    filled: true,
    fillColor: context.colors.cardColor2,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a task title'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    widget.onSave(
      _titleController.text.trim(),
      _descriptionController.text.isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      _combinedDueDate,
      _selectedPriority,
      _selectedCategory,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.task != null ? 'Task updated! ✓' : 'Task added! ✓',
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  DateTime? get _combinedDueDate {
    if (_dueDate == null) return null;
    if (_dueTime == null) {
      return DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day);
    }
    return DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      _dueTime!.hour,
      _dueTime!.minute,
    );
  }
}
