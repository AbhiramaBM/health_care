import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/chat_provider.dart';
import 'conversation_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchConversations();
      context.read<ChatProvider>().fetchChatUsersAndBatches();
    });
  }

  void _showNewChatDialog() {
    final chatProvider = context.read<ChatProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Direct Message Colleague',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Select a staff member or doctor to start a direct room:',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const Divider(height: 20),
              Expanded(
                child: chatProvider.chatUsers.isEmpty
                    ? const Center(child: Text('No staff members found'))
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: chatProvider.chatUsers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final staff = chatProvider.chatUsers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                              child: Text(
                                staff.name != null && staff.name!.isNotEmpty
                                    ? staff.name![0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              staff.name ?? 'Staff Member',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              staff.role?.toUpperCase() ?? 'STAFF',
                              style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor),
                            ),
                            onTap: () async {
                              final navigator = Navigator.of(context);
                              Navigator.of(ctx).pop();
                              final room = await chatProvider.startDirectChat(staff.id);
                              if (room != null && mounted) {
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) => ConversationScreen(
                                      conversationId: room.id,
                                      title: staff.name ?? room.title,
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Clinical Chat'),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: chatProvider.isSocketConnected
                    ? AppTheme.successGreen
                    : Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => chatProvider.fetchConversations(refresh: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewChatDialog,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New DM'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: chatProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : chatProvider.conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.forum_outlined,
                          size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'No active conversations yet.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Start Direct Message'),
                        onPressed: _showNewChatDialog,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      chatProvider.fetchConversations(refresh: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chatProvider.conversations.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final conv = chatProvider.conversations[index];
                      final timeStr = conv.lastMessageAt != null
                          ? DateFormat('hh:mm a').format(conv.lastMessageAt!)
                          : '';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.12),
                          child: Text(
                            conv.title != null && conv.title!.isNotEmpty
                                ? conv.title![0].toUpperCase()
                                : 'C',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          conv.title ?? 'Team Chat Room',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          conv.lastMessage ?? 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: conv.unreadCount > 0
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontWeight: conv.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            if (conv.unreadCount > 0) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${conv.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ConversationScreen(
                                conversationId: conv.id,
                                title: conv.title,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
