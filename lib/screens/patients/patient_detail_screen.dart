import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/patient_model.dart';
import '../../providers/patient_provider.dart';
import '../../providers/log_provider.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  final PatientModel? initialPatient;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    this.initialPatient,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().selectPatient(widget.patientId);
      context.read<LogProvider>().fetchDailyLogs(widget.patientId);
      context.read<LogProvider>().fetchPatientNotes(widget.patientId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showAddNoteDialog() {
    String selectedCategory = 'GENERAL';
    bool isSaving = false;
    String? localError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Clinical Note'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (localError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.criticalRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        localError!,
                        style: const TextStyle(color: AppTheme.criticalRed, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Note Category',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'GENERAL', child: Text('General Clinical Note')),
                      DropdownMenuItem(value: 'DIETARY', child: Text('Dietary Guidance')),
                      DropdownMenuItem(value: 'MEDICATION', child: Text('Medication Review')),
                      DropdownMenuItem(value: 'LIFESTYLE', child: Text('Lifestyle & Activity')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Enter clinical observations, updates, or instructions...',
                    ),
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
                        final content = _noteController.text.trim();
                        if (content.isEmpty) {
                          setDialogState(() => localError = 'Please enter note content');
                          return;
                        }

                        final logProvider = context.read<LogProvider>();
                        final messenger = ScaffoldMessenger.of(context);

                        setDialogState(() {
                          isSaving = true;
                          localError = null;
                        });

                        final success = await logProvider.addPatientNote(
                              patientId: widget.patientId,
                              content: content,
                              category: selectedCategory,
                            );

                        if (!ctx.mounted) return;
                        if (success) {
                          _noteController.clear();
                          Navigator.of(ctx).pop();
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Clinical note saved successfully!'),
                                backgroundColor: AppTheme.successGreen,
                              ),
                            );
                          }
                        } else {
                          final err = logProvider.errorMessage;
                          setDialogState(() {
                            isSaving = false;
                            localError = err ?? 'Failed to save note. Please try again.';
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
          );
        },
      ),
    );
  }

  void _showAddPrescriptionDialog() {
    final medNameController = TextEditingController();
    final doseController = TextEditingController();
    final freqController = TextEditingController(text: 'Twice daily');
    final durationController = TextEditingController(text: '30 days');
    final instructionsController = TextEditingController(text: 'After meals');
    final adviceController = TextEditingController();
    String action = 'NEW';
    bool isSaving = false;
    String? localError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Prescription / Medication'),
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
                  decoration: const InputDecoration(labelText: 'Medicine Name * (e.g. Metformin 500mg)'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: doseController,
                        decoration: const InputDecoration(labelText: 'Dose * (e.g. 500mg)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: action,
                        decoration: const InputDecoration(labelText: 'Action'),
                        items: const [
                          DropdownMenuItem(value: 'NEW', child: Text('NEW')),
                          DropdownMenuItem(value: 'CONTINUE', child: Text('CONTINUE')),
                          DropdownMenuItem(value: 'MODIFIED', child: Text('MODIFIED')),
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
                  decoration: const InputDecoration(labelText: 'Instructions (e.g. After food)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: adviceController,
                  decoration: const InputDecoration(labelText: 'Clinical Advice / Notes'),
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

                      final patientProvider = context.read<PatientProvider>();
                      final messenger = ScaffoldMessenger.of(context);

                      setDialogState(() {
                        isSaving = true;
                        localError = null;
                      });

                      final success = await patientProvider.createPrescription(
                            patientId: widget.patientId,
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
                            advice: adviceController.text.trim().isNotEmpty ? adviceController.text.trim() : null,
                          );

                      if (!ctx.mounted) return;
                      if (success) {
                        Navigator.of(ctx).pop();
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Prescription created successfully!'),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        }
                      } else {
                        final err = patientProvider.errorMessage;
                        setDialogState(() {
                          isSaving = false;
                          localError = err ?? 'Failed to save prescription.';
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Prescription'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLogNoteDialog(String logId) {
    final noteController = TextEditingController();
    bool isSaving = false;
    String? localError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Note to Daily Log'),
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
                  labelText: 'Log Observation / Note',
                  hintText: 'Enter observation for this specific log...',
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

                      final logProvider = context.read<LogProvider>();
                      final messenger = ScaffoldMessenger.of(context);

                      setDialogState(() {
                        isSaving = true;
                        localError = null;
                      });

                      final success = await logProvider.addLogNote(
                            logId: logId,
                            patientId: widget.patientId,
                            content: content,
                          );

                      if (!ctx.mounted) return;
                      if (success) {
                        Navigator.of(ctx).pop();
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Note added to daily log!'),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        }
                      } else {
                        final err = logProvider.errorMessage;
                        setDialogState(() {
                          isSaving = false;
                          localError = err ?? 'Failed to add note to log.';
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

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();
    final patient = patientProvider.selectedPatient ?? widget.initialPatient;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patient?.name ?? 'Patient Details',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (patient?.patientDisplayId != null)
              Text(
                'ID: ${patient!.patientDisplayId}',
                style: const TextStyle(fontSize: 11, color: AppTheme.secondaryColor),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add_outlined),
            tooltip: 'Add Clinical Note',
            onPressed: _showAddNoteDialog,
          ),
          IconButton(
            icon: const Icon(Icons.medication_outlined),
            tooltip: 'Add Prescription',
            onPressed: _showAddPrescriptionDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<PatientProvider>().selectPatient(widget.patientId);
              context.read<LogProvider>().fetchDailyLogs(widget.patientId);
              context.read<LogProvider>().fetchPatientNotes(widget.patientId);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Vitals & Logs'),
            Tab(text: 'Notes'),
            Tab(text: 'Rx & Meds'),
            Tab(text: 'Meal Photos'),
          ],
        ),
      ),
      body: patientProvider.isDetailsLoading && patient == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. Daily Logs / Vitals Tab
                _DailyLogsTab(
                  patientId: widget.patientId,
                  onAddLogNote: _showAddLogNoteDialog,
                ),

                // 2. Clinical Notes Tab
                _ClinicalNotesTab(
                  patientId: widget.patientId,
                  onAddNote: _showAddNoteDialog,
                ),

                // 3. Prescriptions & Medications Tab
                _PrescriptionsTab(
                  onAddPrescription: _showAddPrescriptionDialog,
                ),

                // 4. Meal Photos Tab
                _MealPhotosTab(),
              ],
            ),
    );
  }
}

class _DailyLogsTab extends StatelessWidget {
  final String patientId;
  final void Function(String logId)? onAddLogNote;

  const _DailyLogsTab({
    required this.patientId,
    this.onAddLogNote,
  });

  @override
  Widget build(BuildContext context) {
    final logProvider = context.watch<LogProvider>();

    if (logProvider.isLoadingLogs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (logProvider.dailyLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.monitor_heart_outlined,
                size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No daily logs recorded yet for this patient.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => logProvider.fetchDailyLogs(patientId),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logProvider.dailyLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = logProvider.dailyLogs[index];
        final dateStr = DateFormat('MMM dd, yyyy - hh:mm a').format(log.date);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (log.recordedBy != null)
                      Text(
                        'By: ${log.recordedBy}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
                const Divider(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    if (log.bloodPressureSystolic != null &&
                        log.bloodPressureDiastolic != null)
                      _VitalMetricBadge(
                        label: 'Blood Pressure',
                        value:
                            '${log.bloodPressureSystolic!.toInt()}/${log.bloodPressureDiastolic!.toInt()} mmHg',
                        icon: Icons.favorite,
                        color: AppTheme.criticalRed,
                      ),
                    if (log.fbs != null)
                      _VitalMetricBadge(
                        label: 'Fasting Sugar (FBS)',
                        value: '${log.fbs} mg/dL',
                        icon: Icons.bloodtype,
                        color: log.fbs! > 140
                            ? AppTheme.criticalRed
                            : AppTheme.successGreen,
                      ),
                    if (log.ppbs != null)
                      _VitalMetricBadge(
                        label: 'Post-Prandial (PPBS)',
                        value: '${log.ppbs} mg/dL',
                        icon: Icons.bloodtype_outlined,
                        color: log.ppbs! > 180
                            ? AppTheme.criticalRed
                            : AppTheme.warningAmber,
                      ),
                    if (log.bloodSugar != null && log.fbs == null && log.ppbs == null)
                      _VitalMetricBadge(
                        label: 'Blood Sugar',
                        value: '${log.bloodSugar} mg/dL',
                        icon: Icons.bloodtype,
                        color: AppTheme.warningAmber,
                      ),
                    if (log.heartRate != null)
                      _VitalMetricBadge(
                        label: 'Heart Rate',
                        value: '${log.heartRate!.toInt()} bpm',
                        icon: Icons.monitor_heart,
                        color: AppTheme.primaryColor,
                      ),
                    if (log.weight != null)
                      _VitalMetricBadge(
                        label: 'Weight',
                        value: '${log.weight} kg',
                        icon: Icons.scale_outlined,
                        color: AppTheme.infoBlue,
                      ),
                  ],
                ),
                if (log.symptoms.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Reported Symptoms:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: log.symptoms
                        .map(
                          (s) => Chip(
                            label: Text(s, style: const TextStyle(fontSize: 11)),
                            backgroundColor: Colors.grey.shade100,
                            padding: EdgeInsets.zero,
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Remarks: ${log.notes}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                const Divider(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.note_add_outlined, size: 16),
                    label: const Text('Add Note to Log', style: TextStyle(fontSize: 12)),
                    onPressed: () => onAddLogNote?.call(log.id),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VitalMetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _VitalMetricBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ],
        ),
      ],
    );
  }
}

class _ClinicalNotesTab extends StatelessWidget {
  final String patientId;
  final VoidCallback onAddNote;

  const _ClinicalNotesTab({
    required this.patientId,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    final logProvider = context.watch<LogProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAddNote,
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: logProvider.isLoadingNotes
          ? const Center(child: CircularProgressIndicator())
          : logProvider.patientNotes.isEmpty
              ? const Center(
                  child: Text(
                    'No clinical notes yet. Tap + to add the first note.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: logProvider.patientNotes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final note = logProvider.patientNotes[index];
                    final dateStr =
                        DateFormat('MMM dd, yyyy - hh:mm a').format(note.createdAt);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  note.authorName ?? 'Doctor / Staff',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              note.content,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _PrescriptionsTab extends StatelessWidget {
  final VoidCallback? onAddPrescription;

  const _PrescriptionsTab({this.onAddPrescription});

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();
    final prescriptions = patientProvider.prescriptions;
    final medications = patientProvider.medications;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAddPrescription,
        icon: const Icon(Icons.add),
        label: const Text('Add Prescription'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: (prescriptions.isEmpty && medications.isEmpty)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.medication_outlined, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  const Text(
                    'No prescriptions or medications recorded.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onAddPrescription,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Prescription'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
        if (medications.isNotEmpty) ...[
          const Text(
            'Active Medications',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...medications.map(
            (med) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.medication, color: AppTheme.secondaryColor),
                ),
                title: Text(med.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${med.dosage ?? ""} ${med.frequency != null ? "• ${med.frequency}" : ""}',
                ),
                trailing: Text(
                  med.duration ?? 'Active',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (prescriptions.isNotEmpty) ...[
          const Text(
            'Prescription Records',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...prescriptions.map(
            (rx) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(
                  'Rx: ${rx.status ?? "Prescription"}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Issued ${DateFormat('MMM dd, yyyy').format(rx.createdAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (rx.diagnosis != null)
                          Text('Diagnosis: ${rx.diagnosis}',
                              style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        ...rx.medications.map(
                          (m) => Text('• ${m.name} - ${m.dosage ?? ""} (${m.frequency ?? ""})'),
                        ),
                        if (rx.notes != null) ...[
                          const SizedBox(height: 6),
                          Text('Instructions: ${rx.notes}',
                              style: const TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
    );
  }
}

class _MealPhotosTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final logProvider = context.watch<LogProvider>();
    final logs = logProvider.dailyLogs;

    // Collect meal photos from daily logs
    final mealItems = <Map<String, String>>[];
    for (final log in logs) {
      final dateStr = DateFormat('MMM dd, yyyy').format(log.date);
      if (log.breakfastPhoto != null && log.breakfastPhoto!.isNotEmpty) {
        mealItems.add({'title': 'Breakfast', 'url': log.breakfastPhoto!, 'date': dateStr});
      }
      if (log.lunchPhoto != null && log.lunchPhoto!.isNotEmpty) {
        mealItems.add({'title': 'Lunch', 'url': log.lunchPhoto!, 'date': dateStr});
      }
      if (log.dinnerPhoto != null && log.dinnerPhoto!.isNotEmpty) {
        mealItems.add({'title': 'Dinner', 'url': log.dinnerPhoto!, 'date': dateStr});
      }
      if (log.snackPhoto != null && log.snackPhoto!.isNotEmpty) {
        mealItems.add({'title': 'Snack', 'url': log.snackPhoto!, 'date': dateStr});
      }
      if (log.juicePhoto != null && log.juicePhoto!.isNotEmpty) {
        mealItems.add({'title': 'Juice', 'url': log.juicePhoto!, 'date': dateStr});
      }
    }

    if (mealItems.isEmpty) {
      return const Center(
        child: Text(
          'No meal photos attached to patient logs yet.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: mealItems.length,
      itemBuilder: (context, index) {
        final meal = mealItems[index];

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Image.network(
                  meal['url']!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image,
                        color: AppTheme.textMuted),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal['title']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      meal['date']!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
