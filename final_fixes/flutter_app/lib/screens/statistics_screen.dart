import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/statistics_model.dart';
import '../services/statistics_service.dart';
import '../providers/user_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _statisticsService = StatisticsService();
  bool _isLoading = true;
  Statistics? _statistics;
  String _selectedPeriod = 'week';
  String _selectedChart = 'messages';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final userId = context.read<UserProvider>().user?.uid;
      if (userId != null) {
        final stats = await _statisticsService.getUserStatistics(userId);
        setState(() {
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الإحصائيات: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_statistics == null) {
      return const Center(child: Text('لا توجد إحصائيات متاحة'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإحصائيات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildChartSelector(),
            const SizedBox(height: 16),
            _buildChart(),
            const SizedBox(height: 24),
            _buildDetailedStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          'إجمالي الرسائل',
          _statistics!.totalMessages.toString(),
          Icons.message,
          Colors.blue,
        ),
        _buildSummaryCard(
          'الدردشات',
          _statistics!.totalChats.toString(),
          Icons.chat,
          Colors.green,
        ),
        _buildSummaryCard(
          'المجموعات',
          _statistics!.totalGroups.toString(),
          Icons.group,
          Colors.orange,
        ),
        _buildSummaryCard(
          'الوسائط',
          _statistics!.totalMediaMessages.toString(),
          Icons.photo,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSelector() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedPeriod,
            decoration: const InputDecoration(
              labelText: 'الفترة',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'week', child: Text('أسبوع')),
              DropdownMenuItem(value: 'month', child: Text('شهر')),
              DropdownMenuItem(value: 'year', child: Text('سنة')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedPeriod = value);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedChart,
            decoration: const InputDecoration(
              labelText: 'نوع الرسم البياني',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'messages', child: Text('الرسائل')),
              DropdownMenuItem(value: 'media', child: Text('الوسائط')),
              DropdownMenuItem(value: 'users', child: Text('المستخدمين')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedChart = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    switch (_selectedChart) {
      case 'messages':
        return _buildMessagesChart();
      case 'media':
        return _buildMediaChart();
      case 'users':
        return _buildUsersChart();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMessagesChart() {
    final data = _getChartData();
    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: true),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaChart() {
    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: _statistics!.totalImageMessages.toDouble(),
              title: 'صور',
              color: Colors.blue,
            ),
            PieChartSectionData(
              value: _statistics!.totalVoiceMessages.toDouble(),
              title: 'صوت',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersChart() {
    final userData = _statistics!.messagesPerUser.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: userData.first.value.toDouble(),
          barGroups: userData.map((entry) {
            return BarChartGroupData(
              x: userData.indexOf(entry),
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  color: Colors.blue,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  List<FlSpot> _getChartData() {
    final data = _statistics!.messagesPerDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.toDouble());
    }).toList();
  }

  Widget _buildDetailedStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إحصائيات مفصلة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('الرسائل النصية', _statistics!.totalMessages - _statistics!.totalMediaMessages),
            _buildStatRow('الرسائل الصوتية', _statistics!.totalVoiceMessages),
            _buildStatRow('الرسائل المصورة', _statistics!.totalImageMessages),
            _buildStatRow('الدردشات الخاصة', _statistics!.totalPrivateChats),
            _buildStatRow('المجموعات', _statistics!.totalGroups),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
