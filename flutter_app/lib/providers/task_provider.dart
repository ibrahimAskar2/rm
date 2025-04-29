import 'package:flutter/material.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String assignedTo;
  final String assignedById;
  final String status;
  final int priority;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.assignedTo,
    required this.assignedById,
    required this.status,
    required this.priority,
  });
}

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> fetchTasks(String userId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    // محاكاة جلب المهام
    _tasks.clear();
    _tasks.addAll([
      Task(
        id: '1',
        title: 'إعداد التقرير الأسبوعي',
        description: 'إعداد تقرير بأهم الإنجازات خلال الأسبوع الماضي',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        assignedTo: userId,
        assignedById: '2',
        status: 'قيد التنفيذ',
        priority: 1,
      ),
      Task(
        id: '2',
        title: 'مراجعة خطة العمل',
        description: 'مراجعة وتحديث خطة العمل للشهر القادم',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        assignedTo: userId,
        assignedById: '2',
        status: 'لم تبدأ بعد',
        priority: 2,
      ),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _tasks.add(task);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        dueDate: task.dueDate,
        assignedTo: task.assignedTo,
        assignedById: task.assignedById,
        status: newStatus,
        priority: task.priority,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _tasks.removeWhere((task) => task.id == taskId);

    _isLoading = false;
    notifyListeners();
  }
}
