import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/officer_account.dart';
import '../../core/models/officer_profile.dart';
import '../../core/routing/app_routes.dart';
import '../../core/services/authenticated_http.dart';
import '../../core/services/profile_repository.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/home_button.dart';
import '../cv_upload/cv_upload_sheet.dart';

/// The "Profile" tab root — account details and profile management only.
/// The 25 feature modules themselves live under the Career, Jobs, and Learn
/// tabs (see lib/features/shell/), reached through the app's persistent
/// navigation rather than a flat button list here.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProfileRepository>();
    final profile = repo.profile;

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
          const HomeButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        children: [
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(profile.segment.fullLabel),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                key: const Key('entitlementChip'),
                label: Text((repo.account?.entitlementTier ?? EntitlementTier.free).label),
                visualDensity: VisualDensity.compact,
              ),
            ],
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
            children: profile.cvFileName.isEmpty
                ? [
                    const _InfoRow(label: 'File', value: 'Not uploaded'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      key: const Key('addCvButton'),
                      onPressed: () => showCvUploadSheet(context),
                      child: const Text('Add CV'),
                    ),
                  ]
                : [_InfoRow(label: 'File', value: profile.cvFileName)],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('transitionPlanButton'),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.transitionPlan),
              child: const Text('My Transition Plan'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('helpAndSupportButton'),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.supportTicket),
              child: const Text('Help & Support'),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              key: const Key('signOutButton'),
              onPressed: () {
                final refreshToken = repo.refreshToken;
                if (refreshToken != null) revokeRefreshToken(refreshToken);
                repo.clearSession();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.phoneVerification, (route) => false);
              },
              child: const Text('Sign out'),
            ),
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
