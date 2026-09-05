import 'authenticated_http.dart';
import 'profile_repository.dart';
import 'transition_readiness.dart';

/// Reports a compact, honest snapshot of how far the officer has got — for
/// the admin dashboard to see who's using the app and where people get
/// stuck. Never sends raw CV/score content, only completion flags and the
/// readiness score itself. Best-effort: a failed sync never surfaces to the
/// officer, since this is purely for the admin's visibility, not something
/// the officer's own experience depends on.
Future<void> syncOfficerProgress(ProfileRepository repo) async {
  if (repo.sessionToken == null) return;

  final profile = repo.profile;
  final readiness = TransitionReadinessSummary.fromRepository(repo);

  try {
    await authenticatedPost(repo, '/officer-progress', {
      'rank': profile?.rank,
      'fullName': profile?.fullName,
      'service': profile?.service.name,
      'segment': profile?.segment.name,
      'readinessScore': readiness.overallScore,
      'readinessDimensionsCompleted': readiness.completedCount,
      'readinessDimensionsTotal': readiness.totalCount,
      'cvUploaded': profile?.cvExtractedText != null,
      'civilianizedCvDone': repo.lastCivilianizedCv != null,
      'builtCvDone': repo.lastBuiltCv != null,
      'jdMatchDone': repo.lastFitmentResult != null,
      'financialPlanDone': repo.lastFinancialPlanInput != null,
      'targetRoleStrategyDone': repo.lastTargetRoleStrategy != null,
      'applicationsCount': repo.applications.length,
    });
  } catch (_) {
    // Best-effort — never blocks or surfaces to the officer.
  }
}
