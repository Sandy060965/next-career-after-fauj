import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/fitment/fitment_result.dart';
import '../../features/vertical_fit/vertical_fit.dart';
import '../models/officer_profile.dart';

const _profileKey = 'officer_profile_v1';
const _fitmentResultKey = 'last_fitment_result_v1';
const _jdTextKey = 'last_jd_text_v1';
const _verticalFitKey = 'last_vertical_fit_v1';
const _cvFileName = 'officer_cv';

/// Holder for the officer's profile and cross-screen state, shared via
/// Provider. Persists to disk (SharedPreferences for structured data, a
/// file for the CV's raw bytes) so nothing is lost when the app restarts —
/// persistence is always best-effort: a write/read failure falls back to
/// in-memory-only behaviour rather than crashing the app.
class ProfileRepository extends ChangeNotifier {
  OfficerProfile? _profile;
  FitmentResult? _lastFitmentResult;
  String? _lastJdText;
  VerticalFitAssessment? _lastVerticalFitAssessment;

  OfficerProfile? get profile => _profile;

  /// The most recent JD-match result, cached so Refined CV and Gap Roadmap
  /// can be reached directly from the Profile screen instead of only via
  /// the JD Match flow.
  FitmentResult? get lastFitmentResult => _lastFitmentResult;
  String? get lastJdText => _lastJdText;

  VerticalFitAssessment? get lastVerticalFitAssessment => _lastVerticalFitAssessment;

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
    } catch (e) {
      // Corrupt or unavailable storage — start fresh rather than crash.
      debugPrint('ProfileRepository.loadFromStorage failed: $e');
    }
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
