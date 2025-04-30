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

    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      _records.clear();
      _records.addAll(
        snapshot.docs.map((doc) => AttendanceRecord(
          id: doc.id,
          userId: doc.data()['userId'],
          checkInTime: (doc.data()['checkIn'] as Timestamp).toDate(),
          checkOutTime: doc.data()['checkOut']?.toDate(),
          status: doc.data()['status'],
          notes: doc.data()['notes'] ?? '',
        )).toList(),
      );
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboardData() async {
    try {
      _isLoading = true;
      notifyListeners();

      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      
      // جلب الحاضرين
      final presentSnapshot = await _firestore
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('date', isLessThan: Timestamp.fromDate(today.add(const Duration(days: 1))))
          .where('status', isEqualTo: 'present')
          .get();

      _presentEmployees = await _loadUsersFromSnapshot(presentSnapshot);

      // جلب الغائبين
      final absentSnapshot = await _firestore
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('date', isLessThan: Timestamp.fromDate(today.add(const Duration(days: 1))))
          .where('status', isEqualTo: 'absent')
          .get();

      _absentCount = absentSnapshot.docs.length;

      // تحديد الموظف المميز
      _featuredEmployee = _presentEmployees.isNotEmpty 
          ? _presentEmployees.reduce((a, b) => a.lastActive.isAfter(b.lastActive) ? a : b)
          : null;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<User>> _loadUsersFromSnapshot(QuerySnapshot snapshot) async {
    final List<User> users = [];
    for (final doc in snapshot.docs) {
      final userDoc = await _firestore.collection('users').doc(doc['userId']).get();
      if (userDoc.exists) {
        users.add(User.fromMap(userDoc.id, userDoc.data()!));
      }
    }
    return users;
  }

  Future<void> checkIn(String userId) async {
    try {
      final user = await _firestore.collection('users').doc(userId).get();
      if (!user.exists) throw Exception('المستخدم غير موجود');

      await _firestore.collection('attendance').add({
        'userId': userId,
        'date': Timestamp.now(),
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
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final attendanceDoc = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('date', isLessThan: Timestamp.fromDate(today.add(const Duration(days: 1))))
          .get();

      if (attendanceDoc.docs.isNotEmpty) {
        await _firestore.collection('attendance').doc(attendanceDoc.docs.first.id).update({
          'checkOut': Timestamp.now(),
        });
      }
      await refreshDashboardData();
    } catch (e) {
      rethrow;
    }
  }

  void _safeNotify() {
    if (_isLoading) return;
    notifyListeners();
  }
}
