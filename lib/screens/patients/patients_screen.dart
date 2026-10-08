import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/patient_provider.dart';
import 'patient_detail_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Patients',
            onPressed: () => provider.fetchPatients(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => provider.search(val),
                  decoration: InputDecoration(
                    hintText: 'Search patients by name, ID or phone...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.search('');
                            },
                          )
                        : null,
                  ),
                ),
                if (provider.batches.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All Batches'),
                          selected: provider.selectedBatch == null,
                          onSelected: (_) => provider.filterByBatch(null),
                        ),
                        const SizedBox(width: 6),
                        ...provider.batches.map((batch) {
                          final String batchName = batch is Map
                              ? (batch['batchCode'] ?? batch['name'] ?? batch['batch'] ?? batch['id'] ?? 'Batch').toString()
                              : batch.toString();
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(batchName),
                              selected: provider.selectedBatch == batchName,
                              onSelected: (_) =>
                                  provider.filterByBatch(batchName),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Patients List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppTheme.criticalRed),
                              const SizedBox(height: 12),
                              Text(
                                provider.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                onPressed: () => provider.fetchPatients(refresh: true),
                              ),
                            ],
                          ),
                        ),
                      )
                    : provider.patients.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline, size: 48, color: AppTheme.textMuted),
                                SizedBox(height: 8),
                                Text(
                                  'No patients found matching your search.',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.fetchPatients(refresh: true),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: provider.patients.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final patient = provider.patients[index];
                                return Card(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PatientDetailScreen(
                                            patientId: patient.id,
                                            initialPatient: patient,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: AppTheme.primaryColor
                                                .withValues(alpha: 0.12),
                                            child: Text(
                                              patient.name.isNotEmpty
                                                  ? patient.name[0].toUpperCase()
                                                  : 'P',
                                              style: const TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        patient.name,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppTheme.textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                    if (patient.hasAlert)
                                                      Container(
                                                        margin: const EdgeInsets.only(right: 6),
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.criticalRed
                                                              .withValues(alpha: 0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(6),
                                                          border: Border.all(
                                                            color: AppTheme.criticalRed
                                                                .withValues(alpha: 0.4),
                                                          ),
                                                        ),
                                                        child: const Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.warning_amber_rounded,
                                                                size: 12,
                                                                color: AppTheme.criticalRed),
                                                            SizedBox(width: 3),
                                                            Text(
                                                              'ALERT',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                                color: AppTheme.criticalRed,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    if (patient.patientDisplayId != null)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.secondaryColor
                                                              .withValues(alpha: 0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          patient.patientDisplayId!,
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppTheme.secondaryColor,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  '${patient.age != null ? "${patient.age} yrs" : ""}'
                                                  '${patient.gender != null ? " • ${patient.gender}" : ""}'
                                                  '${patient.phone != null ? " • ${patient.phone}" : ""}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 6,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    if (patient.glucoseStatus != null)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: (patient.glucoseStatus == 'CRITICAL'
                                                                  ? AppTheme.criticalRed
                                                                  : patient.glucoseStatus == 'WARNING'
                                                                      ? AppTheme.warningOrange
                                                                      : AppTheme.successGreen)
                                                              .withValues(alpha: 0.12),
                                                          borderRadius:
                                                              BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          patient.glucoseStatus!,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: patient.glucoseStatus == 'CRITICAL'
                                                                ? AppTheme.criticalRed
                                                                : patient.glucoseStatus == 'WARNING'
                                                                    ? AppTheme.warningOrange
                                                                    : AppTheme.successGreen,
                                                          ),
                                                        ),
                                                      ),
                                                    if (patient.lastLogDate != null)
                                                      Text(
                                                        'Log: ${patient.lastLogDate!.day}/${patient.lastLogDate!.month}/${patient.lastLogDate!.year}',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme.textSecondary,
                                                        ),
                                                      )
                                                    else
                                                      const Text(
                                                        'No logs yet',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme.textMuted,
                                                          fontStyle: FontStyle.italic,
                                                        ),
                                                      ),
                                                    if (patient.hba1c != null)
                                                      Text(
                                                        '• HbA1c: ${patient.hba1c}%',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme.textSecondary,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right,
                                            color: AppTheme.textMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
