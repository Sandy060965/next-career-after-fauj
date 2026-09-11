import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/officer_profile.dart';
import '../../core/routing/app_routes.dart';
import '../../core/services/profile_repository.dart';
import '../../core/widgets/home_button.dart';
import '../cv_builder/built_cv.dart';
import '../cv_builder/cv_builder_intake.dart';
import '../fitment/fitment_result.dart';
import '../fitment/score_gap_screen.dart';
import '../vertical_fit/aptitude_question.dart';
import '../vertical_fit/cv_evidence_http_service.dart';
import '../vertical_fit/vertical_fit.dart';
import '../vertical_fit/vertical_fit_result_screen.dart';

/// Dev-only shortcut menu — reachable at #/debug, but only registered as a
/// route when the app is launched with --dart-define=SKIP_AUTH_FOR_TESTING
/// (see main.dart). Skips the "onboard, then click through to the screen
/// you actually need to look at" loop that testing every other screen in
/// this app otherwise requires: jump straight to any named route, or seed
/// realistic sample data and land directly on a result screen that would
/// otherwise need a full quiz/CV-build/JD-match pass to populate.
class DebugMenuScreen extends StatelessWidget {
  const DebugMenuScreen({super.key});

  static const _routes = <String, String>{
    'Start Here': AppRoutes.startHere,
    'Profile / Home': AppRoutes.profile,
    'Career Readiness': AppRoutes.careerReadiness,
    'JD Match': AppRoutes.jdMatch,
    'Vertical Fit (quiz)': AppRoutes.verticalFit,
    'Career Paths': AppRoutes.careerPaths,
    'Refined CV (entry)': AppRoutes.refinedCv,
    'Gap Roadmap (entry)': AppRoutes.gapRoadmap,
    'Job Matches': AppRoutes.jobMatches,
    'LinkedIn Writeup': AppRoutes.linkedinWriteup,
    'AI Readiness': AppRoutes.aiReadiness,
    'Interview Prep': AppRoutes.interviewPrep,
    '90-Day Roadmap': AppRoutes.ninetyDayRoadmap,
    'Compensation': AppRoutes.compensation,
    'Transition Plan': AppRoutes.transitionPlan,
    'Application Tracker': AppRoutes.applicationTracker,
    'CV Civilianizer': AppRoutes.cvCivilianizer,
    'Network Directory': AppRoutes.networkDirectory,
    'Financial Planner': AppRoutes.financialPlanner,
    'Target Role Strategy': AppRoutes.targetRoleStrategy,
    'CV Builder': AppRoutes.cvBuilder,
    'CV Writing Guide': AppRoutes.cvWritingGuide,
    'Career Handbook': AppRoutes.careerHandbook,
    'Corps/Vertical Matrix': AppRoutes.corpsMatrix,
    'Corporate Language Guide': AppRoutes.corporateLanguageGuide,
    'Reading Programme': AppRoutes.readingProgramme,
    'AI Assistant': AppRoutes.aiAssistant,
    'Support Ticket': AppRoutes.supportTicket,
  };

  OfficerProfile _ensureProfile(ProfileRepository repo) {
    final existing = repo.profile;
    if (existing != null) return existing;
    final seeded = OfficerProfile(
      rank: 'Colonel',
      fullName: 'A K Sharma',
      dateOfBirth: DateTime(1978, 5, 10),
      workExperienceYears: 26,
      workExperienceMonths: 0,
      releaseStatus: ReleaseStatus.tentative,
      releaseDate: DateTime.now().add(const Duration(days: 365)),
      service: OfficerService.army,
      mobileNumber: '9876543210',
      email: 'a.sharma@example.com',
      segment: OfficerSegment.pmr,
      cvFileName: 'resume.docx',
      cvExtractedText: 'COLONEL A K SHARMA\n\nWORK EXPERIENCE\n'
          'Commanding Officer, Infantry Battalion (2019-2022)\n'
          '- Commanded a 900-personnel infantry battalion.',
    );
    repo.saveProfile(seeded);
    return seeded;
  }

  FitmentResult _sampleFitmentResult() => const FitmentResult(
        fitmentScore: 7,
        scoreRationale: 'Solid overall match with one certification gap.',
        requirementBreakdown: [
          RequirementBreakdownItem(
            requirement: 'PMP certification',
            status: RequirementStatus.gap,
            notes: 'No formal certification listed on the CV.',
          ),
          RequirementBreakdownItem(
            requirement: 'Team leadership experience',
            status: RequirementStatus.met,
            notes: 'Over a decade leading teams of 30+.',
          ),
        ],
        originalCvExcerpt: 'Led logistics operations for a large unit.',
        refinedCv: 'Supply Chain & Operations Leader with proven logistics track record.',
        dimensionGaps: [
          DimensionAssessment(
            dimension: GapDimension.experience,
            status: RequirementStatus.met,
            notes: 'Over a decade of relevant leadership experience.',
          ),
          DimensionAssessment(
            dimension: GapDimension.education,
            status: RequirementStatus.met,
            notes: "Bachelor's degree listed.",
          ),
          DimensionAssessment(
            dimension: GapDimension.skills,
            status: RequirementStatus.partiallyMet,
            notes: 'No named ERP platform mentioned.',
          ),
          DimensionAssessment(
            dimension: GapDimension.certifications,
            status: RequirementStatus.gap,
            notes: 'No formal certification listed on the CV.',
          ),
        ],
        gapRoadmap: [
          GapRoadmapItem(
            title: 'PMP',
            dimension: GapDimension.certifications,
            closesGap: 'PMP certification',
            timeToAcquire: '3-4 months',
            priority: 2,
          ),
          GapRoadmapItem(
            title: 'Six Sigma Green Belt',
            dimension: GapDimension.certifications,
            closesGap: 'Process-improvement credibility',
            timeToAcquire: '4-6 weeks',
            priority: 1,
          ),
        ],
      );

  Future<FitmentResult> _seedFitment(BuildContext context) async {
    final repo = context.read<ProfileRepository>();
    _ensureProfile(repo);
    final result = _sampleFitmentResult();
    await repo.saveFitmentResult(result, jdText: 'Sample job description for debug testing.');
    return result;
  }

  Future<VerticalFitAssessment> _seedVerticalFit(BuildContext context) async {
    final repo = context.read<ProfileRepository>();
    _ensureProfile(repo);
    final assessment = VerticalFitAssessment(ratings: {for (final q in kAptitudeQuestions) q.id: 3});
    await repo.saveVerticalFitAssessment(assessment);
    return assessment;
  }

  Future<void> _seedCvBuilderResult(BuildContext context) async {
    final repo = context.read<ProfileRepository>();
    _ensureProfile(repo);
    // Full enough (a summary, two roles, education, a certification, a
    // course, an award) that a CV template downloaded from this seed shows
    // every section it's designed to — not just a sparse, mostly-empty page.
    const intake = CvBuilderIntake(
      summary: 'Senior operations leader with over two decades of experience leading large, '
          'cross-functional teams under pressure. Strong track record in logistics, crisis '
          'management, and training delivery.',
      workExperience: [
        WorkExperienceEntry(
          roleTitle: 'Commanding Officer',
          organizationType: 'Infantry battalion, ~800 personnel',
          duration: 'Jul 2019 to Jun 2022',
          responsibilities: 'Led all operations, training, and welfare for the unit.\n'
              'Managed an annual budget across equipment and stores.\n'
              'Cut average logistics turnaround time by 30% through process redesign.',
        ),
        WorkExperienceEntry(
          roleTitle: 'Second-in-Command',
          organizationType: 'Infantry battalion, ~800 personnel',
          duration: 'Jul 2016 to Jun 2019',
          responsibilities: 'Deputised for the Commanding Officer across all functions.\n'
              'Led a 40-person training cell, raising qualification pass rates by 18%.',
        ),
      ],
      education: [
        EducationEntry(degree: 'M.Sc. Defence Studies', institution: 'Madras University', year: '2015'),
        EducationEntry(degree: 'B.Tech Electronics', institution: 'NIT Trichy', year: '2001'),
      ],
      certifications: [CertificationEntry(name: 'PMP', year: '2021')],
      courses: [CourseEntry(name: 'Higher Command Course', year: '2020')],
      honoursAwards: [AwardEntry(name: 'Sena Medal', year: '2018')],
      skills: 'Leadership, Logistics, Crisis Management, Team Building, Training Delivery, '
          'Stakeholder Management',
    );
    const built = BuiltCv(
      cvText: 'COL A K SHARMA\n\n'
          'PROFESSIONAL SUMMARY\n\n'
          'Senior operations leader with over two decades of experience leading large, '
          'cross-functional teams under pressure. Strong track record in logistics, crisis '
          'management, and training delivery.\n\n'
          'PROFESSIONAL EXPERIENCE\n\n'
          'Operations Director\n'
          'Organisation of ~800 personnel | Jul 2019 - Jun 2022\n'
          '- Led all operations, training, and welfare for the organisation.\n'
          '- Cut average logistics turnaround time by 30% through process redesign.\n\n'
          'Deputy Operations Director\n'
          'Organisation of ~800 personnel | Jul 2016 - Jun 2019\n'
          '- Deputised for the Operations Director across all functions.\n\n'
          'EDUCATION\n\n'
          'M.Sc. Defence Studies, Madras University (2015)\n'
          'B.Tech Electronics, NIT Trichy (2001)\n\n'
          'CERTIFICATIONS\n\nPMP (2021)\n\n'
          'SKILLS\n\nLeadership, Logistics, Crisis Management, Team Building, Training Delivery, '
          'Stakeholder Management',
    );
    await repo.saveCvBuilderIntake(intake);
    await repo.saveBuiltCv(built);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Menu (dev only)'),
        actions: const [HomeButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Dev-only screen — reachable only when launched with '
              '--dart-define=SKIP_AUTH_FOR_TESTING=true. Never shown to a real officer.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ),
          const SizedBox(height: 20),
          Text('Reset', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('debugClearAllButton'),
            onPressed: () async {
              await context.read<ProfileRepository>().clearAllForTesting();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.onboarding, (route) => false);
              }
            },
            icon: const Icon(Icons.restart_alt),
            label: const Text('Clear all local data & restart at onboarding'),
          ),
          const SizedBox(height: 24),
          Text('Seed sample data & open result', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Populates realistic data (without a profile, one is seeded too) and jumps straight '
            'to the result — skips quiz/CV-build/JD-match.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          _SeedTile(
            key: const Key('debugSeedFitmentScore'),
            label: 'Fitment Score screen',
            onTap: () async {
              final result = await _seedFitment(context);
              if (context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ScoreGapScreen(result: result)),
                );
              }
            },
          ),
          _SeedTile(
            key: const Key('debugSeedRefinedCv'),
            label: 'Refined CV screen',
            onTap: () async {
              await _seedFitment(context);
              if (context.mounted) Navigator.of(context).pushNamed(AppRoutes.refinedCv);
            },
          ),
          _SeedTile(
            key: const Key('debugSeedGapRoadmap'),
            label: 'Gap Roadmap screen',
            onTap: () async {
              await _seedFitment(context);
              if (context.mounted) Navigator.of(context).pushNamed(AppRoutes.gapRoadmap);
            },
          ),
          _SeedTile(
            key: const Key('debugSeedVerticalFitResult'),
            label: 'Vertical Fit Result screen',
            onTap: () async {
              final assessment = await _seedVerticalFit(context);
              if (context.mounted) {
                final profile = context.read<ProfileRepository>().profile;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VerticalFitResultScreen(
                      assessment: assessment,
                      corpsOrArm: profile?.corpsOrArm,
                      groundCvEvidence: httpGroundCvEvidence,
                    ),
                  ),
                );
              }
            },
          ),
          _SeedTile(
            key: const Key('debugSeedCvBuilderResult'),
            label: 'CV Builder, with a built result',
            onTap: () async {
              await _seedCvBuilderResult(context);
              if (context.mounted) Navigator.of(context).pushNamed(AppRoutes.cvBuilder);
            },
          ),
          const SizedBox(height: 24),
          Text('Jump to any screen', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final entry in _routes.entries)
            ListTile(
              key: ValueKey('debugRoute_${entry.value}'),
              dense: true,
              title: Text(entry.key),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed(entry.value),
            ),
        ],
      ),
    );
  }
}

class _SeedTile extends StatelessWidget {
  const _SeedTile({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
