import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;
  String? _name;
  String? _bio;
  String? _status;
  String? _phone;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userId = context.read<UserProvider>().user?.uid;
      if (userId != null) {
        final user = await _userService.getUser(userId);
        if (user != null) {
          setState(() {
            _name = user.name;
            _bio = user.bio;
            _status = user.status;
            _phone = user.phone;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في اختيار الصورة: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userId = context.read<UserProvider>().user?.uid;
      if (userId != null) {
        // تحديث الصورة إذا تم اختيارها
        if (_imageFile != null) {
          await _userService.updateProfileImage(userId, _imageFile!);
        }

        // تحديث البيانات الأخرى
        await _userService.updateUser(userId, {
          'name': _name,
          'bio': _bio,
          'status': _status,
          'phone': _phone,
        });

        setState(() => _isEditing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ البيانات بنجاح')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حفظ البيانات: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfileImage(),
              const SizedBox(height: 24),
              _buildProfileInfo(),
              const SizedBox(height: 24),
              _buildSettingsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: _imageFile != null
              ? FileImage(_imageFile!)
              : (context.read<UserProvider>().user?.photoURL != null
                  ? NetworkImage(context.read<UserProvider>().user!.photoURL!)
                  : null) as ImageProvider?,
          child: context.read<UserProvider>().user?.photoURL == null && _imageFile == null
              ? const Icon(Icons.person, size: 60)
              : null,
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: _pickImage,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        TextFormField(
          initialValue: _name,
          enabled: _isEditing,
          decoration: const InputDecoration(
            labelText: 'الاسم',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'الرجاء إدخال الاسم';
            }
            return null;
          },
          onChanged: (value) => _name = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _bio,
          enabled: _isEditing,
          decoration: const InputDecoration(
            labelText: 'نبذة شخصية',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) => _bio = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _status,
          enabled: _isEditing,
          decoration: const InputDecoration(
            labelText: 'الحالة',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _status = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _phone,
          enabled: _isEditing,
          decoration: const InputDecoration(
            labelText: 'رقم الهاتف',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) => _phone = value,
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الإعدادات',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingTile(
          'المستخدمين المحظورين',
          Icons.block,
          () {
            // TODO: Navigate to blocked users screen
          },
        ),
        _buildSettingTile(
          'الدردشات المفضلة',
          Icons.star,
          () {
            // TODO: Navigate to favorite chats screen
          },
        ),
        _buildSettingTile(
          'إعدادات الإشعارات',
          Icons.notifications,
          () {
            // TODO: Navigate to notification settings screen
          },
        ),
        _buildSettingTile(
          'تسجيل الخروج',
          Icons.logout,
          () {
            // TODO: Implement logout
          },
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSettingTile(String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : null,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
