import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      assignedTo: map['assignedTo'] ?? '',
      assignedById: map['assignedById'] ?? '',
      status: map['status'] ?? 'لم تبدأ بعد',
      priority: (map['priority'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'assignedTo': assignedTo,
      'assignedById': assignedById,
      'status': status,
      'priority': priority,
    };
  }
}

class TaskProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> fetchTasks(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .get();

      _tasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(Task task) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('tasks').add(task.toMap());
      await fetchTasks(task.assignedTo);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('tasks').doc(taskId).update({'status': newStatus});
      await fetchTasks(_tasks.firstWhere((t) => t.id == taskId).assignedTo);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('tasks').doc(taskId).delete();
      await fetchTasks(_tasks.firstWhere((t) => t.id == taskId).assignedTo);
    } catch (e) {
      rethrow;
    }
  }

  void _safeNotify() {
    if (_isLoading) return;
    notifyListeners();
  }
}
