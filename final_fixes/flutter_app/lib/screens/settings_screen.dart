import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../models/settings_model.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  late AppSettings _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  // تخزين مؤقت للإعدادات
  late Map<String, dynamic> _tempSettings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final userId = context.read<AuthProvider>().currentUser?.uid;
      if (userId != null) {
        final settings = await _settingsService.getSettings(userId);
        setState(() {
          _settings = settings;
          _tempSettings = settings.toMap();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final userId = context.read<AuthProvider>().currentUser?.uid;
      if (userId != null) {
        await _settingsService.saveSettings(userId, _settings);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء حفظ الإعدادات'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _updateSetting(String key, dynamic value) {
    setState(() {
      _tempSettings[key] = value;
      _settings = AppSettings.fromMap(_tempSettings);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
              tooltip: 'حفظ الإعدادات',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSection(
            'المظهر',
            [
              _buildSwitchTile(
                title: 'الوضع الليلي',
                subtitle: 'تفعيل المظهر الداكن للتطبيق',
                value: _settings.darkMode,
                onChanged: (value) => _updateSetting('darkMode', value),
                icon: _settings.darkMode ? Icons.dark_mode : Icons.light_mode,
                iconColor: _settings.darkMode ? Colors.amber : Colors.blue,
              ),
              _buildDropdownTile(
                title: 'المظهر',
                subtitle: 'اختر مظهر التطبيق',
                value: _settings.theme,
                items: [
                  DropdownMenuItem(
                    value: 'light',
                    child: Row(
                      children: const [
                        Icon(Icons.light_mode, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('فاتح'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'dark',
                    child: Row(
                      children: const [
                        Icon(Icons.dark_mode, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('داكن'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'system',
                    child: Row(
                      children: const [
                        Icon(Icons.settings_suggest, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('تلقائي'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _updateSetting('theme', value);
                  }
                },
              ),
            ],
          ),
          _buildSection(
            'الإشعارات',
            [
              _buildSwitchTile(
                title: 'تفعيل الإشعارات',
                subtitle: 'استلام إشعارات من التطبيق',
                value: _settings.notificationsEnabled,
                onChanged: (value) => _updateSetting('notificationsEnabled', value),
                icon: Icons.notifications,
                iconColor: _settings.notificationsEnabled ? Colors.green : Colors.grey,
              ),
              if (_settings.notificationsEnabled) ...[
                _buildSwitchTile(
                  title: 'الصوت',
                  subtitle: 'تفعيل صوت الإشعارات',
                  value: _settings.soundEnabled,
                  onChanged: (value) => _updateSetting('soundEnabled', value),
                  icon: Icons.volume_up,
                  iconColor: _settings.soundEnabled ? Colors.green : Colors.grey,
                ),
                _buildSwitchTile(
                  title: 'الاهتزاز',
                  subtitle: 'تفعيل الاهتزاز عند الإشعارات',
                  value: _settings.vibrationEnabled,
                  onChanged: (value) => _updateSetting('vibrationEnabled', value),
                  icon: Icons.vibration,
                  iconColor: _settings.vibrationEnabled ? Colors.green : Colors.grey,
                ),
              ],
            ],
          ),
          _buildSection(
            'الخصوصية',
            [
              _buildSwitchTile(
                title: 'إشعارات القراءة',
                subtitle: 'إظهار حالة قراءة الرسائل',
                value: _settings.readReceiptsEnabled,
                onChanged: (value) => _updateSetting('readReceiptsEnabled', value),
                icon: Icons.done_all,
                iconColor: _settings.readReceiptsEnabled ? Colors.green : Colors.grey,
              ),
              _buildSwitchTile(
                title: 'مؤشر الكتابة',
                subtitle: 'إظهار حالة الكتابة في المحادثات',
                value: _settings.typingIndicatorEnabled,
                onChanged: (value) => _updateSetting('typingIndicatorEnabled', value),
                icon: Icons.edit,
                iconColor: _settings.typingIndicatorEnabled ? Colors.green : Colors.grey,
              ),
            ],
          ),
          _buildSection(
            'الدردشة',
            [
              _buildSwitchTile(
                title: 'تحميل الوسائط تلقائياً',
                subtitle: 'تحميل الصور والفيديوهات تلقائياً',
                value: _settings.autoDownloadMedia,
                onChanged: (value) => _updateSetting('autoDownloadMedia', value),
                icon: Icons.download,
                iconColor: _settings.autoDownloadMedia ? Colors.green : Colors.grey,
              ),
            ],
          ),
          _buildSection(
            'اللغة',
            [
              _buildDropdownTile(
                title: 'اللغة',
                subtitle: 'اختر لغة التطبيق',
                value: _settings.language,
                items: [
                  DropdownMenuItem(
                    value: 'ar',
                    child: Row(
                      children: const [
                        Icon(Icons.language, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('العربية'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Row(
                      children: const [
                        Icon(Icons.language, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('English'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _updateSetting('language', value);
                  }
                },
              ),
            ],
          ),
          _buildSection(
            'حول التطبيق',
            [
              _buildInfoTile(
                title: 'الإصدار',
                subtitle: '1.0.0',
                icon: Icons.info_outline,
              ),
              _buildNavigationTile(
                title: 'سياسة الخصوصية',
                icon: Icons.privacy_tip_outlined,
                onTap: () {
                  // TODO: Navigate to privacy policy
                },
              ),
              _buildNavigationTile(
                title: 'شروط الاستخدام',
                icon: Icons.description_outlined,
                onTap: () {
                  // TODO: Navigate to terms of service
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: value ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: value ? Colors.green : Colors.grey,
          ),
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        secondary: Icon(
          icon,
          color: iconColor,
        ),
        activeColor: Colors.green,
        activeTrackColor: Colors.green.withOpacity(0.5),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withOpacity(0.5),
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
        onTap: onTap,
      ),
    );
  }
}
