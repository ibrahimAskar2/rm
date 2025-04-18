import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reference_provider.dart';

class ReferencesScreen extends StatefulWidget {
  const ReferencesScreen({super.key});

  @override
  State<ReferencesScreen> createState() => _ReferencesScreenState();
}

class _ReferencesScreenState extends State<ReferencesScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await Provider.of<ReferenceProvider>(context, listen: false).fetchReferences();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final referenceProvider = Provider.of<ReferenceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المرجعيات'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: referenceProvider.references.isEmpty
                  ? const Center(
                      child: Text('لا توجد مرجعيات'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: referenceProvider.references.length,
                      itemBuilder: (context, index) {
                        final reference = referenceProvider.references[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      reference.fileType == 'pdf'
                                          ? Icons.picture_as_pdf
                                          : reference.fileType == 'docx'
                                              ? Icons.description
                                              : Icons.insert_drive_file,
                                      color: Theme.of(context).primaryColor,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reference.title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            reference.description,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'تم الرفع بواسطة: ${reference.uploadedBy}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'تاريخ الرفع: ${reference.uploadDate.day}/${reference.uploadDate.month}/${reference.uploadDate.year}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // فتح الملف
                                  },
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('فتح الملف'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 40),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // إضافة مرجعية جديدة
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
