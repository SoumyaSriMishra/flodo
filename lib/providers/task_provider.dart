import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];

  List<Task> get allTasks => _tasks;

  Future<void> loadTasks() async {
    final box = Hive.box<Task>('tasks');
    _tasks = box.values.toList();
    _ensureSortOrders();
    _sort();
    notifyListeners();
  }

  Future<void> reload() => loadTasks();

  /// Ensures unique sequential [sortOrder] when migrating older Hive rows.
  void _ensureSortOrders() {
    if (_tasks.isEmpty) return;
    _sort();
    final orders = _tasks.map((t) => t.sortOrder).toList();
    final unique = orders.toSet().length;
    final allZero = orders.every((o) => o == 0);
    if (unique == _tasks.length && !allZero) return;
    final box = Hive.box<Task>('tasks');
    for (var i = 0; i < _tasks.length; i++) {
      _tasks[i].sortOrder = i;
      box.put(_tasks[i].id, _tasks[i]);
    }
  }

  void _sort() {
    _tasks.sort((a, b) {
      final aDone = a.status == 'Done';
      final bDone = b.status == 'Done';
      if (aDone != bDone) return aDone ? 1 : -1;
      final c = a.sortOrder.compareTo(b.sortOrder);
      if (c != 0) return c;
      return a.dueDate.compareTo(b.dueDate);
    });
  }

  List<Task> getFiltered(String query, String statusFilter) {
    final lowerQuery = query.trim().toLowerCase();
    return _tasks.where((task) {
      final matchesQuery = lowerQuery.isEmpty || task.title.toLowerCase().contains(lowerQuery);
      final matchesStatus = statusFilter == 'All' || task.status == statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  int _nextSortOrder() {
    if (_tasks.isEmpty) return 0;
    return _tasks.map((t) => t.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> addTask(Task task) async {
    task.sortOrder = _nextSortOrder();
    await Future.delayed(const Duration(seconds: 2));
    await Hive.box<Task>('tasks').put(task.id, task);
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await Future.delayed(const Duration(seconds: 2));
    await Hive.box<Task>('tasks').put(task.id, task);
    await loadTasks();
  }

  /// After a new task was already saved as Done + recurring, spawn the next occurrence only (no second update).
  Future<bool> addRecurringFollowUp(Task task) async {
    if (!task.isRecurring || task.recurrenceInterval == null) return false;
    final int daysToAdd = task.recurrenceInterval == 'Daily' ? 1 : 7;
    final Task nextTask = Task(
      title: task.title,
      description: task.description,
      dueDate: task.dueDate.add(Duration(days: daysToAdd)),
      status: 'To-Do',
      blockedById: task.blockedById,
      isRecurring: true,
      recurrenceInterval: task.recurrenceInterval,
    );
    await addTask(nextTask);
    return true;
  }

  /// Persists a new global order after drag-and-drop (no simulated delay).
  Future<void> applyOrder(List<Task> ordered) async {
    final box = Hive.box<Task>('tasks');
    for (var i = 0; i < ordered.length; i++) {
      ordered[i].sortOrder = i;
      await box.put(ordered[i].id, ordered[i]);
    }
    await loadTasks();
  }

  Future<void> deleteTask(String id) async {
    await Hive.box<Task>('tasks').delete(id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  bool isBlocked(Task task) {
    final blockerId = task.blockedById;
    if (blockerId == null) {
      return false;
    }
    final blockingTask = getTaskById(blockerId);
    return blockingTask != null && blockingTask.status != 'Done';
  }

  /// Call instead of [updateTask] when the user marks a task as "Done" from the edit screen.
  Future<bool> markDoneAndRecur(Task task) async {
    task.status = 'Done';
    await updateTask(task);

    if (task.isRecurring && task.recurrenceInterval != null) {
      final int daysToAdd = task.recurrenceInterval == 'Daily' ? 1 : 7;
      final DateTime nextDueDate = task.dueDate.add(Duration(days: daysToAdd));

      final Task nextTask = Task(
        title: task.title,
        description: task.description,
        dueDate: nextDueDate,
        status: 'To-Do',
        blockedById: task.blockedById,
        isRecurring: true,
        recurrenceInterval: task.recurrenceInterval,
      );

      await addTask(nextTask);
      return true;
    }

    return false;
  }
}
