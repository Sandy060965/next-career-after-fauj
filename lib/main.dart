import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_routes.dart';
import 'core/services/auth_service.dart';
import 'core/services/profile_repository.dart';
import 'core/theme/app_theme.dart';
import 'features/ai_readiness/ai_readiness_http_service.dart';
import 'features/ai_readiness/ai_readiness_quiz_screen.dart';
import 'features/application_tracker/application_tracker_screen.dart';
import 'features/auth/phone_verification_screen.dart';
import 'features/career_paths/career_paths_screen.dart';
import 'features/career_readiness/career_readiness_screen.dart';
import 'features/compensation/compensation_http_service.dart';
import 'features/compensation/compensation_screen.dart';
import 'features/cv_builder/cv_builder_http_service.dart';
import 'features/cv_builder/cv_builder_screen.dart';
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
import 'features/job_matches/job_matches_http_service.dart';
import 'features/job_matches/job_matches_screen.dart';
import 'features/linkedin_writeup/linkedin_writeup_http_service.dart';
import 'features/linkedin_writeup/linkedin_writeup_screen.dart';
import 'features/networking/network_directory_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/skill_equivalency/skill_equivalency_screen.dart';
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
  final token = profileRepository.sessionToken;
  if (token != null) {
    unawaited(
      AuthService().fetchAccount(token).then((account) {
        if (account != null) profileRepository.updateAccount(account);
      }),
    );
  }

  runApp(NextCareerAfterFaujApp(profileRepository: profileRepository));
}

class NextCareerAfterFaujApp extends StatelessWidget {
  const NextCareerAfterFaujApp({super.key, required this.profileRepository});

  final ProfileRepository profileRepository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: profileRepository,
      child: MaterialApp(
        title: 'Next Career After Fauj',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // Phone verification gates everything else: no session -> verify
        // first. With a session, skip straight to Profile if onboarding was
        // already completed in a previous session — both the session and
        // the profile survive app restarts.
        initialRoute: (profileRepository.sessionToken == null && !_skipAuthForTesting)
            ? AppRoutes.phoneVerification
            : profileRepository.profile != null
                ? AppRoutes.profile
                : AppRoutes.onboarding,
        routes: {
          AppRoutes.phoneVerification: (_) => PhoneVerificationScreen(),
          AppRoutes.onboarding: (_) => const OnboardingScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
          AppRoutes.careerReadiness: (_) => const CareerReadinessScreen(),
          AppRoutes.jdMatch: (_) => const JdMatchScreen(analyzeFitment: httpAnalyzeFitment),
          AppRoutes.verticalFit: (_) => const VerticalFitQuizScreen(),
          AppRoutes.careerPaths: (_) => const CareerPathsScreen(),
          AppRoutes.refinedCv: (_) => const RefinedCvEntryScreen(),
          AppRoutes.gapRoadmap: (_) => const GapRoadmapEntryScreen(),
          AppRoutes.jobMatches: (_) =>
              const JobMatchesScreen(analyzeJobMatches: httpAnalyzeJobMatches),
          AppRoutes.linkedinWriteup: (_) =>
              const LinkedInWriteupScreen(generateWriteup: httpGenerateLinkedInWriteup),
          AppRoutes.aiReadiness: (_) =>
              const AiReadinessQuizScreen(analyzeAiReadiness: httpAnalyzeAiReadiness),
          AppRoutes.interviewPrep: (_) => const InterviewPrepScreen(
                generateJdQuestions: httpGenerateJdInterviewQuestions,
                analyzeMockAnswer: httpAnalyzeInterviewAnswer,
              ),
          AppRoutes.ninetyDayRoadmap: (_) => const NinetyDayRoadmapScreen(),
          AppRoutes.compensation: (_) =>
              const CompensationScreen(estimateCompensation: httpEstimateCompensation),
          AppRoutes.transitionPlan: (_) => const TransitionPlanScreen(),
          AppRoutes.applicationTracker: (_) => const ApplicationTrackerScreen(),
          AppRoutes.skillEquivalency: (_) => const SkillEquivalencyScreen(),
          AppRoutes.cvCivilianizer: (_) =>
              const CivilianizerScreen(civilianizeCv: httpCivilianizeCv),
          AppRoutes.cvBuilder: (_) => const CvBuilderScreen(buildCv: httpBuildCv),
          AppRoutes.networkDirectory: (_) => const NetworkDirectoryScreen(),
          AppRoutes.financialPlanner: (_) => const FinancialPlannerScreen(),
          AppRoutes.targetRoleStrategy: (_) =>
              const TargetRoleStrategyScreen(generateStrategy: httpGenerateTargetRoleStrategy),
        },
      ),
    );
  }
}
