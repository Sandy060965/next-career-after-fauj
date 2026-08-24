import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/job_application.dart';
import '../../core/services/profile_repository.dart';
import '../../core/utils/date_format.dart';
import 'add_edit_application_screen.dart';

class ApplicationTrackerScreen extends StatelessWidget {
  const ApplicationTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final applications = context.watch<ProfileRepository>().applications;

    return Scaffold(
      appBar: AppBar(title: const Text('Application Tracker')),
      floatingActionButton: FloatingActionButton(
        key: const Key('addApplicationFab'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditApplicationScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: applications.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No applications tracked yet. Tap + to log the first company/role '
                  "you're pursuing.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 88),
              children: [
                _FunnelSummary(applications: applications),
                const SizedBox(height: 16),
                ...applications.map((a) => _ApplicationCard(application: a)),
              ],
            ),
    );
  }
}

class _FunnelSummary extends StatelessWidget {
  const _FunnelSummary({required this.applications});

  final List<JobApplication> applications;

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final status in ApplicationStatus.values)
        status: applications.where((a) => a.status == status).length,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final status in ApplicationStatus.values)
          if (counts[status]! > 0)
            Chip(
              key: ValueKey('funnelCount_${status.name}'),
              label: Text('${status.label}: ${counts[status]}'),
              visualDensity: VisualDensity.compact,
            ),
      ],
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      key: ValueKey('application_${application.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddEditApplicationScreen(existing: application)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(application.roleTitle, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Chip(
                    label: Text(application.status.label),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colorScheme.secondaryContainer,
                    labelStyle: TextStyle(color: colorScheme.onSecondaryContainer, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                application.companyName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (application.source != null) ...[
                const SizedBox(height: 4),
                Text('Source: ${application.source}', style: Theme.of(context).textTheme.bodySmall),
              ],
              if (application.nextActionNote != null || application.nextActionDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  [
                    if (application.nextActionNote != null) application.nextActionNote,
                    if (application.nextActionDate != null) 'by ${formatDate(application.nextActionDate!)}',
                  ].join(' — '),
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
