import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/chat_service.dart';
import '../services/call_service.dart';
import '../screens/call_screen.dart';
import '../widgets/search_messages_dialog.dart';
import '../widgets/attachment_options_sheet.dart';
import 'dart:developer' as developer;

class PaginatedChatScreenRefactored extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String receiverId;

  const PaginatedChatScreenRefactored({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.receiverId,
  });

  @override
  State<PaginatedChatScreenRefactored> createState() => _PaginatedChatScreenRefactoredState();
}

class _PaginatedChatScreenRefactoredState extends State<PaginatedChatScreenRefactored> {
  final FirestoreService _firestoreService = FirestoreService();
  final ChatService _chatService = ChatService();
  final CallService _callService = CallService();
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  
  final int _messagesPerLoad = 20;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = _firestoreService.currentUserId;
      if (userId == null) {
        throw Exception('لم يتم تعيين معرف المستخدم الحالي');
      }
      
      final userInfo = await _firestoreService.getUserInfo(userId);
      if (userInfo != null && mounted) {
        setState(() {
          _currentUser = User.fromMap(userId, userInfo);
        });
      }
    } catch (e) {
      developer.log('Error loading current user: $e', name: 'PaginatedChatScreen');
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreMessages();
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(_messagesPerLoad)
          .get();
      
      final messages = messagesSnapshot.docs
          .map((doc) => Message.fromMap(doc.id, doc.data()))
          .toList();
      
      setState(() {
        _messages = messages;
        _isLoading = false;
        _hasMore = messages.length >= _messagesPerLoad;
        _lastDocument = messages.isNotEmpty ? messagesSnapshot.docs.last : null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تحميل الرسائل: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoading || !_hasMore || _lastDocument == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_messagesPerLoad)
          .get();
      
      final moreMessages = messagesSnapshot.docs
          .map((doc) => Message.fromMap(doc.id, doc.data()))
          .toList();
      
      setState(() {
        _messages.addAll(moreMessages);
        _isLoading = false;
        _hasMore = moreMessages.length >= _messagesPerLoad;
        _lastDocument = moreMessages.isNotEmpty ? messagesSnapshot.docs.last : _lastDocument;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تحميل المزيد من الرسائل: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    
    try {
      final currentUserId = _firestoreService.currentUserId;
      if (currentUserId == null || _currentUser == null) {
        throw Exception('لم يتم تعيين معرف المستخدم الحالي');
      }
      
      final message = Message.createText(
        chatId: widget.chatId,
        senderId: currentUserId,
        receiverId: widget.receiverId,
        content: text,
      );
      
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());
      
      await _firestoreService.createMessageSearchKeywords(
        widget.chatId,
        message.id,
        text,
      );
      
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
            'lastMessage': text,
            'lastMessageTimestamp': Timestamp.fromDate(message.timestamp),
            'lastMessageSenderId': currentUserId,
          });
      
      await _sendNotificationToReceiver(
        widget.receiverId,
        currentUserId,
        _currentUser!.name,
        text,
      );
      
      await _firestoreService.updateUserStatistics(
        currentUserId,
        {'totalMessages': FieldValue.increment(1)},
      );
      
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إرسال الرسالة: $e')),
        );
      }
    }
  }

  Future<void> _sendNotificationToReceiver(
    String receiverId,
    String senderId,
    String senderName,
    String messageText,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverId': receiverId,
        'senderId': senderId,
        'senderName': senderName,
        'message': messageText,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'type': 'message',
      });
    } catch (e) {
      developer.log('Error sending notification: $e', name: 'PaginatedChatScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _startVoiceCall(),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && !_isLoading
                ? const Center(child: Text('لا توجد رسائل'))
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: _messages.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final message = _messages[index];
                      final isMe = message.senderId == _firestoreService.currentUserId;

                      return _buildMessageItem(message, isMe);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.type == 'image')
              Image.network(
                message.mediaUrlString,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              )
            else
              Text(message.content),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () => _showAttachmentOptions(),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'اكتب رسالة...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  void _startVoiceCall() async {
    final currentUserId = _firestoreService.currentUserId;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم تعيين معرف المستخدم الحالي')),
      );
      return;
    }

    try {
      final call = await _callService.startCall(
        callerId: currentUserId,
        callerName: _currentUser?.name ?? 'Unknown',
        callerImage: _currentUser?.imageUrl,
        receiverId: widget.receiverId,
        receiverName: widget.chatName,
      );

      if (mounted && call != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              call: call,
              isIncoming: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء بدء المكالمة: $e')),
        );
      }
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => SearchMessagesDialog(
        chatId: widget.chatId,
        onMessageSelected: (message) {
          // تنفيذ التمرير إلى الرسالة المحددة
        },
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentOptionsSheet(
        onImageSelected: (file) async {
          try {
            final currentUserId = _firestoreService.currentUserId;
            if (currentUserId == null) {
              throw Exception('لم يتم تعيين معرف المستخدم الحالي');
            }

            await _chatService.sendImageMessage(
              chatId: widget.chatId,
              senderId: currentUserId,
              receiverId: widget.receiverId,
              imageFile: file,
            );

            if (mounted) {
              _loadMessages();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('حدث خطأ أثناء إرسال الصورة: $e')),
              );
            }
          }
        },
      ),
    );
  }
}
