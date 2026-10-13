import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/message_formatter.dart';
import '../../providers/chat_provider.dart';
import 'conversation_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _patientSearchController = TextEditingController();
  String _patientSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.fetchAssignedPatients();
      chatProvider.fetchConversations();
      chatProvider.fetchChatUsersAndBatches();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _patientSearchController.dispose();
    super.dispose();
  }

  void _showNewColleagueChatDialog() {
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
                    'Direct message colleague',
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
                    ? const Center(child: Text('No staff members found.'))
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
                              MessageFormatter.formatRole(staff.role),
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
                                      isPatient: false,
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
            const Text('Doctor Chat'),
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
            tooltip: 'Refresh conversations',
            onPressed: () {
              chatProvider.fetchAssignedPatients(refresh: true);
              chatProvider.fetchConversations(refresh: true);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: const Icon(Icons.people_alt_outlined, size: 20),
              text: 'Assigned Patients (${chatProvider.assignedPatients.length})',
            ),
            Tab(
              icon: const Icon(Icons.groups_outlined, size: 20),
              text: 'Team & Community (${chatProvider.conversations.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Assigned Patients
          _buildAssignedPatientsTab(chatProvider),

          // TAB 2: Team & Community Rooms
          _buildTeamRoomsTab(chatProvider),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index == 1) {
            return FloatingActionButton.extended(
              onPressed: _showNewColleagueChatDialog,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('New colleague chat'),
              backgroundColor: AppTheme.primaryColor,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAssignedPatientsTab(ChatProvider chatProvider) {
    final filteredPatients = chatProvider.assignedPatients.where((p) {
      if (_patientSearchQuery.isEmpty) return true;
      final q = _patientSearchQuery.toLowerCase();
      final nameMatches = p.name.toLowerCase().contains(q);
      final idMatches = (p.patientDisplayId ?? '').toLowerCase().contains(q);
      final phoneMatches = (p.phone ?? '').toLowerCase().contains(q);
      return nameMatches || idMatches || phoneMatches;
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _patientSearchController,
            onChanged: (val) {
              setState(() {
                _patientSearchQuery = val.trim();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search patients by name, ID or phone...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
              suffixIcon: _patientSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _patientSearchController.clear();
                        setState(() {
                          _patientSearchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),

        // List
        Expanded(
          child: chatProvider.isPatientsLoading && chatProvider.assignedPatients.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : filteredPatients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_off_outlined, size: 48, color: AppTheme.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            _patientSearchQuery.isNotEmpty
                                ? 'No patients found matching "$_patientSearchQuery".'
                                : 'No assigned patients loaded.',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reload patients'),
                            onPressed: () => chatProvider.fetchAssignedPatients(refresh: true),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => chatProvider.fetchAssignedPatients(refresh: true),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: filteredPatients.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          final patient = filteredPatients[index];
                          final initials = patient.name.isNotEmpty
                              ? patient.name[0].toUpperCase()
                              : 'P';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              patient.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                if (patient.patientDisplayId != null &&
                                    patient.patientDisplayId!.isNotEmpty) ...[
                                  Text(
                                    patient.patientDisplayId!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (patient.age != null)
                                  Text(
                                    '${patient.age} yrs • ${patient.displayGender}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      size: 14, color: AppTheme.primaryColor),
                                  SizedBox(width: 4),
                                  Text(
                                    'Chat',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ConversationScreen(
                                    conversationId: patient.id,
                                    title: patient.name,
                                    isPatient: true,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildTeamRoomsTab(ChatProvider chatProvider) {
    if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chatProvider.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum_outlined, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No active team rooms yet.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Start direct message'),
              onPressed: _showNewColleagueChatDialog,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => chatProvider.fetchConversations(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: chatProvider.conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final conv = chatProvider.conversations[index];
          final timeStr = conv.lastMessageAt != null
              ? DateFormat('hh:mm a').format(conv.lastMessageAt!)
              : '';

          final isCommunity = conv.type == 'COMMUNITY_GLOBAL' ||
              (conv.title?.toLowerCase().contains('community') ?? false);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isCommunity
                  ? AppTheme.accentPurple.withValues(alpha: 0.15)
                  : AppTheme.primaryColor.withValues(alpha: 0.12),
              child: Icon(
                isCommunity ? Icons.public : Icons.person_outline,
                color: isCommunity ? AppTheme.accentPurple : AppTheme.primaryColor,
              ),
            ),
            title: Text(
              conv.title ?? 'Team chat room',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              conv.lastMessage ?? (isCommunity ? 'Community discussions' : 'No messages yet.'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: conv.unreadCount > 0
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontWeight:
                    conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (timeStr.isNotEmpty)
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
                    isPatient: false,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
