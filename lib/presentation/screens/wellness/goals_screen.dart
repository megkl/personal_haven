import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/data/models/goal.dart';
import 'package:personal_haven/providers/goal_provider.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalState = ref.watch(goalProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: goalState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsCard(goalState),
                _buildCategoryFilter(goalState),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGoalsList(goalState.activeGoals, 'active'),
                      _buildGoalsList(goalState.completedGoals, 'completed'),
                      _buildGoalsList(goalState.goals, 'all'),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Goal', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatsCard(GoalState goalState) {
    final total = goalState.goals.length;
    final active = goalState.activeCount;
    final completed = goalState.completedCount;
    final completionRate = total > 0 ? (completed / total * 100).toInt() : 0;

    // Calculate overall progress
    double overallProgress = 0;
    if (goalState.activeGoals.isNotEmpty) {
      double totalProgress = 0;
      for (final goal in goalState.activeGoals) {
        totalProgress += goal.progressPercentage;
      }
      overallProgress = totalProgress / goalState.activeGoals.length;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
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
                    const Text(
                      '🎯 Goals Progress',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completed of $total',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'goals completed',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
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
                          value: overallProgress / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${overallProgress.toInt()}%',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'avg',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem('🔥 Active', active.toString(), Colors.orange),
              const SizedBox(width: 16),
              _buildStatItem('✅ Done', completed.toString(), Colors.green),
              const SizedBox(width: 16),
              _buildStatItem('📊 Rate', '$completionRate%', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(GoalState goalState) {
    final categories = ['all', 'fitness', 'finance', 'learning', 'personal'];
    final categoryIcons = {
      'all': '📋',
      'fitness': '💪',
      'finance': '💰',
      'learning': '📚',
      'personal': '🌟',
    };

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          final count = category == 'all'
              ? goalState.goals.length
              : goalState.goals.where((g) => g.category == category).length;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Text(categoryIcons[category] ?? '📋'),
                  const SizedBox(width: 6),
                  Text(
                    '${category[0].toUpperCase()}${category.substring(1)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
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
    Tab( text: 'Active'),
    Tab(text: 'Completed'),
    Tab(text: 'All'),
  ],
)

    );
  }

  Widget _buildGoalsList(List<Goal> goals, String type) {
    // Filter by category
    final filteredGoals = _selectedCategory == 'all'
        ? goals
        : goals.where((g) => g.category == _selectedCategory).toList();

    if (filteredGoals.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(goalProvider.notifier).loadGoals();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredGoals.length,
        itemBuilder: (context, index) {
          return _buildGoalCard(filteredGoals[index]);
        },
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final progress = goal.progressPercentage;
    final isCompleted = goal.isCompleted;
    final daysRemaining = goal.daysRemaining;

    final categoryColors = {
      'fitness': Colors.orange,
      'finance': Colors.green,
      'learning': Colors.blue,
      'personal': Colors.purple,
    };

    final categoryIcons = {
      'fitness': '💪',
      'finance': '💰',
      'learning': '📚',
      'personal': '🌟',
    };

    final color = categoryColors[goal.category] ?? AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCompleted
            ? Border.all(color: Colors.green.shade300, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showGoalDetailsSheet(goal),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        categoryIcons[goal.category] ?? '🎯',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  goal.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2D3E40),
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              if (isCompleted)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.green, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Done',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (goal.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              goal.description!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress section
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${goal.currentValue.toStringAsFixed(goal.currentValue.truncateToDouble() == goal.currentValue ? 0 : 1)} / ${goal.targetValue.toStringAsFixed(goal.targetValue.truncateToDouble() == goal.targetValue ? 0 : 1)} ${goal.unit}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D3E40),
                                ),
                              ),
                              Text(
                                '${progress.toInt()}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted ? Colors.green : color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Footer with date and actions
                if (!isCompleted) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (daysRemaining >= 0) ...[
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: daysRemaining <= 7
                              ? Colors.red
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          daysRemaining == 0
                              ? 'Due today'
                              : daysRemaining == 1
                                  ? '1 day left'
                                  : '$daysRemaining days left',
                          style: TextStyle(
                            fontSize: 12,
                            color: daysRemaining <= 7
                                ? Colors.red
                                : Colors.grey.shade500,
                            fontWeight: daysRemaining <= 7
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Quick update button
                      TextButton.icon(
                        onPressed: () => _showQuickUpdateDialog(goal),
                        icon: Icon(Icons.add, size: 16, color: color),
                        label: Text(
                          'Update',
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    String emoji;

    switch (type) {
      case 'active':
        message = 'No active goals';
        emoji = '🎯';
        break;
      case 'completed':
        message = 'No completed goals yet';
        emoji = '🏆';
        break;
      default:
        message = 'No goals yet';
        emoji = '📋';
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
            'Tap + to create your first goal',
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
  // DIALOGS
  // ─────────────────────────────────────────────────────────────

  void _showGoalDetailsSheet(Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GoalDetailsSheet(
        goal: goal,
        onEdit: () {
          Navigator.pop(context);
          _showEditGoalDialog(goal);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(goal);
        },
        onUpdateProgress: () {
          Navigator.pop(context);
          _showQuickUpdateDialog(goal);
        },
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditGoalSheet(
        onSave: (title, description, targetValue, unit, category, targetDate) {
          ref.read(goalProvider.notifier).addGoal(
                title: title,
                description: description,
                targetValue: targetValue,
                unit: unit,
                category: category,
                targetDate: targetDate,
              );
        },
      ),
    );
  }

  void _showEditGoalDialog(Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditGoalSheet(
        goal: goal,
        onSave: (title, description, targetValue, unit, category, targetDate) {
          final updatedGoal = goal.copyWith(
            title: title,
            description: description,
            targetValue: targetValue,
            unit: unit,
            category: category,
            targetDate: targetDate,
            updatedAt: DateTime.now(),
          );
          ref.read(goalProvider.notifier).updateGoal(updatedGoal);
        },
      ),
    );
  }

  void _showQuickUpdateDialog(Goal goal) {
    final controller = TextEditingController(
      text: goal.currentValue.toStringAsFixed(
          goal.currentValue.truncateToDouble() == goal.currentValue ? 0 : 1),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('📈 '),
            Text('Update: ${goal.title}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Current: ${goal.currentValue} ${goal.unit}'),
                Text('Target: ${goal.targetValue} ${goal.unit}'),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'New Progress',
                suffixText: goal.unit,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            // Quick add buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAddButton(controller, goal, 1),
                _buildQuickAddButton(controller, goal, 5),
                _buildQuickAddButton(controller, goal, 10),
                _buildQuickAddButton(controller, goal, 50),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = double.tryParse(controller.text);
              if (newValue != null) {
                ref.read(goalProvider.notifier).updateProgress(goal, newValue);
                Navigator.pop(context);

                if (newValue >= goal.targetValue) {
                  _showCelebration(goal);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButton(
      TextEditingController controller, Goal goal, double amount) {
    return OutlinedButton(
      onPressed: () {
        final current = double.tryParse(controller.text) ?? goal.currentValue;
        controller.text = (current + amount).toStringAsFixed(
            goal.currentValue.truncateToDouble() == goal.currentValue ? 0 : 1);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
      ),
      child: Text('+${amount.toInt()}'),
    );
  }

  void _confirmDelete(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(goalProvider.notifier).deleteGoal(goal.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCelebration(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Goal Completed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ve achieved "${goal.title}"!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Awesome!'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GOAL DETAILS BOTTOM SHEET
// ─────────────────────────────────────────────────────────────

class _GoalDetailsSheet extends StatelessWidget {
  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onUpdateProgress;

  const _GoalDetailsSheet({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateProgress,
  });

  @override
  Widget build(BuildContext context) {
    final categoryIcons = {
      'fitness': '💪',
      'finance': '💰',
      'learning': '📚',
      'personal': '🌟',
    };

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

          // Title
          Row(
            children: [
              Text(
                categoryIcons[goal.category] ?? '🎯',
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      goal.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (goal.description != null) ...[
            const SizedBox(height: 16),
            Text(
              goal.description!,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progress'),
                    Text(
                      '${goal.progressPercentage.toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: goal.progressPercentage / 100,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      goal.isCompleted ? Colors.green : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current: ${goal.currentValue} ${goal.unit}'),
                    Text('Target: ${goal.targetValue} ${goal.unit}'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Dates
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  'Started',
                  DateFormat('MMM d, yyyy').format(goal.startDate),
                  Icons.play_circle_outline,
                ),
              ),
              const SizedBox(width: 12),
              if (goal.targetDate != null)
                Expanded(
                  child: _buildInfoTile(
                    'Due',
                    DateFormat('MMM d, yyyy').format(goal.targetDate!),
                    Icons.flag_outlined,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Actions
          if (!goal.isCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onUpdateProgress,
                icon: const Icon(Icons.add),
                label: const Text('Update Progress'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
                  label: const Text('Delete',
                      style: TextStyle(color: Colors.red)),
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

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ADD/EDIT GOAL BOTTOM SHEET
// ─────────────────────────────────────────────────────────────

class _AddEditGoalSheet extends StatefulWidget {
  final Goal? goal;
  final Function(String title, String? description, double targetValue,
      String unit, String category, DateTime? targetDate) onSave;

  const _AddEditGoalSheet({
    this.goal,
    required this.onSave,
  });

  @override
  State<_AddEditGoalSheet> createState() => _AddEditGoalSheetState();
}

class _AddEditGoalSheetState extends State<_AddEditGoalSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetController;
  late String _selectedUnit;
  late String _selectedCategory;
  DateTime? _targetDate;

  final _units = ['KES', 'USD', 'kg', 'lbs', 'km', 'miles', 'minutes', 'hours', 'count', 'pages', '%'];
  final _categories = ['fitness', 'finance', 'learning', 'personal'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.goal?.description ?? '');
    _targetController = TextEditingController(
      text: widget.goal?.targetValue.toStringAsFixed(
              widget.goal!.targetValue.truncateToDouble() ==
                      widget.goal!.targetValue
                  ? 0
                  : 1) ??
          '',
    );
    _selectedUnit = widget.goal?.unit ?? 'KES';
    _selectedCategory = widget.goal?.category ?? 'personal';
    _targetDate = widget.goal?.targetDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goal != null;

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
                isEditing ? '✏️ Edit Goal' : '🎯 New Goal',
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
                  labelText: 'Goal Title *',
                  hintText: 'e.g., Save for vacation',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add details about your goal',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Target value and unit
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _targetController,
                      decoration: InputDecoration(
                        labelText: 'Target Value *',
                        hintText: '5000',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: _units
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedUnit = v);
                      },
                    ),
                  ),
                ],
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
                items: _categories.map((c) {
                  final icons = {
                    'fitness': '💪',
                    'finance': '💰',
                    'learning': '📚',
                    'personal': '🌟',
                  };
                  return DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Text(icons[c] ?? ''),
                        const SizedBox(width: 8),
                        Text(c[0].toUpperCase() + c.substring(1)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),
              const SizedBox(height: 16),

              // Target date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (date != null) {
                    setState(() => _targetDate = date);
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
                      Text(
                        _targetDate != null
                            ? DateFormat('EEEE, MMM d, yyyy').format(_targetDate!)
                            : 'Set target date (optional)',
                        style: TextStyle(
                          fontSize: 15,
                          color: _targetDate != null
                              ? Colors.black
                              : Colors.grey.shade500,
                        ),
                      ),
                      const Spacer(),
                      if (_targetDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setState(() => _targetDate = null),
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
                    isEditing ? 'Save Changes' : 'Create Goal',
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
    if (_titleController.text.isEmpty || _targetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in required fields')),
      );
      return;
    }

    final target = double.tryParse(_targetController.text);
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target value')),
      );
      return;
    }

    widget.onSave(
      _titleController.text.trim(),
      _descriptionController.text.isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      target,
      _selectedUnit,
      _selectedCategory,
      _targetDate,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.goal != null ? 'Goal updated!' : 'Goal created!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}