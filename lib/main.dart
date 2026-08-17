import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_routes.dart';
import 'core/services/profile_repository.dart';
import 'core/theme/app_theme.dart';
import 'features/ai_readiness/ai_readiness_http_service.dart';
import 'features/ai_readiness/ai_readiness_quiz_screen.dart';
import 'features/career_paths/career_paths_screen.dart';
import 'features/compensation/compensation_http_service.dart';
import 'features/compensation/compensation_screen.dart';
import 'features/fitment/fitment_entry_screens.dart';
import 'features/fitment/fitment_http_service.dart';
import 'features/interview_prep/interview_prep_http_service.dart';
import 'features/interview_prep/interview_prep_screen.dart';
import 'features/interview_prep/mock_interview_http_service.dart';
import 'features/success_roadmap/ninety_day_roadmap_screen.dart';
import 'features/vertical_fit/vertical_fit_quiz_screen.dart';
import 'features/jd_match/jd_match_screen.dart';
import 'features/job_matches/job_matches_http_service.dart';
import 'features/job_matches/job_matches_screen.dart';
import 'features/linkedin_writeup/linkedin_writeup_http_service.dart';
import 'features/linkedin_writeup/linkedin_writeup_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';

void main() {
  runApp(const NextCareerAfterFaujApp());
}

class NextCareerAfterFaujApp extends StatelessWidget {
  const NextCareerAfterFaujApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileRepository(),
      child: MaterialApp(
        title: 'Next Career After Fauj',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.onboarding,
        routes: {
          AppRoutes.onboarding: (_) => const OnboardingScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
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
        },
      ),
    );
  }
}
