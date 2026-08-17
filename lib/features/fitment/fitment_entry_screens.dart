import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../core/services/profile_repository.dart';
import 'gap_roadmap_screen.dart';
import 'refined_cv_screen.dart';

/// Shown when a top-level fitment screen (Refined CV, Gap Roadmap) is
/// opened before the officer has ever run JD Match — there's no result to
/// show yet, so this prompts them to run it rather than showing nothing.
class _NoFitmentResultYet extends StatelessWidget {
  const _NoFitmentResultYet({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              ElevatedButton(
                key: const Key('goToJdMatchButton'),
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.jdMatch),
                child: const Text('Run JD Match'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top-level "Refined CV" entry point — reads the most recent JD-match
/// result from [ProfileRepository] instead of requiring navigation params.
class RefinedCvEntryScreen extends StatelessWidget {
  const RefinedCvEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<ProfileRepository>();
    final result = repository.lastFitmentResult;
    if (result == null) {
      return const _NoFitmentResultYet(
        title: 'Refined CV',
        body: 'Run JD Match against a job description first — your refined CV will '
            'appear here once it does.',
      );
    }
    return RefinedCvScreen(
      result: result,
      originalCvText: repository.profile?.cvExtractedText,
    );
  }
}

/// Top-level "Gap Roadmap" entry point — reads the most recent JD-match
/// result from [ProfileRepository] instead of requiring navigation params.
class GapRoadmapEntryScreen extends StatelessWidget {
  const GapRoadmapEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = context.watch<ProfileRepository>().lastFitmentResult;
    if (result == null) {
      return const _NoFitmentResultYet(
        title: 'Gap Roadmap',
        body: 'Run JD Match against a job description first — your gap analysis and '
            'roadmap will appear here once it does.',
      );
    }
    return GapRoadmapScreen(result: result);
  }
}
