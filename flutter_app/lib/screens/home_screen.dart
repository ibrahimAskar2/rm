import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/task_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      await Provider.of<TaskProvider>(context, listen: false)
          .fetchTasks(userProvider.user!.id);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرئيسية')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<UserProvider>(
                      builder: (context, userProvider, _) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: Text(
                                    userProvider.user?.name.substring(0, 1) ?? '',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userProvider.user?.name ?? 'زائر',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        userProvider.user?.role ?? '',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'المهام العاجلة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Consumer<TaskProvider>(
                      builder: (context, taskProvider, _) {
                        return taskProvider.tasks.isEmpty
                            ? const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: Text('لا توجد مهام عاجلة')),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: taskProvider.tasks.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final task = taskProvider.tasks[index];
                                  return Card(
                                    margin: EdgeInsets.zero,
                                    child: ListTile(
                                      title: Text(task.title),
                                      subtitle: Text(task.description),
                                      trailing: Chip(
                                        label: Text(
                                          task.status,
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: _getStatusColor(task.status),
                                      ),
                                    ),
                                  );
                                },
                              );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'قيد التنفيذ':
        return Colors.amber;
      case 'مكتملة':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}
