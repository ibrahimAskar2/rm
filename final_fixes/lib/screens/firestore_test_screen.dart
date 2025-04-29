import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class FirestoreTestScreen extends StatefulWidget {
  const FirestoreTestScreen({super.key});

  @override
  State<FirestoreTestScreen> createState() => _FirestoreTestScreenState();
}

class _FirestoreTestScreenState extends State<FirestoreTestScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, dynamic>? _testDocument;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري اختبار الاتصال...';
    });

    try {
      bool isConnected = await _firestoreService.testConnection();
      setState(() {
        _statusMessage = isConnected ? 'تم الاتصال بنجاح' : 'فشل الاتصال';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'حدث خطأ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTestDocument() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري إضافة وثيقة الاختبار...';
    });

    try {
      await _firestoreService.addTestDocument();
      setState(() {
        _statusMessage = 'تم إضافة وثيقة الاختبار بنجاح';
      });
      _getTestDocument();
    } catch (e) {
      setState(() {
        _statusMessage = 'حدث خطأ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getTestDocument() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري قراءة وثيقة الاختبار...';
    });

    try {
      final document = await _firestoreService.getTestDocument();
      setState(() {
        _testDocument = document;
        _statusMessage = 'تم قراءة وثيقة الاختبار بنجاح';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'حدث خطأ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار Firestore'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: const Text('اختبار الاتصال'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _addTestDocument,
              child: const Text('إضافة وثيقة اختبار'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _getTestDocument,
              child: const Text('قراءة وثيقة الاختبار'),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Text(
                _statusMessage,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            if (_testDocument != null) ...[
              const Text(
                'محتوى وثيقة الاختبار:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _testDocument!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 