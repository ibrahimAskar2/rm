import 'dart:typed_data'; // أضف هذا في الأعلى
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/user_provider.dart';

class AttendanceController extends StatefulWidget {
  const AttendanceController({super.key});

  @override
  State<AttendanceController> createState() => _AttendanceControllerState();
}

// ... (الاستيرادات والأجزاء الأخرى بدون تغيير)

class _AttendanceControllerState extends State<AttendanceController> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AttendanceProvider>(context, listen: false).refreshDashboardData();
      }
    });
  }

  Future<void> _confirmCheckIn() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;

    final confirmed = await showDialog<bool>(...);
    
    if (confirmed == true) {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final success = await attendanceProvider.checkIn(user.uid); // <-- أضف user.uid
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(...);
    }
  }

  Future<void> _confirmCheckOut() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;

    final confirmed = await showDialog<bool>(...);
    
    if (confirmed == true) {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final success = await attendanceProvider.checkOut(user.uid); // <-- أضف user.uid
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(...);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, AttendanceProvider>(
      builder: (context, userProvider, attendanceProvider, child) {
        final user = userProvider.user;
        
        if (user == null) { // <-- احذف userData إذا غير مستخدم
          return const Center(child: Text('يرجى تسجيل الدخول أولاً'));
        }
        
        return Column(...);
      },
    );
  }

  Widget _buildDashboard(...) {
    // عدل جميع الأماكن التي تستخدم ['name'] إلى .name
    attendanceProvider.featuredEmployee?.name ?? '-'
  }
}
