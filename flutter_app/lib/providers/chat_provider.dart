import 'package:flutter/material.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });
}

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
  final List<ChatConversation> _conversations = [];
  final Map<String, List<ChatMessage>> _messages = {};
  bool _isLoading = false;

  List<ChatConversation> get conversations => _conversations;
  Map<String, List<ChatMessage>> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> fetchConversations(String userId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    // محاكاة جلب المحادثات
    _conversations.clear();
    _conversations.addAll([
      ChatConversation(
        id: '1',
        participantIds: [userId, '2'],
        participantNames: ['أنت', 'أحمد محمد'],
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
        lastMessageContent: 'مرحباً، كيف حالك اليوم؟',
        hasUnreadMessages: true,
      ),
      ChatConversation(
        id: '2',
        participantIds: [userId, '3'],
        participantNames: ['أنت', 'محمد علي'],
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        lastMessageContent: 'تم إكمال المهمة المطلوبة',
        hasUnreadMessages: false,
      ),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMessages(String conversationId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    // محاكاة جلب الرسائل
    _messages[conversationId] = [
      ChatMessage(
        id: '1',
        senderId: '2',
        senderName: 'أحمد محمد',
        content: 'مرحباً، كيف حالك اليوم؟',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
      ),
      ChatMessage(
        id: '2',
        senderId: '1',
        senderName: 'أنت',
        content: 'أنا بخير، شكراً لسؤالك. ماذا عنك؟',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String conversationId, String senderId, String senderName, String content) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
    );

    if (_messages.containsKey(conversationId)) {
      _messages[conversationId]!.add(message);
    } else {
      _messages[conversationId] = [message];
    }

    // تحديث آخر رسالة في المحادثة
    final index = _conversations.indexWhere((conv) => conv.id == conversationId);
    if (index != -1) {
      final conversation = _conversations[index];
      _conversations[index] = ChatConversation(
        id: conversation.id,
        participantIds: conversation.participantIds,
        participantNames: conversation.participantNames,
        lastMessageTime: DateTime.now(),
        lastMessageContent: content,
        hasUnreadMessages: true,
      );
    }

    _isLoading = false;
    notifyListeners();
  }
}
