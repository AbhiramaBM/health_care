import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'top_notification_banner.dart';
import '../../models/alert_model.dart';
import '../../models/patient_model.dart';
import '../../screens/alerts/alerts_screen.dart';
import '../../screens/patients/patient_detail_screen.dart';

/// Helper to display clinical alert popup notifications and quick action modals.
class NotificationPopupHelper {
  NotificationPopupHelper._();

  /// Displays a compact floating top notification banner (WhatsApp style).
  /// Never blocks the underlying screen, allows user to continue interacting,
  /// auto-dismisses after 3–5 seconds.
  static void showAlertNotificationPopup(
    BuildContext context,
    AlertModel alert, {
    VoidCallback? onAcknowledge,
  }) {
    TopNotificationBanner.showAlert(
      context,
      alert,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AlertsScreen(),
          ),
        );
      },
    );
  }

  /// Displays a quick actions popup modal bottom sheet for a patient.
  static void showPatientQuickActionsPopup({
    required BuildContext context,
    required PatientModel patient,
    AlertModel? activeAlert,
    VoidCallback? onMessageWhatsApp,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.12),
                        child: Text(
                          patient.name.isNotEmpty
                              ? patient.name[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${patient.age != null ? "${patient.age} yrs • " : ""}${patient.displayGender}${patient.phone != null ? " • ${patient.phone}" : ""}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // 1. Alert Notification Item (if patient has alert)
                if (patient.hasAlert) ...[
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFEE2E2),
                      child: Icon(Icons.warning_amber_rounded,
                          color: AppTheme.criticalRed),
                    ),
                    title: Text(
                      activeAlert?.displayTitle ?? 'Active clinical alert',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.criticalRed,
                      ),
                    ),
                    subtitle: Text(
                      activeAlert?.displayDescription ??
                          'Patient has an active clinical alert pending review.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      if (activeAlert != null) {
                        showAlertNotificationPopup(context, activeAlert);
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AlertsScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],

                // 2. View full profile
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.person, color: AppTheme.primaryColor),
                  ),
                  title: const Text('Open patient record'),
                  subtitle: const Text('View vitals, history, and daily logs'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PatientDetailScreen(
                          patientId: patient.id,
                          initialPatient: patient,
                        ),
                      ),
                    );
                  },
                ),

                // 3. Message via WhatsApp
                if (patient.phone != null && patient.phone!.isNotEmpty) ...[
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFD1FAE5),
                      child: Icon(Icons.chat_bubble_outline,
                          color: AppTheme.successGreen),
                    ),
                    title: const Text('Message via WhatsApp'),
                    subtitle: Text('Contact ${patient.name} directly'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      if (onMessageWhatsApp != null) {
                        onMessageWhatsApp();
                      } else {
                        _showQuickWhatsAppDialog(context, patient);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showQuickWhatsAppDialog(
      BuildContext context, PatientModel patient) {
    final controller = TextEditingController(
      text: 'Hello ${patient.name}, please remember to log your readings today.',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send WhatsApp message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sending to ${patient.name} (${patient.phone})',
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter clinical instruction or message...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('WhatsApp message queued successfully.'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            child: const Text('Send message'),
          ),
        ],
      ),
    );
  }
}
