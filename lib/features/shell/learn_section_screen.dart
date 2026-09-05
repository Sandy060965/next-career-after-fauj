import 'package:flutter/material.dart';

import '../../core/routing/app_routes.dart';
import '../../core/widgets/section_list_widgets.dart';

/// The "Learn" tab root — CV-building tools and interview/communication
/// preparation, grouped separately from the assessment chain under Career.
class LearnSectionScreen extends StatelessWidget {
  const LearnSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        children: const [
          PhaseHeader('Build Your CV'),
          ModuleButton(
            keyName: 'cvCivilianizerButton',
            route: AppRoutes.cvCivilianizer,
            label: 'Base CV, Civilianized',
          ),
          ModuleButton(
            keyName: 'cvBuilderButton',
            route: AppRoutes.cvBuilder,
            label: 'Build My Civilian CV',
          ),
          ModuleButton(
            keyName: 'cvWritingGuideButton',
            route: AppRoutes.cvWritingGuide,
            label: 'CV Writing Guide & Templates',
          ),
          ModuleButton(
            keyName: 'corporateLanguageGuideButton',
            route: AppRoutes.corporateLanguageGuide,
            label: 'Corporate Language Guide',
          ),
          PhaseHeader('Prepare'),
          ModuleButton(
            keyName: 'readingProgrammeButton',
            route: AppRoutes.readingProgramme,
            label: 'Corporate Transition - Reading Programme',
          ),
          ModuleButton(
            keyName: 'interviewPrepButton',
            route: AppRoutes.interviewPrep,
            label: 'Interview Prep',
          ),
        ],
      ),
    );
  }
}
