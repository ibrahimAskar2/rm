import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class TaskService {
  // Singleton pattern
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  final FirestoreService _firestore = FirestoreService();
  final CollectionReference _tasksCollection = FirebaseFirestore.instance.collection('tasks');

  // الحصول على قائمة المهام المخصصة للمستخدم مع التحميل المتدرج
  Future<List<Task>> getUserTasks({
    required String userId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
    String? status,
  }) async {
    try {
      Query query = _tasksCollection
          .where('assigneeId', isEqualTo: userId)
          .orderBy('createdAt', descending: false);
      
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
      final docSnapshot = await _tasksCollection.doc(taskId).get();
      
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
    required String assigneeId,
    required String assigneeName,
    required String assignerId,
    required String assignerName,
    DateTime? dueDate,
    String? priority,
    List<String>? tags,
  }) async {
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      assignerId: assignerId,
      assignerName: assignerName,
      status: 'pending',
      createdAt: DateTime.now(),
      dueDate: dueDate,
      priority: priority ?? 'medium',
      tags: tags ?? [],
    );

    await _tasksCollection.doc(task.id).set(task.toMap());
    return task;
  }

  // تحديث حالة مهمة
  Future<void> updateTaskStatus(String taskId, String status) async {
    await _tasksCollection.doc(taskId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // إضافة تعليق إلى مهمة
  Future<void> addComment(String taskId, String text, String userId, String userName) async {
    final comment = {
      'text': text,
      'userId': userId,
      'userName': userName,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _tasksCollection.doc(taskId).update({
      'comments': FieldValue.arrayUnion([comment]),
    });
  }

  // إضافة مرفق إلى مهمة
  Future<void> addAttachment(String taskId, String name, String type, int size, String url, String uploaderId, String uploaderName) async {
    final attachment = {
      'name': name,
      'type': type,
      'size': size,
      'url': url,
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'uploadedAt': FieldValue.serverTimestamp(),
    };

    await _tasksCollection.doc(taskId).update({
      'attachments': FieldValue.arrayUnion([attachment]),
    });
  }

  // الحصول على إحصائيات المهام للمستخدم
  Future<Map<String, dynamic>> getTaskStatistics(String userId) async {
    try {
      // الحصول على جميع مهام المستخدم
      final querySnapshot = await _tasksCollection
          .where('assigneeId', isEqualTo: userId)
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

  Stream<List<Task>> getTasksStream(String userId) {
    return _tasksCollection
        .where('assigneeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Task.fromMap(data);
      }).toList();
    });
  }

  Future<List<Task>> searchTasks(String query) async {
    final snapshot = await _tasksCollection
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Task.fromMap(data);
    }).toList();
  }
}
