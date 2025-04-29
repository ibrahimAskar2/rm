import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      await Provider.of<ChatProvider>(context, listen: false)
          .fetchConversations(userProvider.user!.id);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدردشات'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: chatProvider.conversations.isEmpty
                  ? const Center(
                      child: Text('لا توجد محادثات'),
                    )
                  : ListView.builder(
                      itemCount: chatProvider.conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = chatProvider.conversations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                conversation.participantNames[1].substring(0, 1),
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            title: Text(conversation.participantNames[1]),
                            subtitle: Text(
                              conversation.lastMessageContent,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${conversation.lastMessageTime.hour}:${conversation.lastMessageTime.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (conversation.hasUnreadMessages)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Text(
                                      '',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {
                              // التنقل إلى شاشة المحادثة
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
