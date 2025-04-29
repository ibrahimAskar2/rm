import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class ChatService {
  // Singleton pattern
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // Firebase instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final CollectionReference _messagesCollection = FirebaseFirestore.instance.collection('messages');
  final CollectionReference _chatsCollection = FirebaseFirestore.instance.collection('chats');

  // User context
  String? _currentUserId;
  String? _currentUserName;

  void setCurrentUser(String userId, String userName) {
    _currentUserId = userId;
    _currentUserName = userName;
  }

  // الحصول على قائمة الدردشات للمستخدم
  Stream<QuerySnapshot> getChats() {
    if (_currentUserId == null) {
      throw Exception('User not set');
    }

    try {
      return _firestore
          .collection('chats')
          .where('participants', arrayContains: _currentUserId)
          .orderBy('lastMessageTimestamp', descending: true)
          .snapshots();
    } catch (e) {
      print('Error getting chats: $e');
      rethrow;
    }
  }

  // الحصول على معلومات المستخدم
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user info: $e');
      rethrow;
    }
  }

  // إنشاء دردشة خاصة
  Future<String> createPrivateChat(String otherUserId) async {
    if (_currentUserId == null) {
      throw Exception('User not set');
    }

    try {
      // التحقق من وجود دردشة سابقة بين المستخدمين
      final querySnapshot = await _firestore
          .collection('chats')
          .where('type', isEqualTo: 'private')
          .where('participants', arrayContains: _currentUserId)
          .get();
      
      // إذا وجدت دردشة سابقة، أعد معرفها
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      
      // إنشاء دردشة جديدة
      final chatRef = _firestore.collection('chats').doc();
      await chatRef.set({
        'type': 'private',
        'participants': [_currentUserId, otherUserId],
        'createdAt': Timestamp.now(),
        'lastMessage': '',
        'lastMessageTimestamp': Timestamp.now(),
      });
      
      return chatRef.id;
    } catch (e) {
      print('Error creating private chat: $e');
      rethrow;
    }
  }

  // إنشاء دردشة جماعية
  Future<String> createGroupChat(String name, List<String> participants) async {
    if (_currentUserId == null) {
      throw Exception('User not set');
    }

    try {
      // إنشاء دردشة جديدة
      final chatRef = _firestore.collection('chats').doc();
      await chatRef.set({
        'type': 'group',
        'name': name,
        'participants': [...participants, _currentUserId],
        'admin': _currentUserId,
        'createdAt': Timestamp.now(),
        'lastMessage': '',
        'lastMessageTimestamp': Timestamp.now(),
      });
      
      return chatRef.id;
    } catch (e) {
      print('Error creating group chat: $e');
      rethrow;
    }
  }

  // إضافة مشاركين إلى مجموعة
  Future<void> addParticipantsToGroup(String chatId, List<String> newParticipants) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'participants': FieldValue.arrayUnion(newParticipants),
      });
    } catch (e) {
      print('Error adding participants to group: $e');
      rethrow;
    }
  }

  // تعليم الرسالة كمستلمة
  Future<void> markMessageAsDelivered(String chatId, String messageId) async {
    if (_currentUserId == null) {
      throw Exception('User not set');
    }

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'deliveredTo': FieldValue.arrayUnion([_currentUserId]),
          });
    } catch (e) {
      print('Error marking message as delivered: $e');
      rethrow;
    }
  }

  // تعليم الرسالة كمقروءة
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    if (_currentUserId == null) {
      throw Exception('User not set');
    }

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'readBy': FieldValue.arrayUnion([_currentUserId]),
          });
    } catch (e) {
      print('Error marking message as read: $e');
      rethrow;
    }
  }

  // إرسال رسالة نصية
  Future<void> sendTextMessage(String chatId, String text) async {
    if (_currentUserId == null || _currentUserName == null) {
      throw Exception('User not set');
    }

    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      
      await messageRef.set({
        'type': 'text',
        'text': text,
        'senderId': _currentUserId,
        'senderName': _currentUserName,
        'timestamp': Timestamp.now(),
        'readBy': [_currentUserId],
        'deliveredTo': [_currentUserId],
      });
      
      // تحديث آخر رسالة في الدردشة
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTimestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error sending text message: $e');
      rethrow;
    }
  }

  // إرسال رسالة صوتية
  Future<void> sendVoiceMessage(String chatId, File audioFile) async {
    if (_currentUserId == null || _currentUserName == null) {
      throw Exception('User not set');
    }

    try {
      // رفع الملف الصوتي إلى Firebase Storage
      final storageRef = _storage.ref().child('chats/$chatId/voice/${DateTime.now().millisecondsSinceEpoch}.m4a');
      await storageRef.putFile(audioFile);
      final downloadUrl = await storageRef.getDownloadURL();
      
      // إنشاء رسالة جديدة
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      
      await messageRef.set({
        'type': 'voice',
        'url': downloadUrl,
        'senderId': _currentUserId,
        'senderName': _currentUserName,
        'timestamp': Timestamp.now(),
        'readBy': [_currentUserId],
        'deliveredTo': [_currentUserId],
      });
      
      // تحديث آخر رسالة في الدردشة
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': 'رسالة صوتية',
        'lastMessageTimestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error sending voice message: $e');
      rethrow;
    }
  }

  // إرسال صورة
  Future<void> sendImageMessage(String chatId, File imageFile) async {
    if (_currentUserId == null || _currentUserName == null) {
      throw Exception('User not set');
    }

    try {
      // رفع الصورة إلى Firebase Storage
      final storageRef = _storage.ref().child('chats/$chatId/images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();
      
      // إنشاء رسالة جديدة
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      
      await messageRef.set({
        'type': 'image',
        'url': downloadUrl,
        'senderId': _currentUserId,
        'senderName': _currentUserName,
        'timestamp': Timestamp.now(),
        'readBy': [_currentUserId],
        'deliveredTo': [_currentUserId],
      });
      
      // تحديث آخر رسالة في الدردشة
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': 'صورة',
        'lastMessageTimestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error sending image message: $e');
      rethrow;
    }
  }

  // الحصول على رسائل الدردشة
  Stream<List<Message>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Message.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    });
  }

  // البحث في رسائل الدردشة
  Future<List<Message>> searchMessages(String chatId, String searchText) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('text', isGreaterThanOrEqualTo: searchText)
          .where('text', isLessThanOrEqualTo: searchText + '\uf8ff')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Message.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error searching messages: $e');
      rethrow;
    }
  }

  // حذف رسالة
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  // تعديل رسالة
  Future<void> editMessage(String chatId, String messageId, String newText) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'text': newText,
        'isEdited': true,
        'editedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error editing message: $e');
      rethrow;
    }
  }

  // الرد على رسالة
  Future<void> replyToMessage(String chatId, String messageId, String replyText) async {
    if (_currentUserId == null || _currentUserName == null) {
      throw Exception('User not set');
    }

    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      
      await messageRef.set({
        'type': 'text',
        'text': replyText,
        'senderId': _currentUserId,
        'senderName': _currentUserName,
        'timestamp': Timestamp.now(),
        'readBy': [_currentUserId],
        'deliveredTo': [_currentUserId],
        'replyTo': messageId,
      });
      
      // تحديث آخر رسالة في الدردشة
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': replyText,
        'lastMessageTimestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error replying to message: $e');
      rethrow;
    }
  }

  // رفع صورة
  Future<String> uploadImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = _storage.ref().child('chat_images/$fileName');
      
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }
}
