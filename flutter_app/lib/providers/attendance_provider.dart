import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<AttendanceRecord> _records = [];
  List<User> _presentEmployees = [];
  int _absentCount = 0;
  User? _featuredEmployee;
  bool _isLoading = false;

  List<AttendanceRecord> get records => _records;
  List<User> get presentEmployees => _presentEmployees;
  int get absentCount => _absentCount;
  User? get featuredEmployee => _featuredEmployee;
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

  Future<void> refreshDashboardData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // الحصول على قائمة الموظفين الحاضرين
      final presentSnapshot = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: DateTime.now().toIso8601String().split('T')[0])
          .where('status', isEqualTo: 'present')
          .get();

      _presentEmployees = presentSnapshot.docs
          .map((doc) => User.fromMap(doc.id, doc.data()))
          .toList();

      // حساب عدد الغائبين
      final absentSnapshot = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: DateTime.now().toIso8601String().split('T')[0])
          .where('status', isEqualTo: 'absent')
          .get();

      _absentCount = absentSnapshot.docs.length;

      // تحديد الموظف المميز
      if (_presentEmployees.isNotEmpty) {
        _featuredEmployee = _presentEmployees.first;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> checkIn(String userId) async {
    try {
      await _firestore.collection('attendance').add({
        'userId': userId,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'checkIn': Timestamp.now(),
        'status': 'present',
      });
      await refreshDashboardData();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> checkOut(String userId) async {
    try {
      final attendanceDoc = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: DateTime.now().toIso8601String().split('T')[0])
          .get();

      if (attendanceDoc.docs.isNotEmpty) {
        await _firestore
            .collection('attendance')
            .doc(attendanceDoc.docs.first.id)
            .update({
          'checkOut': Timestamp.now(),
        });
      }
      await refreshDashboardData();
    } catch (e) {
      rethrow;
    }
  }
}
