import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/alert_provider.dart';
import '../../providers/chat_provider.dart';
import '../patients/patients_screen.dart';
import '../alerts/alerts_screen.dart';
import '../chat/chat_list_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().fetchPatients();
      context.read<AlertProvider>().fetchAlerts();
      context.read<ChatProvider>().fetchConversations();
    });
  }

  final List<Widget> _pages = const [
    _DashboardHomeTab(),
    PatientsScreen(),
    AlertsScreen(),
    ChatListScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final alertCount = context.watch<AlertProvider>().pendingAlertsCount;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        elevation: 2,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryColor),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppTheme.primaryColor),
            label: 'Patients',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: alertCount > 0,
              label: Text('$alertCount'),
              backgroundColor: AppTheme.criticalRed,
              child: const Icon(Icons.notifications_active_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: alertCount > 0,
              label: Text('$alertCount'),
              backgroundColor: AppTheme.criticalRed,
              child: const Icon(Icons.notifications_active,
                  color: AppTheme.criticalRed),
            ),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon:
                Icon(Icons.chat_bubble, color: AppTheme.primaryColor),
            label: 'Chat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _DashboardHomeTab extends StatelessWidget {
  const _DashboardHomeTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final patientProvider = context.watch<PatientProvider>();
    final alertProvider = context.watch<AlertProvider>();
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.name ?? "Doctor"}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.role?.toUpperCase() ?? 'DOCTOR',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () {
              patientProvider.fetchPatients(refresh: true);
              alertProvider.fetchAlerts(refresh: true);
              chatProvider.fetchConversations(refresh: true);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await patientProvider.fetchPatients(refresh: true);
          await alertProvider.fetchAlerts(refresh: true);
          await chatProvider.fetchConversations(refresh: true);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Patients',
                      value: '${patientProvider.patients.length}',
                      icon: Icons.people,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Active Alerts',
                      value: '${alertProvider.pendingAlertsCount}',
                      icon: Icons.warning_amber_rounded,
                      color: AppTheme.criticalRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Chat Rooms',
                      value: '${chatProvider.conversations.length}',
                      icon: Icons.forum_outlined,
                      color: AppTheme.infoBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Batches',
                      value: '${patientProvider.batches.length}',
                      icon: Icons.layers_outlined,
                      color: AppTheme.warningAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Alerts Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Clinical Attention Required',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${alertProvider.alerts.length} Total',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (alertProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (alertProvider.alerts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Center(
                    child: Text(
                      'No pending alerts at this time.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ...alertProvider.alerts.take(4).map(
                      (alert) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (alert.severity == 'URGENT' ||
                                    alert.severity == 'critical')
                                ? AppTheme.criticalRed.withValues(alpha: 0.15)
                                : AppTheme.warningAmber.withValues(alpha: 0.15),
                            child: Icon(
                              Icons.priority_high,
                              color: (alert.severity == 'URGENT' ||
                                      alert.severity == 'critical')
                                  ? AppTheme.criticalRed
                                  : AppTheme.warningAmber,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            alert.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            alert.description ?? 'No details provided',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: alert.isAcknowledged
                                  ? AppTheme.successGreen.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              alert.isAcknowledged ? 'ACKNOWLEDGED' : 'PENDING',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: alert.isAcknowledged
                                    ? AppTheme.successGreen
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
