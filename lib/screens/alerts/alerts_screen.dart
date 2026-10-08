import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/alert_model.dart';
import '../../providers/alert_provider.dart';
import '../../providers/log_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Alerts',
            onPressed: () => alertProvider.fetchAlerts(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Pending Alerts'),
                    selected: !alertProvider.showAcknowledged,
                    onSelected: (_) => alertProvider.filter(acknowledged: false),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Acknowledged'),
                    selected: alertProvider.showAcknowledged,
                    onSelected: (_) => alertProvider.filter(acknowledged: true),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Urgent Only'),
                    selected: alertProvider.selectedPriority == 'URGENT',
                    onSelected: (sel) => alertProvider.filter(
                      priority: sel ? 'URGENT' : '',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Alerts List
          Expanded(
            child: alertProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : alertProvider.alerts.isEmpty
                    ? Center(
                        child: Text(
                          alertProvider.errorMessage ??
                              (alertProvider.showAcknowledged
                                  ? 'No acknowledged alerts found.'
                                  : 'No pending alerts at this time.'),
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            alertProvider.fetchAlerts(refresh: true),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: alertProvider.alerts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final alert = alertProvider.alerts[index];
                            return _AlertCard(alert: alert);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  const _AlertCard({required this.alert});

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
      case 'URGENT':
        return AppTheme.criticalRed;
      case 'HIGH':
      case 'WATCH':
        return Colors.deepOrange;
      case 'MEDIUM':
        return AppTheme.warningAmber;
      case 'LOW':
      case 'INFO':
      default:
        return AppTheme.infoBlue;
    }
  }

  void _showActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AlertActionsModal(alert: alert),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSeverityColor(alert.severity);
    final dateStr =
        DateFormat('MMM dd, yyyy • hh:mm a').format(alert.createdAt);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showActionsSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      alert.severity.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    alert.isAcknowledged ? 'ACKNOWLEDGED' : 'PENDING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: alert.isAcknowledged
                          ? AppTheme.successGreen
                          : AppTheme.criticalRed,
                    ),
                  ),
                ],
              ),
              if (alert.patientName != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Patient: ${alert.patientName}${alert.patientPhone != null ? " (${alert.patientPhone})" : ""}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
              if (alert.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  alert.description!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const Text(
                    'Tap to take action →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertActionsModal extends StatefulWidget {
  final AlertModel alert;
  const _AlertActionsModal({required this.alert});

  @override
  State<_AlertActionsModal> createState() => _AlertActionsModalState();
}

class _AlertActionsModalState extends State<_AlertActionsModal> {
  @override
  Widget build(BuildContext context) {
    final logProvider = context.read<LogProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.alert.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // 1. Acknowledge Action (POST /alerts/:id/acknowledge with ACKNOWLEDGED)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFD1FAE5),
                child: Icon(Icons.check, color: AppTheme.successGreen),
              ),
              title: const Text('Acknowledge Alert'),
              subtitle: const Text('Confirm review with optional clinical observation'),
              onTap: () => _showAcknowledgeDialog(context),
            ),

            // 2. Ignore Action (POST /alerts/:id/acknowledge with IGNORED)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF1F5F9),
                child: Icon(Icons.close, color: AppTheme.textSecondary),
              ),
              title: const Text('Ignore Alert (No Action Needed)'),
              subtitle: const Text('Dismiss false positive or verified expected variance'),
              onTap: () => _showIgnoreDialog(context),
            ),

            // 3. Message Patient via WhatsApp (POST /alerts/:id/acknowledge with MESSAGE_SENT)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFEF3C7),
                child: Icon(Icons.chat_bubble_outline, color: AppTheme.warningAmber),
              ),
              title: const Text('Message Patient via WhatsApp'),
              subtitle: const Text('Send reminder or instruction directly to patient'),
              onTap: () => _showMessageDialog(context),
            ),

            // 4. Change Medication (POST /alerts/:id/acknowledge with MEDICATION_CHANGED)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE0E7FF),
                child: Icon(Icons.medication_liquid, color: AppTheme.infoBlue),
              ),
              title: const Text('Change Medication (Doctor Only)'),
              subtitle: const Text('Adjust dose, frequency, or regimen for patient'),
              onTap: () => _showChangeMedicationDialog(context),
            ),

            // 5. Add Note to Alert (POST /notes with targetType: ALERT)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEDE9FE),
                child: Icon(Icons.note_add_outlined, color: Colors.purple),
              ),
              title: const Text('Add Clinical Note to Alert'),
              subtitle: const Text('Record internal note for clinical team review'),
              onTap: () => _addNoteDialog(context, logProvider),
            ),
          ],
        ),
      ),
    );
  }

  void _showAcknowledgeDialog(BuildContext parentContext) {
    final noteController = TextEditingController();
    bool isSaving = false;
    String? localError;

    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Acknowledge Alert'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (localError != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.criticalRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    localError!,
                    style: const TextStyle(color: AppTheme.criticalRed, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Clinical Note (Optional)',
                  hintText: 'Enter observation or action summary...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final alertProvider = parentContext.read<AlertProvider>();
                      final messenger = ScaffoldMessenger.of(parentContext);
                      final navigator = Navigator.of(parentContext);

                      setDialogState(() {
                        isSaving = true;
                        localError = null;
                      });
                      final note = noteController.text.trim();
                      final success = await alertProvider.acknowledge(
                            widget.alert.id,
                            noteContent: note.isNotEmpty ? note : 'Alert acknowledged by doctor.',
                          );
                      if (!ctx.mounted) return;
                      if (success) {
                        Navigator.of(ctx).pop();
                        if (mounted) {
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Alert acknowledged successfully!'),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        }
                      } else {
                        final err = alertProvider.errorMessage;
                        setDialogState(() {
                          isSaving = false;
                          localError = err ?? 'Failed to acknowledge alert.';
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIgnoreDialog(BuildContext parentContext) {
    final noteController = TextEditingController(
      text: 'Patient confirmed values — no intervention needed.',
    );
    bool isSaving = false;
    String? localError;

    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ignore Alert'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (localError != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.criticalRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    localError!,
                    style: const TextStyle(color: AppTheme.criticalRed, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason for Dismissal',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.criticalRed),
              onPressed: isSaving
                  ? null
                  : () async {
                      final alertProvider = parentContext.read<AlertProvider>();
                      final messenger = ScaffoldMessenger.of(parentContext);
                      final navigator = Navigator.of(parentContext);

                      setDialogState(() {
                        isSaving = true;
                        localError = null;
                      });
                      final note = noteController.text.trim();
                      final success = await alertProvider.ignore(
                            widget.alert.id,
                            noteContent: note,
                          );
                      if (!ctx.mounted) return;
                      if (success) {
                        Navigator.of(ctx).pop();
                        if (mounted) {
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Alert marked as ignored.'),
                              backgroundColor: AppTheme.textSecondary,
                            ),
                          );
                        }
                      } else {
                        final err = alertProvider.errorMessage;
                        setDialogState(() {
                          isSaving = false;
                          localError = err ?? 'Failed to ignore alert.';
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Ignore Alert'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageDialog(BuildContext parentContext) {
    final msgController = TextEditingController(
      text: 'Please recheck your reading tomorrow morning and stay hydrated.',
    );
    bool isSaving = false;
    String? localError;

    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Send WhatsApp Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (localError != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.criticalRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    localError!,
                    style: const TextStyle(color: AppTheme.criticalRed, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: msgController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message to Patient',
                  hintText: 'Enter message text to send via WhatsApp...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final msg = msgController.text.trim();
                      if (msg.isEmpty) {
                        setDialogState(() => localError = 'Please enter a message');
                        return;
                      }
                      final alertProvider = parentContext.read<AlertProvider>();
                      final messenger = ScaffoldMessenger.of(parentContext);
                      final navigator = Navigator.of(parentContext);

                      setDialogState(() {
                        isSaving = true;
                        localError = null;
                      });
                      final success = await alertProvider
                          .messagePatient(widget.alert.id, messageText: msg);
                      if (!ctx.mounted) return;
                      if (success) {
                        Navigator.of(ctx).pop();
                        if (mounted) {
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('WhatsApp message dispatched to patient!'),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        }
                      } else {
                        final err = alertProvider.errorMessage;
                        setDialogState(() {
                          isSaving = false;
                          localError = err ?? 'Failed to send message.';
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Send WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeMedicationDialog(BuildContext parentContext) {
    final medNameController = TextEditingController(text: 'Metformin');
    final doseController = TextEditingController(text: '1000mg');
    final freqController = TextEditingController(text: 'twice daily');
    final durationController = TextEditingController(text: '30 days');
    final instructionsController = TextEditingController(text: 'After meals');
    final noteController = TextEditingController(text: 'Adjusted medication based on alert.');
    String action = 'MODIFIED';
    bool isSaving = false;
    String? localError;

    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Medication'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (localError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.criticalRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      localError!,
                      style: const TextStyle(color: AppTheme.criticalRed, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                  controller: medNameController,
                  decoration: const InputDecoration(labelText: 'Medicine Name *'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: doseController,
                        decoration: const InputDecoration(labelText: 'Dose (e.g. 500mg) *'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: action,
                        decoration: const InputDecoration(labelText: 'Action'),
                        items: const [
                          DropdownMenuItem(value: 'MODIFIED', child: Text('MODIFIED')),
                          DropdownMenuItem(value: 'NEW', child: Text('NEW')),
                          DropdownMenuItem(value: 'CONTINUE', child: Text('CONTINUE')),
                          DropdownMenuItem(value: 'DISCONTINUED', child: Text('DISCONTINUED')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => action = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: freqController,
                        decoration: const InputDecoration(labelText: 'Frequency'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        decoration: const InputDecoration(labelText: 'Duration'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: instructionsController,
                  decoration: const InputDecoration(labelText: 'Instructions'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Clinical Note Content'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (medNameController.text.trim().isEmpty || doseController.text.trim().isEmpty) {
                        setDialogState(() => localError = 'Medicine name and dose are required');
                        return;
                      }

                      final alertProvider = parentContext.read<AlertProvider>();
                      final messenger = ScaffoldMessenger.of(parentContext);
                      final navigator = Navigator.of(parentContext);

                      setDialogState(() {
                        isSaving = true;
                        localError = null;
                      });

                      final noteText = noteController.text.trim();
                      final success = await alertProvider.changeMedication(
                            alertId: widget.alert.id,
                            patientId: widget.alert.patientId,
                            noteContent: noteText.isNotEmpty ? noteText : 'Adjusted medication based on alert.',
                            medications: [
                              {
                                'medicineName': medNameController.text.trim(),
                                'dose': doseController.text.trim(),
                                'frequency': freqController.text.trim().isNotEmpty
                                    ? freqController.text.trim()
                                    : 'Once daily',
                                'duration': durationController.text.trim().isNotEmpty
                                    ? durationController.text.trim()
                                    : '30 days',
                                'instructions': instructionsController.text.trim().isNotEmpty
                                    ? instructionsController.text.trim()
                                    : 'As directed',
                                'action': action,
                              }
                            ],
                          );
                      if (!ctx.mounted) return;
                      if (success) {
                        Navigator.of(ctx).pop();
                        if (mounted) {
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Medication updated and alert recorded!'),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        }
                      } else {
                        final err = alertProvider.errorMessage;
                        setDialogState(() {
                          isSaving = false;
                          localError = err ?? 'Failed to apply medication change.';
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Apply Medication Change'),
            ),
          ],
        ),
      ),
    );
  }

  void _addNoteDialog(BuildContext parentContext, LogProvider logProvider) {
    final noteController = TextEditingController();
    bool isSaving = false;
    String? localError;

    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Clinical Note to Alert'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (localError != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.criticalRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    localError!,
                    style: const TextStyle(color: AppTheme.criticalRed, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note Content',
                  hintText: 'Enter observation regarding alert...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final content = noteController.text.trim();
                      if (content.isEmpty) {
                        setDialogState(() => localError = 'Please enter note content');
                        return;
                      }

                      final pId = widget.alert.patientId ?? '';
                      if (pId.isEmpty) {
                        setDialogState(() => localError = 'Alert does not have an associated patient ID');
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(parentContext);
                      final navigator = Navigator.of(parentContext);

                      setDialogState(() {
                        isSaving = true;
                        localError = null;
                      });

                      final success = await logProvider.addAlertNote(
                        alertId: widget.alert.id,
                        patientId: pId,
                        content: content,
                      );
                      if (!ctx.mounted) return;
                      if (success) {
                        Navigator.of(ctx).pop();
                        if (mounted) {
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Clinical note added to alert!'),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        }
                      } else {
                        final err = logProvider.errorMessage;
                        setDialogState(() {
                          isSaving = false;
                          localError = err ?? 'Failed to add note to alert.';
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Note'),
            ),
          ],
        ),
      ),
    );
  }
}
