import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _settingsKey = 'app_settings';

  // الحصول على إعدادات التطبيق
  Future<AppSettings> getSettings(String userId) async {
    try {
      // محاولة الحصول على الإعدادات من Firestore
      final settingsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('app_settings')
          .get();

      if (settingsDoc.exists) {
        return AppSettings.fromMap(settingsDoc.data()!);
      }

      // إذا لم تكن الإعدادات موجودة، قم بإنشاء إعدادات افتراضية
      final defaultSettings = AppSettings();
      await _saveSettings(userId, defaultSettings);
      return defaultSettings;
    } catch (e) {
      print('Error getting settings: $e');
      rethrow;
    }
  }

  // حفظ إعدادات التطبيق
  Future<void> saveSettings(String userId, AppSettings settings) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('app_settings')
          .set(settings.toMap());

      // حفظ نسخة محلية من الإعدادات
      await _saveLocalSettings(settings);
    } catch (e) {
      print('Error saving settings: $e');
      rethrow;
    }
  }

  // حفظ إعدادات محلية
  Future<void> _saveLocalSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, settings.toMap().toString());
    } catch (e) {
      print('Error saving local settings: $e');
    }
  }

  // الحصول على الإعدادات المحلية
  Future<AppSettings?> getLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsString = prefs.getString(_settingsKey);
      if (settingsString != null) {
        // تحويل النص إلى Map
        final settingsMap = Map<String, dynamic>.from(
          Map<String, dynamic>.from(
            settingsString as Map,
          ),
        );
        return AppSettings.fromMap(settingsMap);
      }
      return null;
    } catch (e) {
      print('Error getting local settings: $e');
      return null;
    }
  }

  // تحديث إعدادات الإشعارات
  Future<void> updateNotificationSettings(
    String userId,
    Map<String, bool> settings,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('app_settings')
          .update({
        'notificationSettings': settings,
      });
    } catch (e) {
      print('Error updating notification settings: $e');
      rethrow;
    }
  }

  // تحديث إعدادات الخصوصية
  Future<void> updatePrivacySettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('app_settings')
          .update({
        'privacySettings': settings,
      });
    } catch (e) {
      print('Error updating privacy settings: $e');
      rethrow;
    }
  }

  // تحديث إعدادات الدردشة
  Future<void> updateChatSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('app_settings')
          .update({
        'chatSettings': settings,
      });
    } catch (e) {
      print('Error updating chat settings: $e');
      rethrow;
    }
  }

  // تحديث المظهر
  Future<void> updateTheme(String userId, String theme) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('app_settings')
          .update({
        'theme': theme,
      });
    } catch (e) {
      print('Error updating theme: $e');
      rethrow;
    }
  }

  // تحديث اللغة
  Future<void> updateLanguage(String userId, String language) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('app_settings')
          .update({
        'language': language,
      });
    } catch (e) {
      print('Error updating language: $e');
      rethrow;
    }
  }

  // تحديث وضع الظلام
  Future<void> updateDarkMode(String userId, bool darkMode) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('app_settings')
          .update({
        'darkMode': darkMode,
      });
    } catch (e) {
      print('Error updating dark mode: $e');
      rethrow;
    }
  }
} 