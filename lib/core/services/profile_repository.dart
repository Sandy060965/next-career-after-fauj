import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/ai_readiness/ai_readiness.dart';
import '../../features/cv_builder/built_cv.dart';
import '../../features/cv_builder/cv_builder_intake.dart';
import '../../features/cv_civilianizer/civilianized_cv.dart';
import '../../features/financial_planner/financial_plan.dart';
import '../../features/fitment/fitment_result.dart';
import '../../features/target_role/target_role_strategy.dart';
import '../../features/vertical_fit/cv_evidence.dart';
import '../../features/vertical_fit/vertical_fit.dart';
import '../models/job_application.dart';
import '../models/officer_account.dart';
import '../models/officer_profile.dart';
import 'session_storage.dart';

/// A one-time snapshot of what the backend already knows about this officer
/// (see officer_progress_sync.dart, which is what wrote it) — fetched right
/// after a sign-in on a device with no local profile yet, e.g. a reinstall
/// or a new device. Only the four fields officer_progress tracks; the rest
/// of onboarding (DOB, release date, corps/arm, CV) still isn't known
/// server-side and must be re-entered regardless. See
/// officer_progress_prefill.dart for how this gets fetched.
class OfficerProgressPrefill {
  const OfficerProgressPrefill({this.rank, this.fullName, this.service, this.segment});

  final String? rank;
  final String? fullName;
  final String? service;
  final String? segment;

  factory OfficerProgressPrefill.fromJson(Map<String, dynamic> json) => OfficerProgressPrefill(
        rank: json['rank'] as String?,
        fullName: json['fullName'] as String?,
        service: json['service'] as String?,
        segment: json['segment'] as String?,
      );
}

const _profileKey = 'officer_profile_v1';
const _fitmentResultKey = 'last_fitment_result_v1';
const _jdTextKey = 'last_jd_text_v1';
const _verticalFitKey = 'last_vertical_fit_v1';
const _aiReadinessKey = 'last_ai_readiness_v1';
const _accountKey = 'officer_account_v1';
const _applicationsKey = 'job_applications_v1';
const _civilianizedCvKey = 'last_civilianized_cv_v1';
const _financialPlanKey = 'last_financial_plan_input_v1';
const _targetRoleStrategyKey = 'last_target_role_strategy_v1';
const _cvEvidenceKey = 'last_cv_evidence_v1';
const _cvBuilderIntakeKey = 'last_cv_builder_intake_v1';
const _builtCvKey = 'last_built_cv_v1';
const _civilianizedCvSavedAtKey = 'last_civilianized_cv_saved_at_v1';
const _builtCvSavedAtKey = 'last_built_cv_saved_at_v1';
const _cvFileName = 'officer_cv';
const _jdFileName = 'last_jd';
const _photoFileName = 'officer_photo';
const _hasSeenGuidedIntroKey = 'has_seen_guided_intro_v1';
const _hasVisitedSkillEquivalencyKey = 'has_visited_skill_equivalency_v1';

/// Holder for the officer's profile and cross-screen state, shared via
/// Provider. Persists to disk (SharedPreferences for structured data, a
/// file for the CV's raw bytes) so nothing is lost when the app restarts —
/// persistence is always best-effort: a write/read failure falls back to
/// in-memory-only behaviour rather than crashing the app.
class ProfileRepository extends ChangeNotifier {
  ProfileRepository({SessionStorage? sessionStorage})
      : _sessionStorage = sessionStorage ?? SessionStorage();

  final SessionStorage _sessionStorage;

  OfficerProfile? _profile;
  FitmentResult? _lastFitmentResult;
  String? _lastJdText;
  Uint8List? _lastJdPdfBytes;
  VerticalFitAssessment? _lastVerticalFitAssessment;
  AiReadinessResult? _lastAiReadinessResult;
  String? _sessionToken;
  String? _refreshToken;
  OfficerAccount? _account;
  List<JobApplication> _applications = [];
  CivilianizedCv? _lastCivilianizedCv;
  FinancialPlanInput? _lastFinancialPlanInput;
  TargetRoleStrategyResult? _lastTargetRoleStrategy;
  CvEvidenceResult? _lastCvEvidenceResult;
  CvBuilderIntake? _lastCvBuilderIntake;
  BuiltCv? _lastBuiltCv;
  DateTime? _civilianizedCvSavedAt;
  DateTime? _builtCvSavedAt;
  bool _hasSeenGuidedIntro = false;
  bool _hasVisitedSkillEquivalency = false;
  OfficerProgressPrefill? _progressPrefill;

  OfficerProfile? get profile => _profile;

  /// In-memory only (never persisted) — set right after a sign-in that
  /// found no local profile, consumed once by OnboardingScreen to prefill
  /// its form instead of starting blank. See officer_progress_prefill.dart.
  OfficerProgressPrefill? get progressPrefill => _progressPrefill;

  /// Reads and clears in one step, without notifying — OnboardingScreen
  /// calls this from initState, and notifyListeners() during another
  /// widget's build phase throws ("setState() or markNeedsBuild() called
  /// during build"). Nothing else observes this field, so a silent clear
  /// is safe.
  OfficerProgressPrefill? takeProgressPrefill() {
    final prefill = _progressPrefill;
    _progressPrefill = null;
    return prefill;
  }

  void setProgressPrefill(OfficerProgressPrefill? prefill) {
    _progressPrefill = prefill;
    notifyListeners();
  }

  /// Whether this officer has already been shown (or skipped) the one-time
  /// "Start Here" guided sequence right after onboarding — once true, a
  /// fresh onboarding submit (e.g. via Profile > Edit) goes straight back
  /// into the app instead of showing the guided intro again.
  bool get hasSeenGuidedIntro => _hasSeenGuidedIntro;

  /// Whether the officer has opened Skill Equivalency at least once — used
  /// as its "done" signal on the Start Here screen, since it's a lookup
  /// tool with no quiz score to key off.
  bool get hasVisitedSkillEquivalency => _hasVisitedSkillEquivalency;

  /// Non-null once the officer has verified their phone number — gates
  /// access to onboarding (see main.dart's initialRoute logic). Distinct
  /// from [profile], which is the officer's own career data collected
  /// during onboarding.
  String? get sessionToken => _sessionToken;

  /// Long-lived, single-use-then-rotated — presented to /auth/refresh to
  /// silently mint a new short-lived [sessionToken] without the officer
  /// re-verifying by phone OTP. See [saveSession].
  String? get refreshToken => _refreshToken;

  OfficerAccount? get account => _account;

  /// The most recent JD-match result, cached so Refined CV and Gap Roadmap
  /// can be reached directly from the Profile screen instead of only via
  /// the JD Match flow.
  FitmentResult? get lastFitmentResult => _lastFitmentResult;
  String? get lastJdText => _lastJdText;

  /// Raw bytes of the last JD uploaded as a PDF, if that's how it was
  /// supplied — mutually exclusive with [lastJdText] the same way a CV's
  /// [OfficerProfile.cvPdfBytes] is mutually exclusive with
  /// [OfficerProfile.cvExtractedText].
  Uint8List? get lastJdPdfBytes => _lastJdPdfBytes;

  VerticalFitAssessment? get lastVerticalFitAssessment => _lastVerticalFitAssessment;

  AiReadinessResult? get lastAiReadinessResult => _lastAiReadinessResult;

  /// The officer's own application pipeline — newest first.
  List<JobApplication> get applications => List.unmodifiable(_applications);

  CivilianizedCv? get lastCivilianizedCv => _lastCivilianizedCv;

  FinancialPlanInput? get lastFinancialPlanInput => _lastFinancialPlanInput;

  TargetRoleStrategyResult? get lastTargetRoleStrategy => _lastTargetRoleStrategy;

  CvEvidenceResult? get lastCvEvidenceResult => _lastCvEvidenceResult;

  CvBuilderIntake? get lastCvBuilderIntake => _lastCvBuilderIntake;

  BuiltCv? get lastBuiltCv => _lastBuiltCv;

  /// The officer's most recently completed civilian-ready CV text —
  /// whichever of "Base CV, Civilianized" or "Build My Civilian CV" was
  /// completed more recently — for JD Match to analyse instead of the raw
  /// military-language CV from onboarding. Null if neither has been done
  /// yet, in which case callers should fall back to the raw CV.
  String? get preferredCivilianCvText {
    final civilianized = _lastCivilianizedCv;
    final built = _lastBuiltCv;
    if (civilianized == null && built == null) return null;
    if (civilianized == null) return built!.cvText;
    if (built == null) return civilianized.civilianizedCv;
    final civilianizedAt = _civilianizedCvSavedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final builtAt = _builtCvSavedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return builtAt.isAfter(civilianizedAt) ? built.cvText : civilianized.civilianizedCv;
  }

  /// Loads previously persisted state from disk. Call once, before
  /// runApp, so the UI never flashes an empty state that then repopulates.
  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final profileJson = prefs.getString(_profileKey);
      if (profileJson != null) {
        final cvBytes = await _readCvFile();
        final photoBytes = await _readPhotoFile();
        _profile = OfficerProfile.fromJson(
          jsonDecode(profileJson) as Map<String, dynamic>,
          cvPdfBytes: cvBytes,
          photoBytes: photoBytes,
        );
      }

      final fitmentJson = prefs.getString(_fitmentResultKey);
      if (fitmentJson != null) {
        _lastFitmentResult = FitmentResult.fromJson(jsonDecode(fitmentJson) as Map<String, dynamic>);
      }
      _lastJdText = prefs.getString(_jdTextKey);
      _lastJdPdfBytes = await _readJdFile();

      final verticalFitJson = prefs.getString(_verticalFitKey);
      if (verticalFitJson != null) {
        _lastVerticalFitAssessment =
            VerticalFitAssessment.fromJson(jsonDecode(verticalFitJson) as Map<String, dynamic>);
      }

      final aiReadinessJson = prefs.getString(_aiReadinessKey);
      if (aiReadinessJson != null) {
        _lastAiReadinessResult =
            AiReadinessResult.fromJson(jsonDecode(aiReadinessJson) as Map<String, dynamic>);
      }

      final accountJson = prefs.getString(_accountKey);
      if (accountJson != null) {
        _account = OfficerAccount.fromJson(jsonDecode(accountJson) as Map<String, dynamic>);
      }

      final applicationsJson = prefs.getString(_applicationsKey);
      if (applicationsJson != null) {
        _applications = (jsonDecode(applicationsJson) as List)
            .map((e) => JobApplication.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final civilianizedCvJson = prefs.getString(_civilianizedCvKey);
      if (civilianizedCvJson != null) {
        _lastCivilianizedCv =
            CivilianizedCv.fromJson(jsonDecode(civilianizedCvJson) as Map<String, dynamic>);
        _civilianizedCvSavedAt = DateTime.tryParse(prefs.getString(_civilianizedCvSavedAtKey) ?? '');
      }

      final financialPlanJson = prefs.getString(_financialPlanKey);
      if (financialPlanJson != null) {
        _lastFinancialPlanInput =
            FinancialPlanInput.fromJson(jsonDecode(financialPlanJson) as Map<String, dynamic>);
      }

      final targetRoleJson = prefs.getString(_targetRoleStrategyKey);
      if (targetRoleJson != null) {
        _lastTargetRoleStrategy =
            TargetRoleStrategyResult.fromJson(jsonDecode(targetRoleJson) as Map<String, dynamic>);
      }

      final cvEvidenceJson = prefs.getString(_cvEvidenceKey);
      if (cvEvidenceJson != null) {
        _lastCvEvidenceResult =
            CvEvidenceResult.fromJson(jsonDecode(cvEvidenceJson) as Map<String, dynamic>);
      }

      final cvBuilderIntakeJson = prefs.getString(_cvBuilderIntakeKey);
      if (cvBuilderIntakeJson != null) {
        _lastCvBuilderIntake =
            CvBuilderIntake.fromJson(jsonDecode(cvBuilderIntakeJson) as Map<String, dynamic>);
      }

      final builtCvJson = prefs.getString(_builtCvKey);
      if (builtCvJson != null) {
        _lastBuiltCv = BuiltCv.fromJson(jsonDecode(builtCvJson) as Map<String, dynamic>);
        _builtCvSavedAt = DateTime.tryParse(prefs.getString(_builtCvSavedAtKey) ?? '');
      }

      _hasSeenGuidedIntro = prefs.getBool(_hasSeenGuidedIntroKey) ?? false;
      _hasVisitedSkillEquivalency = prefs.getBool(_hasVisitedSkillEquivalencyKey) ?? false;
    } catch (e) {
      // Corrupt or unavailable storage — start fresh rather than crash.
      debugPrint('ProfileRepository.loadFromStorage failed: $e');
    }

    // The session tokens live in secure storage, not SharedPreferences —
    // read separately so a failure here doesn't take the rest of the cached
    // state down with it.
    _sessionToken = await _sessionStorage.readToken();
    _refreshToken = await _sessionStorage.readRefreshToken();
  }

  Future<void> saveProfile(OfficerProfile profile) async {
    _profile = profile;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
      if (profile.cvPdfBytes != null) {
        await _writeCvFile(profile.cvPdfBytes!);
      }
    } catch (e) {
      // Persistence is best-effort — in-memory state above already
      // updated, so the app keeps working even if the disk write fails.
      debugPrint('ProfileRepository.saveProfile persistence failed: $e');
    }
  }

  /// Adds, replaces, or (both args null) removes the officer's optional
  /// CV-template photo — offered only from the CV templates gallery, never
  /// part of onboarding itself. A no-op if there's no profile yet.
  Future<void> updatePhoto({String? photoFileName, Uint8List? photoBytes}) async {
    final current = _profile;
    if (current == null) return;
    final updated = current.withUpdatedPhoto(photoFileName: photoFileName, photoBytes: photoBytes);
    _profile = updated;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(updated.toJson()));
      if (photoBytes != null) {
        await _writePhotoFile(photoBytes);
      } else {
        await _deletePhotoFile();
      }
    } catch (e) {
      debugPrint('ProfileRepository.updatePhoto persistence failed: $e');
    }
  }

  Future<void> saveFitmentResult(FitmentResult result, {String? jdText, Uint8List? jdPdfBytes}) async {
    _lastFitmentResult = result;
    _lastJdText = jdText;
    _lastJdPdfBytes = jdPdfBytes;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fitmentResultKey, jsonEncode(result.toJson()));
      if (jdText != null) {
        await prefs.setString(_jdTextKey, jdText);
      } else {
        await prefs.remove(_jdTextKey);
      }
      // Only ever written, never explicitly deleted — same tolerance the
      // CV file already has (saveProfile never deletes a stale CV file
      // either). A fire-and-forget caller (several exist, including in
      // tests) must never be blocked on a file-delete's timeout.
      if (jdPdfBytes != null) {
        await _writeJdFile(jdPdfBytes);
      }
    } catch (e) {
      debugPrint('ProfileRepository.saveFitmentResult persistence failed: $e');
    }
  }

  Future<void> saveVerticalFitAssessment(VerticalFitAssessment assessment) async {
    _lastVerticalFitAssessment = assessment;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_verticalFitKey, jsonEncode(assessment.toJson()));
    } catch (e) {
      debugPrint('ProfileRepository.saveVerticalFitAssessment persistence failed: $e');
    }
  }

  Future<void> saveAiReadinessResult(AiReadinessResult result) async {
    _lastAiReadinessResult = result;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_aiReadinessKey, jsonEncode(result.toJson()));
    } catch (e) {
      debugPrint('ProfileRepository.saveAiReadinessResult persistence failed: $e');
    }
  }

  /// Called right after phone-OTP verification succeeds, and again on every
  /// silent token refresh (see `authenticated_http.dart`) — [refreshToken]
  /// is rotated on each use, so the caller always passes the latest one.
  Future<void> saveSession(String token, OfficerAccount account, {required String refreshToken}) async {
    _sessionToken = token;
    _refreshToken = refreshToken;
    _account = account;
    notifyListeners();
    await _sessionStorage.saveToken(token);
    await _sessionStorage.saveRefreshToken(refreshToken);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accountKey, jsonEncode(account.toJson()));
    } catch (e) {
      debugPrint('ProfileRepository.saveSession persistence failed: $e');
    }
  }

  /// Refreshes the cached entitlement from the backend — e.g. after a
  /// payment, or just to pick up a manually-granted test entitlement.
  Future<void> updateAccount(OfficerAccount account) async {
    _account = account;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accountKey, jsonEncode(account.toJson()));
    } catch (e) {
      debugPrint('ProfileRepository.updateAccount persistence failed: $e');
    }
  }

  Future<void> clearSession() async {
    _sessionToken = null;
    _refreshToken = null;
    _account = null;
    notifyListeners();
    await _sessionStorage.clearToken();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accountKey);
    } catch (e) {
      debugPrint('ProfileRepository.clearSession persistence failed: $e');
    }
  }

  /// Dev-only: wipes every cached field and all persisted local storage —
  /// a one-tap way back to a clean, unregistered state for testing, instead
  /// of manually clearing browser storage. Only ever called from the debug
  /// menu (debug_menu_screen.dart), itself only reachable when the app is
  /// launched with --dart-define=SKIP_AUTH_FOR_TESTING.
  Future<void> clearAllForTesting() async {
    _profile = null;
    _lastFitmentResult = null;
    _lastJdText = null;
    _lastJdPdfBytes = null;
    _lastVerticalFitAssessment = null;
    _lastAiReadinessResult = null;
    _sessionToken = null;
    _refreshToken = null;
    _account = null;
    _applications = [];
    _lastCivilianizedCv = null;
    _lastFinancialPlanInput = null;
    _lastTargetRoleStrategy = null;
    _lastCvEvidenceResult = null;
    _lastCvBuilderIntake = null;
    _lastBuiltCv = null;
    _civilianizedCvSavedAt = null;
    _builtCvSavedAt = null;
    _hasSeenGuidedIntro = false;
    _hasVisitedSkillEquivalency = false;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _sessionStorage.clearToken();
    } catch (e) {
      debugPrint('ProfileRepository.clearAllForTesting persistence failed: $e');
    }
  }

  Future<void> saveCivilianizedCv(CivilianizedCv result) async {
    _lastCivilianizedCv = result;
    _civilianizedCvSavedAt = DateTime.now();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_civilianizedCvKey, jsonEncode(result.toJson()));
      await prefs.setString(_civilianizedCvSavedAtKey, _civilianizedCvSavedAt!.toIso8601String());
    } catch (e) {
      debugPrint('ProfileRepository.saveCivilianizedCv persistence failed: $e');
    }
  }

  Future<void> saveFinancialPlanInput(FinancialPlanInput input) async {
    _lastFinancialPlanInput = input;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_financialPlanKey, jsonEncode(input.toJson()));
    } catch (e) {
      debugPrint('ProfileRepository.saveFinancialPlanInput persistence failed: $e');
    }
  }

  Future<void> saveTargetRoleStrategy(TargetRoleStrategyResult result) async {
    _lastTargetRoleStrategy = result;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_targetRoleStrategyKey, jsonEncode(result.toJson()));
    } catch (e) {
      debugPrint('ProfileRepository.saveTargetRoleStrategy persistence failed: $e');
    }
  }

  Future<void> saveCvEvidenceResult(CvEvidenceResult result) async {
    _lastCvEvidenceResult = result;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cvEvidenceKey, jsonEncode(result.toJson()));
    } catch (e) {
      debugPrint('ProfileRepository.saveCvEvidenceResult persistence failed: $e');
    }
  }

  Future<void> saveCvBuilderIntake(CvBuilderIntake intake) async {
    _lastCvBuilderIntake = intake;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cvBuilderIntakeKey, jsonEncode(intake.toJson()));
    } catch (e) {
      debugPrint('ProfileRepository.saveCvBuilderIntake persistence failed: $e');
    }
  }

  Future<void> saveBuiltCv(BuiltCv result) async {
    _lastBuiltCv = result;
    _builtCvSavedAt = DateTime.now();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_builtCvKey, jsonEncode(result.toJson()));
      await prefs.setString(_builtCvSavedAtKey, _builtCvSavedAt!.toIso8601String());
    } catch (e) {
      debugPrint('ProfileRepository.saveBuiltCv persistence failed: $e');
    }
  }

  Future<void> markGuidedIntroSeen() async {
    if (_hasSeenGuidedIntro) return;
    _hasSeenGuidedIntro = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenGuidedIntroKey, true);
    } catch (e) {
      debugPrint('ProfileRepository.markGuidedIntroSeen persistence failed: $e');
    }
  }

  Future<void> markSkillEquivalencyVisited() async {
    if (_hasVisitedSkillEquivalency) return;
    _hasVisitedSkillEquivalency = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasVisitedSkillEquivalencyKey, true);
    } catch (e) {
      debugPrint('ProfileRepository.markSkillEquivalencyVisited persistence failed: $e');
    }
  }

  Future<void> _persistApplications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _applicationsKey,
        jsonEncode(_applications.map((a) => a.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('ProfileRepository._persistApplications failed: $e');
    }
  }

  Future<void> addApplication(JobApplication application) async {
    _applications = [application, ..._applications];
    notifyListeners();
    await _persistApplications();
  }

  Future<void> updateApplication(JobApplication application) async {
    _applications = [
      for (final a in _applications) a.id == application.id ? application : a,
    ];
    notifyListeners();
    await _persistApplications();
  }

  Future<void> deleteApplication(String id) async {
    _applications = _applications.where((a) => a.id != id).toList();
    notifyListeners();
    await _persistApplications();
  }

  // File I/O gets a hard timeout: on a real device this should always be
  // near-instant, but persistence is best-effort and must never leave the
  // UI stuck waiting on a disk operation.
  static const _ioTimeout = Duration(seconds: 5);

  Future<File> _cvFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cvFileName');
  }

  Future<Uint8List?> _readCvFile() async {
    try {
      final file = await _cvFile();
      if (!await file.exists().timeout(_ioTimeout)) return null;
      return await file.readAsBytes().timeout(_ioTimeout);
    } catch (e) {
      debugPrint('ProfileRepository._readCvFile failed: $e');
      return null;
    }
  }

  Future<void> _writeCvFile(Uint8List bytes) async {
    final file = await _cvFile();
    await file.writeAsBytes(bytes).timeout(_ioTimeout);
  }

  Future<File> _jdFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_jdFileName');
  }

  Future<Uint8List?> _readJdFile() async {
    try {
      final file = await _jdFile();
      if (!await file.exists().timeout(_ioTimeout)) return null;
      return await file.readAsBytes().timeout(_ioTimeout);
    } catch (e) {
      debugPrint('ProfileRepository._readJdFile failed: $e');
      return null;
    }
  }

  Future<void> _writeJdFile(Uint8List bytes) async {
    final file = await _jdFile();
    await file.writeAsBytes(bytes).timeout(_ioTimeout);
  }

  Future<File> _photoFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_photoFileName');
  }

  Future<Uint8List?> _readPhotoFile() async {
    try {
      final file = await _photoFile();
      if (!await file.exists().timeout(_ioTimeout)) return null;
      return await file.readAsBytes().timeout(_ioTimeout);
    } catch (e) {
      debugPrint('ProfileRepository._readPhotoFile failed: $e');
      return null;
    }
  }

  Future<void> _writePhotoFile(Uint8List bytes) async {
    final file = await _photoFile();
    await file.writeAsBytes(bytes).timeout(_ioTimeout);
  }

  Future<void> _deletePhotoFile() async {
    try {
      final file = await _photoFile();
      if (await file.exists().timeout(_ioTimeout)) {
        await file.delete().timeout(_ioTimeout);
      }
    } catch (e) {
      debugPrint('ProfileRepository._deletePhotoFile failed: $e');
    }
  }
}
