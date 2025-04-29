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
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
          _hasMore = messages.length >= _messagesPerLoad;
          _lastDocument = messages.isNotEmpty ? messagesSnapshot.docs.last : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
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
      
      if (mounted) {
        setState(() {
          _messages.addAll(moreMessages);
          _isLoading = false;
          _hasMore = moreMessages.length >= _messagesPerLoad;
          _lastDocument = moreMessages.isNotEmpty ? messagesSnapshot.docs.last : _lastDocument;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
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
      
      if (mounted) {
        await _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        final context = this.context;
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
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: _startVoiceCall,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
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
                      return _buildMessageItem(_messages[index]);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _showAttachmentOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالة...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message) {
    final isMe = message.senderId == _firestoreService.currentUserId;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.type == 'text')
              Text(
                message.content,
                style: const TextStyle(fontSize: 16),
              )
            else if (message.type == 'image')
              Image.network(
                message.mediaUrl ?? '',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  );
                },
              ),
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  void _startVoiceCall() async {
    final currentUserId = _firestoreService.currentUserId;
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم تعيين معرف المستخدم الحالي')),
        );
      }
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
    final context = this.context;
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
              await _loadMessages();
            }
          } catch (e) {
            if (mounted) {
              final context = this.context;
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
