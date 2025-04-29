import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatConversation {
  final String id;
  final List<String> participantIds;
  final List<String> participantNames;
  final DateTime lastMessageTime;
  final String lastMessageContent;
  final bool hasUnreadMessages;

  ChatConversation({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.lastMessageTime,
    required this.lastMessageContent,
    this.hasUnreadMessages = false,
  });
}

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentChatId;
  List<Message> _messages = [];
  Map<String, User> _usersInfo = {};
  bool _isLoading = false;

  String? get currentChatId => _currentChatId;
  List<Message> get messages => _messages;
  Map<String, User> get usersInfo => _usersInfo;
  bool get isLoading => _isLoading;

  Future<void> setCurrentChat(String chatId) async {
    _currentChatId = chatId;
    await loadMessages();
    notifyListeners();
  }

  Future<void> loadMessages() async {
    if (_currentChatId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(_currentChatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .get();

      _messages = messagesSnapshot.docs
          .map((doc) => Message.fromMap(doc.id, doc.data()))
          .toList();

      // تحميل معلومات المستخدمين
      final userIds = _messages
          .map((message) => message.senderId)
          .toSet()
          .toList();

      for (final userId in userIds) {
        if (!_usersInfo.containsKey(userId)) {
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            _usersInfo[userId] = User.fromMap(userId, userDoc.data()!);
          }
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendTextMessage(String content, String senderId, String receiverId) async {
    if (_currentChatId == null) return;

    try {
      final message = Message.createText(
        chatId: _currentChatId!,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
      );

      await _firestore
          .collection('chats')
          .doc(_currentChatId)
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());

      _messages.insert(0, message);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendImageMessage(String imageUrl, String senderId, String receiverId) async {
    if (_currentChatId == null) return;

    try {
      final message = Message.createMedia(
        chatId: _currentChatId!,
        senderId: senderId,
        receiverId: receiverId,
        content: 'صورة',
        mediaType: 'image',
        mediaUrl: imageUrl,
        mediaData: {'url': imageUrl},
      );

      await _firestore
          .collection('chats')
          .doc(_currentChatId)
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());

      _messages.insert(0, message);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> searchChatMessages(String query) async {
    if (_currentChatId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(_currentChatId)
          .collection('messages')
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      _messages = messagesSnapshot.docs
          .map((doc) => Message.fromMap(doc.id, doc.data()))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    if (_currentChatId == null) return;

    try {
      final message = _messages.firstWhere((m) => m.id == messageId);
      final updatedMessage = message.markAsReadBy(_usersInfo.keys.first);

      await _firestore
          .collection('chats')
          .doc(_currentChatId)
          .collection('messages')
          .doc(messageId)
          .update(updatedMessage.toMap());

      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = updatedMessage;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }
}
