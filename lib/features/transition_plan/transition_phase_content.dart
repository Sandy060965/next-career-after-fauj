import '../../core/routing/app_routes.dart';

/// One curated action within a phase — points at a real, existing module,
/// never a generated suggestion. [completionCheck] optionally lets the
/// screen show this as already done, using state the app already has
/// (e.g. a completed Vertical Fit assessment).
class TransitionAction {
  const TransitionAction({
    required this.title,
    required this.route,
    required this.moduleLabel,
    this.completionCheck,
  });

  final String title;
  final String route;
  final String moduleLabel;

  /// A key identifying which cached repository state (if any) marks this
  /// action complete — resolved by the screen, not stored here, since the
  /// content list is static and the completion state is not.
  final String? completionCheck;
}

/// A single milestone in the transition timeline, anchored to how many
/// months before release it targets (0 = release/joining itself). Content
/// is fixed and curated — universal guidance, not personalised or
/// generated, so there's nothing to fabricate.
class TransitionPhaseContent {
  const TransitionPhaseContent({
    required this.monthsBeforeRelease,
    required this.label,
    required this.headline,
    required this.actions,
  });

  final int monthsBeforeRelease;
  final String label;
  final String headline;
  final List<TransitionAction> actions;
}

const List<TransitionPhaseContent> kTransitionPlan = [
  TransitionPhaseContent(
    monthsBeforeRelease: 12,
    label: 'T-12 months',
    headline: 'Understand your options',
    actions: [
      TransitionAction(
        title: 'Take the Career Vertical Fit assessment',
        route: AppRoutes.verticalFit,
        moduleLabel: 'Career Vertical Fit',
        completionCheck: 'verticalFit',
      ),
      TransitionAction(
        title: 'Explore Career Paths for verticals that interest you',
        route: AppRoutes.careerPaths,
        moduleLabel: 'Career Paths',
      ),
      TransitionAction(
        title: 'Take the AI Readiness assessment',
        route: AppRoutes.aiReadiness,
        moduleLabel: 'AI Readiness',
        completionCheck: 'aiReadiness',
      ),
    ],
  ),
  TransitionPhaseContent(
    monthsBeforeRelease: 9,
    label: 'T-9 months',
    headline: 'Test your fit against real roles',
    actions: [
      TransitionAction(
        title: 'Run JD Match against 2-3 target job descriptions',
        route: AppRoutes.jdMatch,
        moduleLabel: 'JD Match',
        completionCheck: 'jdMatch',
      ),
      TransitionAction(
        title: 'Review your Gap Roadmap and start on priority gaps',
        route: AppRoutes.gapRoadmap,
        moduleLabel: 'Gap Roadmap',
      ),
      TransitionAction(
        title: 'Check Compensation Guidance for your target roles',
        route: AppRoutes.compensation,
        moduleLabel: 'Compensation Guidance',
      ),
    ],
  ),
  TransitionPhaseContent(
    monthsBeforeRelease: 6,
    label: 'T-6 months',
    headline: 'Build your civilian presence',
    actions: [
      TransitionAction(
        title: 'Get your Refined CV ready',
        route: AppRoutes.refinedCv,
        moduleLabel: 'Refined CV',
      ),
      TransitionAction(
        title: 'Generate your LinkedIn Write-up and update your profile',
        route: AppRoutes.linkedinWriteup,
        moduleLabel: 'LinkedIn Write-up',
      ),
      TransitionAction(
        title: 'Start browsing Job Matches for your target verticals',
        route: AppRoutes.jobMatches,
        moduleLabel: 'Job Matches',
      ),
    ],
  ),
  TransitionPhaseContent(
    monthsBeforeRelease: 4,
    label: 'T-4 months',
    headline: 'Start actively applying',
    actions: [
      TransitionAction(
        title: 'Apply to shortlisted roles and log them in your tracker',
        route: AppRoutes.jobMatches,
        moduleLabel: 'Job Matches',
      ),
      TransitionAction(
        title: 'Track every application through the pipeline',
        route: AppRoutes.applicationTracker,
        moduleLabel: 'Application Tracker',
      ),
      TransitionAction(
        title: "Prepare using Interview Prep's question bank",
        route: AppRoutes.interviewPrep,
        moduleLabel: 'Interview Prep',
      ),
    ],
  ),
  TransitionPhaseContent(
    monthsBeforeRelease: 2,
    label: 'T-2 months',
    headline: 'Interview and negotiate',
    actions: [
      TransitionAction(
        title: 'Run Mock Interviews for roles you\'re being considered for',
        route: AppRoutes.interviewPrep,
        moduleLabel: 'Interview Prep',
      ),
      TransitionAction(
        title: 'Finalize your compensation expectations',
        route: AppRoutes.compensation,
        moduleLabel: 'Compensation Guidance',
      ),
      TransitionAction(
        title: 'Review Your First 90 Days before you join',
        route: AppRoutes.ninetyDayRoadmap,
        moduleLabel: 'Your First 90 Days',
      ),
    ],
  ),
  TransitionPhaseContent(
    monthsBeforeRelease: 0,
    label: 'Joining',
    headline: 'Succeed in your new role',
    actions: [
      TransitionAction(
        title: 'Follow Your First 90 Days month by month',
        route: AppRoutes.ninetyDayRoadmap,
        moduleLabel: 'Your First 90 Days',
      ),
      TransitionAction(
        title: 'Revisit your Transition Readiness Index to track ongoing growth',
        route: AppRoutes.careerReadiness,
        moduleLabel: 'Transition Readiness Index',
      ),
    ],
  ),
];

/// The active phase for a given number of months remaining until release —
/// the smallest-threshold phase still at or above [monthsUntilRelease], so
/// an officer sees the phase whose milestone they've most recently reached
/// (or the earliest phase, if release is still further away than T-12).
TransitionPhaseContent currentTransitionPhase(int monthsUntilRelease) {
  final ascending = [...kTransitionPlan]
    ..sort((a, b) => a.monthsBeforeRelease.compareTo(b.monthsBeforeRelease));
  for (final phase in ascending) {
    if (monthsUntilRelease <= phase.monthsBeforeRelease) return phase;
  }
  return ascending.last;
}
