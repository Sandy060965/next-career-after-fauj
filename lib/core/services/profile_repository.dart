import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/ai_readiness/ai_readiness.dart';
import '../../features/cv_civilianizer/civilianized_cv.dart';
import '../../features/financial_planner/financial_plan.dart';
import '../../features/fitment/fitment_result.dart';
import '../../features/vertical_fit/vertical_fit.dart';
import '../models/job_application.dart';
import '../models/officer_account.dart';
import '../models/officer_profile.dart';
import 'session_storage.dart';

const _profileKey = 'officer_profile_v1';
const _fitmentResultKey = 'last_fitment_result_v1';
const _jdTextKey = 'last_jd_text_v1';
const _verticalFitKey = 'last_vertical_fit_v1';
const _aiReadinessKey = 'last_ai_readiness_v1';
const _accountKey = 'officer_account_v1';
const _applicationsKey = 'job_applications_v1';
const _civilianizedCvKey = 'last_civilianized_cv_v1';
const _financialPlanKey = 'last_financial_plan_input_v1';
const _cvFileName = 'officer_cv';

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
  VerticalFitAssessment? _lastVerticalFitAssessment;
  AiReadinessResult? _lastAiReadinessResult;
  String? _sessionToken;
  OfficerAccount? _account;
  List<JobApplication> _applications = [];
  CivilianizedCv? _lastCivilianizedCv;
  FinancialPlanInput? _lastFinancialPlanInput;

  OfficerProfile? get profile => _profile;

  /// Non-null once the officer has verified their phone number — gates
  /// access to onboarding (see main.dart's initialRoute logic). Distinct
  /// from [profile], which is the officer's own career data collected
  /// during onboarding.
  String? get sessionToken => _sessionToken;

  OfficerAccount? get account => _account;

  /// The most recent JD-match result, cached so Refined CV and Gap Roadmap
  /// can be reached directly from the Profile screen instead of only via
  /// the JD Match flow.
  FitmentResult? get lastFitmentResult => _lastFitmentResult;
  String? get lastJdText => _lastJdText;

  VerticalFitAssessment? get lastVerticalFitAssessment => _lastVerticalFitAssessment;

  AiReadinessResult? get lastAiReadinessResult => _lastAiReadinessResult;

  /// The officer's own application pipeline — newest first.
  List<JobApplication> get applications => List.unmodifiable(_applications);

  CivilianizedCv? get lastCivilianizedCv => _lastCivilianizedCv;

  FinancialPlanInput? get lastFinancialPlanInput => _lastFinancialPlanInput;

  /// Loads previously persisted state from disk. Call once, before
  /// runApp, so the UI never flashes an empty state that then repopulates.
  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final profileJson = prefs.getString(_profileKey);
      if (profileJson != null) {
        final cvBytes = await _readCvFile();
        _profile = OfficerProfile.fromJson(
          jsonDecode(profileJson) as Map<String, dynamic>,
          cvPdfBytes: cvBytes,
        );
      }

      final fitmentJson = prefs.getString(_fitmentResultKey);
      if (fitmentJson != null) {
        _lastFitmentResult = FitmentResult.fromJson(jsonDecode(fitmentJson) as Map<String, dynamic>);
      }
      _lastJdText = prefs.getString(_jdTextKey);

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
      }

      final financialPlanJson = prefs.getString(_financialPlanKey);
      if (financialPlanJson != null) {
        _lastFinancialPlanInput =
            FinancialPlanInput.fromJson(jsonDecode(financialPlanJson) as Map<String, dynamic>);
      }
    } catch (e) {
      // Corrupt or unavailable storage — start fresh rather than crash.
      debugPrint('ProfileRepository.loadFromStorage failed: $e');
    }

    // The session token lives in secure storage, not SharedPreferences —
    // read separately so a failure here doesn't take the rest of the cached
    // state down with it.
    _sessionToken = await _sessionStorage.readToken();
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

  Future<void> saveFitmentResult(FitmentResult result, {String? jdText}) async {
    _lastFitmentResult = result;
    _lastJdText = jdText;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fitmentResultKey, jsonEncode(result.toJson()));
      if (jdText != null) {
        await prefs.setString(_jdTextKey, jdText);
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

  /// Called once, right after phone-OTP verification succeeds.
  Future<void> saveSession(String token, OfficerAccount account) async {
    _sessionToken = token;
    _account = account;
    notifyListeners();
    await _sessionStorage.saveToken(token);
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

  Future<void> saveCivilianizedCv(CivilianizedCv result) async {
    _lastCivilianizedCv = result;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_civilianizedCvKey, jsonEncode(result.toJson()));
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
}
