import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/chat_service.dart';
import '../providers/user_provider.dart';
import '../models/message_model.dart';
import 'package:image_picker/image_picker.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _chats = [];
  Map<String, List<Message>> _messages = {};
  String? _currentChatId;
  String? _currentUserId;
  String? _currentUserName;
  Map<String, Map<String, dynamic>> _usersInfo = {};
  Map<String, bool> _typingStatus = {};

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get chats => _chats;
  Map<String, List<Message>> get messages => _messages;
  String? get currentChatId => _currentChatId;
  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  Map<String, Map<String, dynamic>> get usersInfo => _usersInfo;

  void setCurrentUser(String userId, String userName) {
    _currentUserId = userId;
    _currentUserName = userName;
    notifyListeners();
  }

  void setCurrentChat(String chatId) {
    _currentChatId = chatId;
    _loadMessages();
    notifyListeners();
  }

  Future<void> _loadMessages() async {
    if (_currentChatId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _chatService.getMessagesStream(_currentChatId!).listen((messages) {
        _messages[_currentChatId!] = messages;
        notifyListeners();
      });
    } catch (e) {
      print('Error loading messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendTextMessage(String chatId, String text) async {
    if (_currentUserId == null || _currentUserName == null) return;

    try {
      await _chatService.sendMessage(
        chatId: chatId,
        senderId: _currentUserId!,
        senderName: _currentUserName!,
        text: text,
      );
      updateTypingStatus(chatId, false);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> sendImageMessage(String chatId, String imageUrl) async {
    if (_currentUserId == null || _currentUserName == null) return;

    try {
      await _chatService.sendMessage(
        chatId: chatId,
        senderId: _currentUserId!,
        senderName: _currentUserName!,
        text: '',
        imageUrl: imageUrl,
      );
    } catch (e) {
      print('Error sending image: $e');
      rethrow;
    }
  }

  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await _chatService.markMessageAsRead(messageId);
    } catch (e) {
      print('Error marking message as read: $e');
      rethrow;
    }
  }

  Future<List<Message>> searchChatMessages(String chatId, String searchText) async {
    try {
      return await _chatService.searchMessages(chatId, searchText);
    } catch (e) {
      print('Error searching messages: $e');
      rethrow;
    }
  }

  Future<String?> pickAndUploadImage() async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        return await _chatService.uploadImage(file);
      }
      return null;
    } catch (e) {
      print('Error picking and uploading image: $e');
      rethrow;
    }
  }

  void updateTypingStatus(String chatId, bool isTyping) {
    _typingStatus[chatId] = isTyping;
    notifyListeners();
  }

  Stream<bool> getTypingStatus(String chatId) {
    return Stream.value(_typingStatus[chatId] ?? false);
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _chatService.deleteMessage(chatId, messageId);
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  Future<void> editMessage(String chatId, String messageId, String newText) async {
    try {
      await _chatService.editMessage(chatId, messageId, newText);
    } catch (e) {
      print('Error editing message: $e');
      rethrow;
    }
  }

  Future<void> replyToMessage(String chatId, String messageId, String replyText) async {
    try {
      await _chatService.replyToMessage(chatId, messageId, replyText);
    } catch (e) {
      print('Error replying to message: $e');
      rethrow;
    }
  }

  // تحميل قائمة الدردشات
  void loadChats() {
    try {
      _isLoading = true;
      notifyListeners();

      _chatService.getChats().listen((snapshot) async {
        _chats = [];
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final chatId = doc.id;
          
          // تحويل البيانات إلى تنسيق مناسب
          final chatInfo = {
            'id': chatId,
            'type': data['type'],
            'participants': List<String>.from(data['participants'] ?? []),
            'lastMessage': data['lastMessage'],
            'lastMessageTime': data['lastMessageTime'],
          };
          
          // إضافة اسم المجموعة إذا كانت دردشة جماعية
          if (data['type'] == 'group') {
            chatInfo['name'] = data['name'];
            chatInfo['admin'] = data['admin'];
          } else {
            // للدردشات الفردية، احصل على معلومات المستخدم الآخر
            final participants = List<String>.from(data['participants'] ?? []);
            final currentUserId = Provider.of<UserProvider>(
              _getGlobalContext(),
              listen: false,
            ).user?.uid;
            
            if (currentUserId != null && participants.isNotEmpty) {
              final otherUserId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => participants.first,
              );
              
              // تحميل معلومات المستخدم إذا لم تكن محملة بالفعل
              if (!_usersInfo.containsKey(otherUserId)) {
                final userInfo = await _chatService.getUserInfo(otherUserId);
                if (userInfo != null) {
                  _usersInfo[otherUserId] = userInfo;
                }
              }
            }
          }
          
          _chats.add(chatInfo);
        }
        
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error loading chats: $e');
    }
  }

  // إنشاء دردشة فردية جديدة
  Future<String?> createPrivateChat(String otherUserId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final chatId = await _chatService.createPrivateChat(otherUserId);
      
      // تحميل معلومات المستخدم الآخر
      if (!_usersInfo.containsKey(otherUserId)) {
        final userInfo = await _chatService.getUserInfo(otherUserId);
        if (userInfo != null) {
          _usersInfo[otherUserId] = userInfo;
        }
      }

      _isLoading = false;
      notifyListeners();
      return chatId;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error creating private chat: $e');
      return null;
    }
  }

  // إنشاء مجموعة دردشة جديدة
  Future<String?> createGroupChat(String name, List<String> participants) async {
    try {
      _isLoading = true;
      notifyListeners();

      final chatId = await _chatService.createGroupChat(name, participants);

      _isLoading = false;
      notifyListeners();
      return chatId;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error creating group chat: $e');
      return null;
    }
  }

  // إضافة مشاركين إلى مجموعة دردشة
  Future<bool> addParticipantsToGroup(String chatId, List<String> newParticipants) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _chatService.addParticipantsToGroup(chatId, newParticipants);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error adding participants to group: $e');
      return false;
    }
  }

  // تحميل رسائل دردشة معينة
  void loadChatMessages(String chatId) {
    try {
      _isLoading = true;
      notifyListeners();

      _chatService.getChatMessages(chatId).listen((snapshot) async {
        final List<Message> messagesList = [];
        
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final messageId = doc.id;
          
          // تحويل البيانات إلى تنسيق مناسب
          final message = Message(
            id: messageId,
            type: data['type'],
            senderId: data['senderId'],
            timestamp: data['timestamp'],
            readBy: List<String>.from(data['readBy'] ?? []),
            deliveredTo: List<String>.from(data['deliveredTo'] ?? []),
          );
          
          // إضافة البيانات الخاصة بنوع الرسالة
          if (data['type'] == 'text') {
            message.text = data['text'];
          } else if (data['type'] == 'voice' || data['type'] == 'image') {
            message.url = data['url'];
          }
          
          // تحميل معلومات المرسل إذا لم تكن محملة بالفعل
          final senderId = data['senderId'];
          if (!_usersInfo.containsKey(senderId)) {
            final userInfo = await _chatService.getUserInfo(senderId);
            if (userInfo != null) {
              _usersInfo[senderId] = userInfo;
            }
          }
          
          // تحديث حالة استلام الرسالة
          final currentUserId = Provider.of<UserProvider>(
            _getGlobalContext(),
            listen: false,
          ).user?.uid;
          
          if (currentUserId != null && 
              senderId != currentUserId && 
              !message.deliveredTo.contains(currentUserId)) {
            _chatService.markMessageAsDelivered(chatId, message.id);
          }
          
          messagesList.add(message);
        }
        
        _messages[chatId] = messagesList;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error loading chat messages: $e');
    }
  }

  // إرسال رسالة صوتية
  Future<bool> sendVoiceMessage(String chatId, File audioFile) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _chatService.sendVoiceMessage(chatId, audioFile);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error sending voice message: $e');
      return false;
    }
  }

  // البحث في رسائل دردشة معينة
  Future<List<Map<String, dynamic>>> searchChatMessages(String chatId, String query) async {
    try {
      _isLoading = true;
      notifyListeners();

      final results = await _chatService.searchChatMessages(chatId, query);
      
      final List<Map<String, dynamic>> searchResults = [];
      for (var doc in results) {
        final data = doc.data() as Map<String, dynamic>;
        final messageId = doc.id;
        
        searchResults.add({
          'id': messageId,
          'type': data['type'],
          'text': data['text'],
          'senderId': data['senderId'],
          'timestamp': data['timestamp'],
        });
      }

      _isLoading = false;
      notifyListeners();
      return searchResults;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error searching chat messages: $e');
      return [];
    }
  }

  // الحصول على معلومات المستخدم
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      if (_usersInfo.containsKey(userId)) {
        return _usersInfo[userId];
      }
      
      final userInfo = await _chatService.getUserInfo(userId);
      if (userInfo != null) {
        _usersInfo[userId] = userInfo;
        notifyListeners();
      }
      
      return userInfo;
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }

  // الحصول على سياق عام للتطبيق (للاستخدام الداخلي)
  BuildContext _getGlobalContext() {
    return navigatorKey.currentContext!;
  }
}

// مفتاح عام للتنقل (يجب تعريفه في main.dart)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
