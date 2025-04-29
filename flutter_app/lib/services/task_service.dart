import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../models/comment_model.dart'; // Added import for Comment class

class TaskService {
  // Singleton pattern
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  // Firebase instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // الحصول على قائمة المهام المخصصة للمستخدم مع التحميل المتدرج
  Future<List<Task>> getUserTasks({
    required String userId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
    String? status,
  }) async {
    try {
      Query query = _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .orderBy('dueDate', descending: false);
      
      // تصفية حسب الحالة إذا تم تحديدها
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      
      // إضافة التحميل المتدرج
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      // تحديد عدد النتائج
      query = query.limit(limit);
      
      final querySnapshot = await query.get();
      
      // تحويل البيانات إلى قائمة من كائنات Task
      final tasks = querySnapshot.docs.map((doc) {
        return Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      return tasks;
    } catch (e) {
      print('Error getting user tasks: $e');
      rethrow;
    }
  }

  // الحصول على تفاصيل مهمة محددة
  Future<Task?> getTaskDetails(String taskId) async {
    try {
      final docSnapshot = await _firestore
          .collection('tasks')
          .doc(taskId)
          .get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      return Task.fromMap(docSnapshot.id, docSnapshot.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting task details: $e');
      rethrow;
    }
  }

  // إنشاء مهمة جديدة
  Future<Task> createTask({
    required String title,
    required String description,
    required String assignerId,
    required String assignerName,
    required String assigneeId,
    required String assigneeName,
    required DateTime dueDate,
    int priority = 2,
  }) async {
    try {
      final task = Task.create(
        title: title,
        description: description,
        assignerId: assignerId,
        assignerName: assignerName,
        assigneeId: assigneeId,
        assigneeName: assigneeName,
        dueDate: dueDate,
        priority: priority,
      );

      await _firestore.collection('tasks').doc(task.id).set(task.toMap());
      return task;
    } catch (e) {
      print('Error creating task: $e');
      rethrow;
    }
  }

  // تحديث حالة مهمة
  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': status,
        'completedAt': status == 'completed' ? Timestamp.now() : null,
      });
    } catch (e) {
      print('Error updating task status: $e');
      rethrow;
    }
  }

  // إضافة تعليق إلى مهمة
  Future<void> addComment(String taskId, String text, String userId, String userName) async {
    try {
      final comment = {
        'text': text,
        'userId': userId,
        'userName': userName,
        'timestamp': Timestamp.now(),
      };

      await _firestore.collection('tasks').doc(taskId).update({
        'comments': FieldValue.arrayUnion([comment]),
      });
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  // إضافة مرفق إلى مهمة
  Future<void> addAttachment(String taskId, String name, String url, String type, String size, String uploaderId, String uploaderName) async {
    try {
      final attachment = {
        'name': name,
        'url': url,
        'type': type,
        'size': size,
        'uploaderId': uploaderId,
        'uploaderName': uploaderName,
        'timestamp': Timestamp.now(),
      };

      await _firestore.collection('tasks').doc(taskId).update({
        'attachments': FieldValue.arrayUnion([attachment]),
      });
    } catch (e) {
      print('Error adding attachment: $e');
      rethrow;
    }
  }

  // الحصول على إحصائيات المهام للمستخدم
  Future<Map<String, dynamic>> getTaskStatistics(String userId) async {
    try {
      // الحصول على جميع مهام المستخدم
      final querySnapshot = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .get();
      
      // تحويل البيانات إلى قائمة من كائنات Task
      final tasks = querySnapshot.docs.map((doc) {
        return Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      // حساب الإحصائيات
      int totalTasks = tasks.length;
      int pendingTasks = tasks.where((task) => task.status == 'pending').length;
      int inProgressTasks = tasks.where((task) => task.status == 'in_progress').length;
      int completedTasks = tasks.where((task) => task.status == 'completed').length;
      int cancelledTasks = tasks.where((task) => task.status == 'cancelled').length;
      int overdueTasks = tasks.where((task) => task.isOverdue()).length;
      
      // حساب معدل الإنجاز
      double completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;
      
      // حساب معدل التأخير
      double overdueRate = totalTasks > 0 ? (overdueTasks / totalTasks) * 100 : 0;
      
      return {
        'totalTasks': totalTasks,
        'pendingTasks': pendingTasks,
        'inProgressTasks': inProgressTasks,
        'completedTasks': completedTasks,
        'cancelledTasks': cancelledTasks,
        'overdueTasks': overdueTasks,
        'completionRate': completionRate,
        'overdueRate': overdueRate,
      };
    } catch (e) {
      print('Error getting task statistics: $e');
      rethrow;
    }
  }

  Stream<List<Task>> getTasks() {
    return _firestore
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<Task>> getUserTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('assigneeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}
