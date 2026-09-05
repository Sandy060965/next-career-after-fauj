import 'package:flutter/material.dart';

import '../../core/routing/app_routes.dart';
import '../../core/widgets/section_list_widgets.dart';

/// The "Jobs" tab root — active job search plus compensation, interview
/// aftermath, and landing.
class JobsSectionScreen extends StatelessWidget {
  const JobsSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        children: const [
          PhaseHeader('Active Job Search'),
          ModuleButton(
            keyName: 'jobMatchesButton',
            route: AppRoutes.jobMatches,
            label: 'Job Matches',
          ),
          ModuleButton(
            keyName: 'applicationTrackerButton',
            route: AppRoutes.applicationTracker,
            label: 'Application Tracker',
          ),
          ModuleButton(
            keyName: 'networkDirectoryButton',
            route: AppRoutes.networkDirectory,
            label: 'Future Mentor Sign Up',
          ),
          ModuleButton(
            keyName: 'linkedinWriteupButton',
            route: AppRoutes.linkedinWriteup,
            label: 'LinkedIn Write-up',
          ),
          PhaseHeader('Compensation & Landing'),
          ModuleButton(
            keyName: 'compensationButton',
            route: AppRoutes.compensation,
            label: 'Compensation Guidance',
          ),
          ModuleButton(
            keyName: 'financialPlannerButton',
            route: AppRoutes.financialPlanner,
            label: 'Financial & Cost-of-Living Calculator',
          ),
          ModuleButton(
            keyName: 'ninetyDayRoadmapButton',
            route: AppRoutes.ninetyDayRoadmap,
            label: 'Your First 90 Days',
          ),
        ],
      ),
    );
  }
}
