import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // الحصول على معلومات المستخدم
  Future<User?> getUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return User.fromMap(userDoc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      rethrow;
    }
  }

  // تحديث معلومات المستخدم
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // تحديث صورة الملف الشخصي
  Future<String> updateProfileImage(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      
      await _firestore.collection('users').doc(userId).update({
        'profileImage': downloadUrl,
      });
      
      return downloadUrl;
    } catch (e) {
      print('Error updating profile image: $e');
      rethrow;
    }
  }

  // تحديث حالة المستخدم
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': status,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user status: $e');
      rethrow;
    }
  }

  // تحديث حالة الاتصال
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating online status: $e');
      rethrow;
    }
  }

  // إضافة مستخدم إلى قائمة المحظورين
  Future<void> blockUser(String userId, String blockedUserId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
      });
    } catch (e) {
      print('Error blocking user: $e');
      rethrow;
    }
  }

  // إزالة مستخدم من قائمة المحظورين
  Future<void> unblockUser(String userId, String blockedUserId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
      });
    } catch (e) {
      print('Error unblocking user: $e');
      rethrow;
    }
  }

  // إضافة دردشة إلى المفضلة
  Future<void> addToFavorites(String userId, String chatId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favoriteChats': FieldValue.arrayUnion([chatId]),
      });
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  // إزالة دردشة من المفضلة
  Future<void> removeFromFavorites(String userId, String chatId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favoriteChats': FieldValue.arrayRemove([chatId]),
      });
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  // تحديث إعدادات الإشعارات
  Future<void> updateNotificationSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'notifications': settings,
      });
    } catch (e) {
      print('Error updating notification settings: $e');
      rethrow;
    }
  }

  // الحصول على قائمة المستخدمين المحظورين
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      return List<String>.from(userData?['blockedUsers'] ?? []);
    } catch (e) {
      print('Error getting blocked users: $e');
      rethrow;
    }
  }

  // الحصول على قائمة الدردشات المفضلة
  Future<List<String>> getFavoriteChats(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      return List<String>.from(userData?['favoriteChats'] ?? []);
    } catch (e) {
      print('Error getting favorite chats: $e');
      rethrow;
    }
  }

  // الحصول على إعدادات الإشعارات
  Future<Map<String, dynamic>> getNotificationSettings(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      return Map<String, dynamic>.from(userData?['notifications'] ?? {});
    } catch (e) {
      print('Error getting notification settings: $e');
      rethrow;
    }
  }
} 