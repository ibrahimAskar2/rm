import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';

class PaginatedChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String receiverId;

  const PaginatedChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.receiverId,
  });

  @override
  State<PaginatedChatScreen> createState() => _PaginatedChatScreenState();
}

class _PaginatedChatScreenState extends State<PaginatedChatScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ChatService _chatService = ChatService();
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  
  final int _messagesPerLoad = 20;

  @override
  void initState() {
    super.initState();
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
      if (currentUserId == null) {
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
      
      await _sendNotification(
        widget.receiverId,
        currentUserId,
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

  Future<void> _sendNotification(String receiverId, String senderId, String message) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverId': receiverId,
        'senderId': senderId,
        'message': message,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'type': 'message',
      });
    } catch (e) {
      print('Error sending notification: $e');
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
            onPressed: () {
              // تنفيذ المكالمة الصوتية
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // عرض نافذة البحث
            },
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
            onPressed: () {
              // تنفيذ إرفاق ملف
            },
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
}
