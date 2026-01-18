
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/task.dart';

final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  return TasksNotifier();
});

class TasksNotifier extends StateNotifier<List<Task>> {
  TasksNotifier() : super([]);

  void addTask(Task task) {
    state = [...state, task];
  }

  void toggleTask(String id) {
    state = [
      for (final task in state)
        if (task.id == id)
          task.copyWith(isCompleted: !task.isCompleted)
        else
          task,
    ];
  }

  void deleteTask(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}