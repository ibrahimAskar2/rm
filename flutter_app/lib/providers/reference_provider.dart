import 'package:flutter/material.dart';

class Reference {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String fileType;
  final DateTime uploadDate;
  final String uploadedBy;

  Reference({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileType,
    required this.uploadDate,
    required this.uploadedBy,
  });
}

class ReferenceProvider extends ChangeNotifier {
  final List<Reference> _references = [];
  bool _isLoading = false;

  List<Reference> get references => _references;
  bool get isLoading => _isLoading;

  Future<void> fetchReferences() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    // محاكاة جلب المرجعيات
    _references.clear();
    _references.addAll([
      Reference(
        id: '1',
        title: 'دليل المستخدم',
        description: 'دليل شامل لاستخدام التطبيق وجميع ميزاته',
        fileUrl: 'https://example.com/user_guide.pdf',
        fileType: 'pdf',
        uploadDate: DateTime.now().subtract(const Duration(days: 30)),
        uploadedBy: 'أحمد محمد',
      ),
      Reference(
        id: '2',
        title: 'قواعد العمل',
        description: 'قواعد وأنظمة العمل في الفريق',
        fileUrl: 'https://example.com/work_rules.docx',
        fileType: 'docx',
        uploadDate: DateTime.now().subtract(const Duration(days: 15)),
        uploadedBy: 'محمد علي',
      ),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addReference(Reference reference) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _references.add(reference);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteReference(String id) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _references.removeWhere((reference) => reference.id == id);

    _isLoading = false;
    notifyListeners();
  }
}
