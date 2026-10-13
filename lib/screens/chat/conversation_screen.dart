import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/message_formatter.dart';
import '../../models/chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String? title;
  final bool isPatient;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    this.title,
    this.isPatient = false,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  int _prevMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().openConversation(
            widget.conversationId,
            isPatient: widget.isPatient,
            title: widget.title,
          );
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTextChanged(String text) {
    if (widget.isPatient) return;
    final chatProvider = context.read<ChatProvider>();
    if (text.isNotEmpty) {
      chatProvider.sendTyping();
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        chatProvider.stopTyping();
      });
    } else {
      chatProvider.stopTyping();
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      context.read<ChatProvider>().sendMessage(content);
      _messageController.clear();
      if (!widget.isPatient) {
        context.read<ChatProvider>().stopTyping();
      }
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id ?? '';
    final currentUserName = authProvider.currentUser?.name ?? '';

    // Auto-scroll when new message is received or added
    if (chatProvider.activeMessages.length != _prevMessageCount) {
      _prevMessageCount = chatProvider.activeMessages.length;
      _scrollToBottom();
    }

    final headerTitle = widget.title != null && widget.title!.isNotEmpty
        ? MessageFormatter.toSentenceCase(widget.title!)
        : (widget.isPatient ? 'Patient Consultation' : 'Clinical chat room');

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          chatProvider.closeConversation();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headerTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              if (widget.isPatient)
                const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 12, color: AppTheme.primaryColor),
                    SizedBox(width: 4),
                    Text(
                      'Assigned Patient Consultation',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              else if (chatProvider.isOtherUserTyping)
                Text(
                  '${chatProvider.typingUserName ?? "Colleague"} is typing...',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: chatProvider.isSocketConnected
                            ? AppTheme.successGreen
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      chatProvider.isSocketConnected
                          ? 'Connected'
                          : 'Connecting...',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh messages',
              onPressed: () {
                chatProvider.openConversation(
                  widget.conversationId,
                  isPatient: widget.isPatient,
                  title: widget.title,
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (chatProvider.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppTheme.warningOrange.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppTheme.warningOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatProvider.errorMessage!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

            // Messages List
            Expanded(
              child: chatProvider.isMessagesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : chatProvider.activeMessages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.isPatient
                                      ? Icons.chat_bubble_outline_rounded
                                      : Icons.forum_outlined,
                                  size: 48,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.isPatient
                                      ? 'No messages with this patient yet.\nSend clinical advice or check-in below.'
                                      : 'No messages in this chat room yet.\nSend a message to begin.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await chatProvider.openConversation(
                              widget.conversationId,
                              isPatient: widget.isPatient,
                              title: widget.title,
                            );
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            itemCount: chatProvider.activeMessages.length,
                            itemBuilder: (context, index) {
                              final msg = chatProvider.activeMessages[index];
                              final isMe = msg.senderId == currentUserId ||
                                  (msg.senderRole != null &&
                                      msg.senderRole!.toUpperCase() == 'DOCTOR') ||
                                  msg.senderName == 'Me' ||
                                  (currentUserName.isNotEmpty &&
                                      msg.senderName == currentUserName);
                              return _MessageBubble(
                                message: msg,
                                isMe: isMe,
                                isPatientChat: widget.isPatient,
                              );
                            },
                          ),
                        ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        onChanged: _onTextChanged,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: widget.isPatient
                              ? 'Type a message to the patient...'
                              : 'Type a message to the team...',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                const BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 18),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final bool isPatientChat;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isPatientChat,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(message.createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && (message.senderName != null || message.senderRole != null)) ...[
              Text(
                '${message.senderName ?? (isPatientChat ? "Patient" : "Colleague")}${message.senderRole != null ? " (${MessageFormatter.formatRole(message.senderRole)})" : ""}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 2),
            ] else if (isMe && message.senderRole != null) ...[
              Text(
                '${message.senderName ?? "Dr. Consultation"} (Doctor)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : AppTheme.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppTheme.textMuted,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead
                        ? Icons.done_all
                        : (message.isDelivered ? Icons.done_all : Icons.done),
                    size: 14,
                    color: message.isRead
                        ? Colors.lightBlueAccent
                        : Colors.white.withValues(alpha: 0.75),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
