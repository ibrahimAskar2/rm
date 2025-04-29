import 'package:flutter/material.dart';

class StatisticsData {
  final String category;
  final double value;
  final Color color;

  StatisticsData({
    required this.category,
    required this.value,
    required this.color,
  });
}

class StatisticsProvider extends ChangeNotifier {
  List<StatisticsData> _attendanceStats = [];
  List<StatisticsData> _taskStats = [];
  bool _isLoading = false;

  List<StatisticsData> get attendanceStats => _attendanceStats;
  List<StatisticsData> get taskStats => _taskStats;
  bool get isLoading => _isLoading;

  Future<void> fetchStatistics(String userId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    // محاكاة جلب إحصائيات الحضور
    _attendanceStats = [
      StatisticsData(
        category: 'حضور',
        value: 85,
        color: Colors.green,
      ),
      StatisticsData(
        category: 'غياب',
        value: 10,
        color: Colors.red,
      ),
      StatisticsData(
        category: 'تأخير',
        value: 5,
        color: Colors.orange,
      ),
    ];

    // محاكاة جلب إحصائيات المهام
    _taskStats = [
      StatisticsData(
        category: 'مكتملة',
        value: 70,
        color: Colors.blue,
      ),
      StatisticsData(
        category: 'قيد التنفيذ',
        value: 20,
        color: Colors.amber,
      ),
      StatisticsData(
        category: 'متأخرة',
        value: 10,
        color: Colors.red,
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }
}
