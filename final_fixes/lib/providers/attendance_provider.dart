import 'package:flutter/material.dart';

class AttendanceRecord {
  final String id;
  final String userId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status;
  final String notes;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.notes = '',
  });
}

class AttendanceProvider extends ChangeNotifier {
  final List<AttendanceRecord> _records = [];
  bool _isLoading = false;

  List<AttendanceRecord> get records => _records;
  bool get isLoading => _isLoading;

  Future<void> fetchAttendanceRecords(String userId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    // محاكاة جلب سجلات الحضور
    _records.clear();
    _records.addAll([
      AttendanceRecord(
        id: '1',
        userId: userId,
        checkInTime: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
        checkOutTime: DateTime.now().subtract(const Duration(days: 1)),
        status: 'مكتمل',
      ),
      AttendanceRecord(
        id: '2',
        userId: userId,
        checkInTime: DateTime.now().subtract(const Duration(hours: 8)),
        checkOutTime: null,
        status: 'قيد التقدم',
      ),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkIn(String userId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _records.add(
      AttendanceRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        checkInTime: DateTime.now(),
        status: 'قيد التقدم',
      ),
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkOut(String recordId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final index = _records.indexWhere((record) => record.id == recordId);
    if (index != -1) {
      final record = _records[index];
      _records[index] = AttendanceRecord(
        id: record.id,
        userId: record.userId,
        checkInTime: record.checkInTime,
        checkOutTime: DateTime.now(),
        status: 'مكتمل',
        notes: record.notes,
      );
    }

    _isLoading = false;
    notifyListeners();
  }
}
