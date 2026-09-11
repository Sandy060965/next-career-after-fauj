import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_routes.dart';
import 'core/services/auth_service.dart';
import 'core/services/officer_progress_sync.dart';
import 'core/services/profile_repository.dart';
import 'core/theme/app_theme.dart';
import 'features/ai_assistant/ai_assistant_http_service.dart';
import 'features/ai_assistant/ai_assistant_screen.dart';
import 'features/ai_readiness/ai_readiness_http_service.dart';
import 'features/ai_readiness/ai_readiness_quiz_screen.dart';
import 'features/application_tracker/application_tracker_screen.dart';
import 'features/auth/phone_verification_screen.dart';
import 'features/career_handbook/career_handbook_screen.dart';
import 'features/career_paths/career_paths_screen.dart';
import 'features/business_etiquette/business_etiquette_screen.dart';
import 'features/corporate_culture/corporate_culture_screen.dart';
import 'features/corporate_language/corporate_language_guide_screen.dart';
import 'features/corps_matrix/corps_matrix_screen.dart';
import 'features/learning_resources/learning_resources_screen.dart';
import 'features/reading_programme/reading_programme_screen.dart';
import 'features/career_readiness/career_readiness_screen.dart';
import 'features/compensation/compensation_http_service.dart';
import 'features/compensation/compensation_screen.dart';
import 'features/cv_builder/cv_builder_http_service.dart';
import 'features/cv_builder/cv_builder_screen.dart';
import 'features/cv_examples/cv_examples_screen.dart';
import 'features/cv_writing_guide/cv_writing_guide_screen.dart';
import 'features/cv_civilianizer/civilianizer_http_service.dart';
import 'features/cv_civilianizer/civilianizer_screen.dart';
import 'features/financial_planner/financial_planner_screen.dart';
import 'features/fitment/fitment_entry_screens.dart';
import 'features/fitment/fitment_http_service.dart';
import 'features/interview_prep/interview_prep_http_service.dart';
import 'features/interview_prep/interview_prep_screen.dart';
import 'features/interview_prep/mock_interview_http_service.dart';
import 'features/success_roadmap/ninety_day_roadmap_screen.dart';
import 'features/target_role/target_role_http_service.dart';
import 'features/target_role/target_role_strategy_screen.dart';
import 'features/vertical_fit/vertical_fit_quiz_screen.dart';
import 'features/jd_match/jd_match_screen.dart';
import 'features/jd_match/sample_jd_http_service.dart';
import 'features/job_matches/job_matches_http_service.dart';
import 'features/job_matches/job_matches_screen.dart';
import 'features/admin/admin_login_screen.dart';
import 'features/debug/debug_menu_screen.dart';
import 'features/linkedin_writeup/linkedin_writeup_http_service.dart';
import 'features/linkedin_writeup/linkedin_writeup_screen.dart';
import 'features/networking/network_directory_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/skill_equivalency/course_civilianization_http_service.dart';
import 'features/start_here/start_here_screen.dart';
import 'features/support/support_screen.dart';
import 'features/transition_plan/transition_plan_screen.dart';

// Debug-only escape hatch for local testing before Twilio is configured —
// false in every real build (App Store/Play Store builds never pass this
// flag). Only active when explicitly launched with
// --dart-define=SKIP_AUTH_FOR_TESTING=true.
const _skipAuthForTesting = bool.fromEnvironment('SKIP_AUTH_FOR_TESTING');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final profileRepository = ProfileRepository();
  await profileRepository.loadFromStorage();

  // Refresh the cached entitlement from the backend in the background —
  // e.g. to pick up a payment or a manually-granted test entitlement made
  // since the last launch. The app runs fine on the cached value if this
  // fails or the session has expired server-side.
  if (profileRepository.sessionToken != null) {
    unawaited(
      AuthService().fetchAccount(profileRepository).then((account) {
        if (account != null) profileRepository.updateAccount(account);
      }),
    );
  }

  runApp(NextCareerAfterFaujApp(profileRepository: profileRepository));
}

class NextCareerAfterFaujApp extends StatelessWidget {
  const NextCareerAfterFaujApp({
    super.key,
    required this.profileRepository,
    this.syncProgress = syncOfficerProgress,
  });

  final ProfileRepository profileRepository;

  /// Overridable for testing so a widget test that reaches MainShell never
  /// makes a real network call just by mounting the app.
  final Future<void> Function(ProfileRepository repo) syncProgress;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: profileRepository,
      child: MaterialApp(
        title: 'Next Career After Fauj',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // Every route (not just the first one Flutter resolves at launch)
        // goes through onGenerateRoute, which enforces the phone-verification
        // gate on every navigation — including a browser loading a URL that
        // already names a specific route directly (a bookmark, browser-
        // suggested history entry, or anything else that isn't a plain,
        // route-less visit to the site). Relying on `initialRoute` alone
        // would only gate that one specific case.
        onGenerateRoute: (settings) {
          final hasSession =
              profileRepository.sessionToken != null || _skipAuthForTesting;
          final isPublicRoute = settings.name == AppRoutes.phoneVerification ||
              settings.name == AppRoutes.admin;
          if (!hasSession && !isPublicRoute) {
            return MaterialPageRoute(
              settings: const RouteSettings(name: AppRoutes.phoneVerification),
              builder: (_) => PhoneVerificationScreen(),
            );
          }

          // '/' is ambiguous on its own — it's both AppRoutes.onboarding and
          // what Flutter resolves a plain, route-less visit to — so it needs
          // the same "already has a profile -> skip straight to Profile"
          // check the old initialRoute logic did, before the builder-map
          // lookup below (which would otherwise always match onboarding).
          if (settings.name == '/' || settings.name == null) {
            return MaterialPageRoute(
              builder: (_) => profileRepository.profile != null
                  ? MainShell(syncProgress: syncProgress)
                  : const OnboardingScreen(),
            );
          }

          final builder = _routeBuilders[settings.name];
          if (builder != null) {
            return MaterialPageRoute(settings: settings, builder: builder);
          }

          // Truly unrecognized route name — send them wherever they belong
          // given their current session/profile state, same as above.
          return MaterialPageRoute(
            builder: (_) => profileRepository.profile != null
                ? MainShell(syncProgress: syncProgress)
                : const OnboardingScreen(),
          );
        },
      ),
    );
  }

  Map<String, WidgetBuilder> get _routeBuilders => {
    AppRoutes.phoneVerification: (_) => PhoneVerificationScreen(),
    AppRoutes.onboarding: (_) => const OnboardingScreen(),
    AppRoutes.startHere: (_) => const StartHereScreen(),
    AppRoutes.profile: (_) => MainShell(syncProgress: syncProgress),
    AppRoutes.aiAssistant: (_) =>
        AiAssistantScreen(sendMessage: httpSendAssistantMessage),
    AppRoutes.careerReadiness: (_) => const CareerReadinessScreen(),
    AppRoutes.jdMatch: (_) => const JdMatchScreen(
        analyzeFitment: httpAnalyzeFitment, generateSampleJd: httpGenerateSampleJd),
    AppRoutes.verticalFit: (_) => const VerticalFitQuizScreen(),
    AppRoutes.careerPaths: (_) => const CareerPathsScreen(),
    AppRoutes.refinedCv: (_) => const RefinedCvEntryScreen(),
    AppRoutes.gapRoadmap: (_) => const GapRoadmapEntryScreen(),
    AppRoutes.jobMatches: (_) =>
        const JobMatchesScreen(analyzeJobMatches: httpAnalyzeJobMatches),
    AppRoutes.linkedinWriteup: (_) => const LinkedInWriteupScreen(
        generateWriteup: httpGenerateLinkedInWriteup),
    AppRoutes.aiReadiness: (_) =>
        const AiReadinessQuizScreen(analyzeAiReadiness: httpAnalyzeAiReadiness),
    AppRoutes.interviewPrep: (_) => const InterviewPrepScreen(
          generateJdQuestions: httpGenerateJdInterviewQuestions,
          analyzeMockAnswer: httpAnalyzeInterviewAnswer,
        ),
    AppRoutes.ninetyDayRoadmap: (_) => const NinetyDayRoadmapScreen(),
    AppRoutes.compensation: (_) => const CompensationScreen(
        estimateCompensation: httpEstimateCompensation),
    AppRoutes.transitionPlan: (_) => const TransitionPlanScreen(),
    AppRoutes.applicationTracker: (_) => const ApplicationTrackerScreen(),
    AppRoutes.cvCivilianizer: (_) =>
        const CivilianizerScreen(civilianizeCv: httpCivilianizeCv),
    AppRoutes.cvBuilder: (_) => const CvBuilderScreen(
        buildCv: httpBuildCv, fetchApprovedEquivalencies: httpFetchApprovedEquivalencies),
    AppRoutes.cvWritingGuide: (_) => const CvWritingGuideScreen(),
    AppRoutes.cvExamples: (_) => const CvExamplesScreen(),
    AppRoutes.careerHandbook: (_) => const CareerHandbookScreen(),
    AppRoutes.corpsMatrix: (_) => const CorpsMatrixScreen(),
    AppRoutes.corporateLanguageGuide: (_) =>
        const CorporateLanguageGuideScreen(),
    AppRoutes.readingProgramme: (_) => const ReadingProgrammeScreen(),
    AppRoutes.corporateCultureGuide: (_) => const CorporateCultureScreen(),
    AppRoutes.businessEtiquetteGuide: (_) => const BusinessEtiquetteScreen(),
    AppRoutes.learningResources: (_) => const LearningResourcesScreen(),
    AppRoutes.networkDirectory: (_) => const NetworkDirectoryScreen(),
    AppRoutes.financialPlanner: (_) => const FinancialPlannerScreen(),
    AppRoutes.targetRoleStrategy: (_) => const TargetRoleStrategyScreen(
        generateStrategy: httpGenerateTargetRoleStrategy),
    AppRoutes.supportTicket: (_) => const SupportScreen(),
    AppRoutes.admin: (_) => const AdminLoginScreen(),
    if (_skipAuthForTesting) AppRoutes.debugMenu: (_) => const DebugMenuScreen(),
  };
}
