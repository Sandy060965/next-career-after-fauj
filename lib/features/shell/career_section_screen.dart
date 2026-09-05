import 'package:flutter/material.dart';

import '../../core/routing/app_routes.dart';
import '../../core/widgets/section_list_widgets.dart';

/// The "Career" tab root — orientation tools plus the self-assessment and
/// gap-analysis chain (Career Vertical Fit → Target Role Strategy →
/// JD Match → Refined CV / Gap Roadmap).
class CareerSectionScreen extends StatelessWidget {
  const CareerSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Career')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        children: const [
          PhaseHeader('Orientation'),
          ModuleButton(
            keyName: 'careerPathsButton',
            route: AppRoutes.careerPaths,
            label: 'Career Paths',
          ),
          ModuleButton(
            keyName: 'careerHandbookButton',
            route: AppRoutes.careerHandbook,
            label: 'Career Vertical Handbook',
          ),
          ModuleButton(
            keyName: 'corpsMatrixButton',
            route: AppRoutes.corpsMatrix,
            label: 'Corps/Arm/Branch Fit Matrix',
          ),
          ModuleButton(
            keyName: 'skillEquivalencyButton',
            route: AppRoutes.skillEquivalency,
            label: 'Skill Equivalency Matrix',
          ),
          PhaseHeader('Self-Assessment & Gap Analysis'),
          ModuleButton(
            keyName: 'careerReadinessButton',
            route: AppRoutes.careerReadiness,
            label: 'Transition Readiness Index',
          ),
          ModuleButton(
            keyName: 'aiReadinessButton',
            route: AppRoutes.aiReadiness,
            label: 'AI Readiness',
          ),
          ModuleButton(
            keyName: 'verticalFitButton',
            route: AppRoutes.verticalFit,
            label: 'Career Vertical Fit',
          ),
          ModuleButton(
            keyName: 'targetRoleStrategyButton',
            route: AppRoutes.targetRoleStrategy,
            label: 'Target Role Strategy',
          ),
          ModuleButton(
            keyName: 'jdMatchButton',
            route: AppRoutes.jdMatch,
            label: 'JD Match',
          ),
          ModuleButton(
            keyName: 'refinedCvButton',
            route: AppRoutes.refinedCv,
            label: 'Refined CV',
          ),
          ModuleButton(
            keyName: 'gapRoadmapButton',
            route: AppRoutes.gapRoadmap,
            label: 'Gap Roadmap',
          ),
        ],
      ),
    );
  }
}
