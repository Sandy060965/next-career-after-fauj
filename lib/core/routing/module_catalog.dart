import '../theme/app_theme.dart';
import 'app_routes.dart';

/// Per-category accent colours, drawn from the existing palette
/// (core/theme/app_theme.dart) rather than new ones — used for each
/// category's phase headings (career/jobs/learn_section_screen.dart) and
/// the wide-screen sidebar's phase labels (app_sidebar.dart), so the same
/// category always reads in the same colour everywhere it appears.
///
/// Career deliberately uses [AppColors.brassDeep], not [AppColors.oliveDeep]
/// — oliveDeep is the app's primary colour, already used everywhere in the
/// chrome (buttons, selected nav, the FAB), so reusing it here didn't read
/// as a distinct category colour the way Jobs' blue and Learn's green do.
const kCareerColor = AppColors.brassDeep;
const kJobsColor = AppColors.info;
const kLearnColor = AppColors.success;

/// One module reachable from a section tab — same data a `ModuleButton`
/// renders (see section_list_widgets.dart), extracted here as data rather
/// than inline widgets so both the section screens and the wide-screen
/// sidebar can render from a single source of truth.
///
/// [description] is a one-line, plain-English summary of what the module
/// does — not shown by `ModuleButton` itself today, but the single source
/// the Dashboard's "How This App Works" guide (dashboard_screen.dart) reads
/// from, so that guide can never drift out of sync with the real module list.
class ModuleEntry {
  const ModuleEntry({
    required this.keyName,
    required this.route,
    required this.label,
    required this.description,
  });

  final String keyName;
  final String route;
  final String label;
  final String description;
}

/// A named, ordered group of [ModuleEntry]s within a section — same
/// grouping the `PhaseHeader` widgets render today.
class ModulePhase {
  const ModulePhase({required this.title, required this.modules});

  final String title;
  final List<ModuleEntry> modules;
}

const List<ModulePhase> kCareerModules = [
  ModulePhase(
    title: 'Orientation',
    modules: [
      ModuleEntry(
        keyName: 'careerPathsButton',
        route: AppRoutes.careerPaths,
        label: 'Career Paths',
        description: 'Explore civilian career paths mapped to your Service background.',
      ),
      ModuleEntry(
        keyName: 'careerHandbookButton',
        route: AppRoutes.careerHandbook,
        label: 'Career Vertical Handbook',
        description: 'Deep-dive briefs on all 34 verticals — what each does, how officers typically '
            'grow into it, and what it takes to get hired.',
      ),
      ModuleEntry(
        keyName: 'corpsMatrixButton',
        route: AppRoutes.corpsMatrix,
        label: 'Corps/Arm/Branch Fit Matrix',
        description: 'See which verticals your specific Corps, Arm or Branch is naturally strongest in.',
      ),
    ],
  ),
  ModulePhase(
    title: 'Self-Assessment & Gap Analysis',
    modules: [
      ModuleEntry(
        keyName: 'careerReadinessButton',
        route: AppRoutes.careerReadiness,
        label: 'Transition Readiness Index',
        description: 'Your aggregate readiness score, combining Career Fit, AI Readiness and CV & JD '
            'Fit into one number.',
      ),
      ModuleEntry(
        keyName: 'aiReadinessButton',
        route: AppRoutes.aiReadiness,
        label: 'AI Readiness',
        description: 'Assess how prepared you are to work alongside AI tools in a corporate role, '
            'and get a 90-day roadmap to close the specific gaps the assessment finds.',
      ),
      ModuleEntry(
        keyName: 'verticalFitButton',
        route: AppRoutes.verticalFit,
        label: 'Career Vertical Fit',
        description: 'Score your fit against each civilian career vertical, based on your actual '
            'profile.',
      ),
      ModuleEntry(
        keyName: 'targetRoleStrategyButton',
        route: AppRoutes.targetRoleStrategy,
        label: 'Target Role Strategy',
        description: 'Turn your Career Vertical Fit results into a concrete shortlist of target roles.',
      ),
      ModuleEntry(
        keyName: 'jdMatchButton',
        route: AppRoutes.jdMatch,
        label: 'JD Match',
        description: 'Match your CV against a real (or AI-generated) job description and see exactly '
            'where it falls short — this is the "CV & JD Fit" assessment.',
      ),
      ModuleEntry(
        keyName: 'refinedCvButton',
        route: AppRoutes.refinedCv,
        label: 'Refined CV',
        description: 'An AI-refined, recruiter-ready rewrite of your CV — reframing what you\'ve '
            'already done, never inventing anything new.',
      ),
      ModuleEntry(
        keyName: 'gapRoadmapButton',
        route: AppRoutes.gapRoadmap,
        label: 'Gap Roadmap',
        description: 'A prioritised plan to close the specific gaps your last CV & JD Fit match '
            'found — across skills, certifications, experience and education/qualifications.',
      ),
    ],
  ),
];

const List<ModulePhase> kJobsModules = [
  ModulePhase(
    title: 'Active Job Search',
    modules: [
      ModuleEntry(
        keyName: 'jobMatchesButton',
        route: AppRoutes.jobMatches,
        label: 'Job Matches',
        description: 'Browse job openings matched against your CV and profile.',
      ),
      ModuleEntry(
        keyName: 'applicationTrackerButton',
        route: AppRoutes.applicationTracker,
        label: 'Application Tracker',
        description: 'Track every application\'s stage in one place, instead of a mental checklist.',
      ),
      ModuleEntry(
        keyName: 'networkDirectoryButton',
        route: AppRoutes.networkDirectory,
        label: 'Future Mentor Sign Up',
        description: 'Register your interest in mentoring other transitioning officers once you\'ve '
            'landed.',
      ),
      ModuleEntry(
        keyName: 'linkedinWriteupButton',
        route: AppRoutes.linkedinWriteup,
        label: 'LinkedIn Write-up',
        description: 'Get a ready-to-use LinkedIn headline, About section and transition announcement '
            'post.',
      ),
    ],
  ),
  ModulePhase(
    title: 'Compensation & Landing',
    modules: [
      ModuleEntry(
        keyName: 'compensationButton',
        route: AppRoutes.compensation,
        label: 'Compensation Guidance',
        description: 'Understand typical civilian compensation structures and how to negotiate them.',
      ),
      ModuleEntry(
        keyName: 'financialPlannerButton',
        route: AppRoutes.financialPlanner,
        label: 'Financial & Cost-of-Living Calculator',
        description: 'Compare your military package against a corporate offer, cost-of-living '
            'included.',
      ),
      ModuleEntry(
        keyName: 'ninetyDayRoadmapButton',
        route: AppRoutes.ninetyDayRoadmap,
        label: 'Your First 90 Days',
        description: 'A structured plan for settling in and establishing credibility in your first '
            'quarter on the job.',
      ),
    ],
  ),
];

const List<ModulePhase> kLearnModules = [
  ModulePhase(
    title: 'Build Your CV',
    modules: [
      ModuleEntry(
        keyName: 'cvCivilianizerButton',
        route: AppRoutes.cvCivilianizer,
        label: 'Base CV, Civilianized',
        description: 'A first-pass rewrite of your existing Service CV into civilian language.',
      ),
      ModuleEntry(
        keyName: 'cvBuilderButton',
        route: AppRoutes.cvBuilder,
        label: 'Build My Civilian CV',
        description: 'Build a fresh civilian CV from scratch, section by section, and download it as '
            'a PDF.',
      ),
      ModuleEntry(
        keyName: 'cvWritingGuideButton',
        route: AppRoutes.cvWritingGuide,
        label: 'CV Writing Guide & Templates',
        description: 'A reference guide and templates for structuring a strong civilian CV yourself.',
      ),
      ModuleEntry(
        keyName: 'corporateLanguageGuideButton',
        route: AppRoutes.corporateLanguageGuide,
        label: 'Corporate Language Guide',
        description: 'Definitions of commonly used corporate terms and abbreviations, each bridged '
            'to a military-familiar equivalent, across 20 business-function categories (Finance, '
            'Sales & Marketing, Technology, HR and more) — built to speed up your settling-in.',
      ),
    ],
  ),
  ModulePhase(
    title: 'Prepare',
    modules: [
      ModuleEntry(
        keyName: 'readingProgrammeButton',
        route: AppRoutes.readingProgramme,
        label: 'Corporate Transition - Reading Programme',
        description: 'A curated, phased reading list to build corporate fluency before you start.',
      ),
      ModuleEntry(
        keyName: 'interviewPrepButton',
        route: AppRoutes.interviewPrep,
        label: 'Interview Prep',
        description: '48 common interview questions with guidance on answering them, plus '
            'additional questions likely for your specific role once you\'ve run JD Match — then '
            'run a mock interview and get constructive AI feedback on your answers.',
      ),
    ],
  ),
];
