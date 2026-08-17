import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/officer_profile.dart';
import '../../core/routing/app_routes.dart';
import '../../core/services/profile_repository.dart';
import '../../core/utils/date_format.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileRepository>().profile;

    if (profile == null) {
      return const Scaffold(body: Center(child: Text('No profile found yet.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Chip(
            label: Text(profile.segment.fullLabel),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Profile details',
            children: [
              _InfoRow(label: 'Service', value: profile.service.label),
              _InfoRow(label: 'Rank', value: profile.rank),
              _InfoRow(label: 'Name', value: profile.fullName),
              _InfoRow(label: 'Date of birth', value: formatDate(profile.dateOfBirth)),
              _InfoRow(
                label: 'Work experience',
                value: '${profile.workExperienceYears} yrs ${profile.workExperienceMonths} mos',
              ),
              _InfoRow(
                label: profile.releaseStatus == ReleaseStatus.alreadyReleased
                    ? 'Date of release'
                    : 'Tentative release date',
                value: formatDate(profile.releaseDate),
              ),
              _InfoRow(label: 'Mobile', value: profile.mobileNumber),
              _InfoRow(label: 'Email', value: profile.email),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'CV',
            children: [_InfoRow(label: 'File', value: profile.cvFileName)],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('careerPathsButton'),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.careerPaths),
              child: const Text('Career Paths'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('jdMatchButton'),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.jdMatch),
              child: const Text('JD Match'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('jobMatchesButton'),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.jobMatches),
              child: const Text('Job Matches'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('linkedinWriteupButton'),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.linkedinWriteup),
              child: const Text('LinkedIn Write-up'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('aiReadinessButton'),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.aiReadiness),
              child: const Text('AI Readiness'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Subscription unlock as this build progresses.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
