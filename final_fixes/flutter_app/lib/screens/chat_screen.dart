import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final bool isGroup;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.isGroup = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRecording = false;
  String _searchQuery = '';
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  final ChatService _chatService = ChatService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // تحديد الدردشة الحالية وتحميل رسائلها
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).setCurrentChat(widget.chatId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      await _chatService.getMessagesStream(widget.chatId).first;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الرسائل: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // التمرير إلى أسفل القائمة عند إضافة رسائل جديدة
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // إرسال رسالة نصية
  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final success = await chatProvider.sendTextMessage(widget.chatId, text);

    if (success) {
      _messageController.clear();
      _scrollToBottom();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل إرسال الرسالة')),
        );
      }
    }
  }

  // إرسال رسالة صوتية
  Future<void> _startVoiceRecording() async {
    // في التطبيق الفعلي، سيتم هنا بدء تسجيل الصوت
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopVoiceRecording() async {
    // في التطبيق الفعلي، سيتم هنا إيقاف تسجيل الصوت وإرسال الملف
    setState(() {
      _isRecording = false;
    });

    // مثال لإرسال ملف صوتي (سيتم استبداله بالتسجيل الفعلي)
    // final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // final success = await chatProvider.sendVoiceMessage(widget.chatId, audioFile);
  }

  // إرسال صورة
  Future<void> _sendImage() async {
    try {
      final imageUrl = await context.read<ChatProvider>().pickAndUploadImage();
      if (imageUrl != null && mounted) {
        await _chatService.sendMessage(
          chatId: widget.chatId,
          senderId: context.read<ChatProvider>().currentUserId,
          senderName: context.read<ChatProvider>().currentUserName,
          text: '',
          imageUrl: imageUrl,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إرسال الصورة: $e')),
        );
      }
    }
  }

  // البحث في المحادثة
  Future<void> _searchInChat(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final results = await chatProvider.searchChatMessages(widget.chatId, query);

    setState(() {
      _searchResults = results;
    });
  }

  // تحديث حالة قراءة الرسالة
  void _markMessageAsRead(String messageId) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.markMessageAsRead(widget.chatId, messageId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchResults = [];
                }
              });
            },
          ),
          if (widget.isGroup)
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: () {
                // في التطبيق الفعلي، سيتم هنا فتح شاشة إضافة مشاركين
              },
            ),
        ],
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'البحث في المحادثة',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _searchInChat(value);
                    },
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // عرض نتائج البحث
          if (_isSearching && _searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final message = _searchResults[index];
                  return ListTile(
                    title: Text(message['text'] ?? ''),
                    subtitle: Text('${_formatTimestamp(message['timestamp'])}'),
                    onTap: () {
                      // في التطبيق الفعلي، سيتم هنا التمرير إلى الرسالة في المحادثة
                    },
                  );
                },
              ),
            )
          else if (_isSearching && _searchQuery.isNotEmpty)
            const Expanded(
              child: Center(
                child: Text('لا توجد نتائج'),
              ),
            )
          else
            // عرض المحادثة
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: _chatService.getMessagesStream(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('خطأ: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!;
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == context.read<ChatProvider>().currentUserId;
                      
                      // تحديث حالة قراءة الرسالة
                      if (!isMe && message.senderId != null && 
                          !message.readBy.contains(message.senderId)) {
                        _markMessageAsRead(message.id);
                      }
                      
                      return _buildMessageBubble(message);
                    },
                  );
                },
              ),
            ),
          
          // حقل إدخال الرسالة
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                // زر إرسال الصورة
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _sendImage,
                ),
                
                // زر تسجيل الصوت
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  onPressed: _isRecording ? _stopVoiceRecording : _startVoiceRecording,
                  color: _isRecording ? Colors.red : null,
                ),
                
                // حقل إدخال النص
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
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendTextMessage(),
                  ),
                ),
                
                // زر إرسال الرسالة
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendTextMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.senderId == context.read<ChatProvider>().currentUserId;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null)
              Image.network(
                message.imageUrl!,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
            Text(
              message.senderName,
              style: TextStyle(
                fontSize: 12,
                color: isMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // تنسيق الوقت
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return '';
    }
    
    try {
      final DateTime dateTime = timestamp is DateTime
          ? timestamp
          : DateTime.fromMillisecondsSinceEpoch(
              timestamp.seconds * 1000 + (timestamp.nanoseconds ~/ 1000000),
            );
      
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}
