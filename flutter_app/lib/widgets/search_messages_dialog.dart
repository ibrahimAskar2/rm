import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import 'dart:developer' as developer;

class SearchMessagesDialog extends StatefulWidget {
  final String chatId;
  final Function(Message) onMessageSelected;

  const SearchMessagesDialog({
    super.key,
    required this.chatId,
    required this.onMessageSelected,
  });

  @override
  State<SearchMessagesDialog> createState() => _SearchMessagesDialogState();
}

class _SearchMessagesDialogState extends State<SearchMessagesDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Message> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchMessages(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      final messages = messagesSnapshot.docs
          .map((doc) => Message.fromMap(doc.id, doc.data()))
          .toList();

      if (mounted) {
        setState(() {
          _searchResults = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء البحث: $e')),
        );
      }
      developer.log('Error searching messages: $e', name: 'SearchMessagesDialog');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('بحث في الرسائل'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'أدخل نص البحث...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _searchMessages,
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const CircularProgressIndicator()
          else if (_searchResults.isEmpty)
            const Text('لا توجد نتائج')
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final message = _searchResults[index];
                  return ListTile(
                    title: Text(message.content),
                    subtitle: Text(
                      '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onMessageSelected(message);
                    },
                  );
                },
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 