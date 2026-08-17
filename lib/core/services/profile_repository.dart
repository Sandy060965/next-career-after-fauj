import 'package:flutter/foundation.dart';

import '../../features/fitment/fitment_result.dart';
import '../../features/vertical_fit/vertical_fit.dart';
import '../models/officer_profile.dart';

/// In-memory holder for the officer's profile, shared between the
/// onboarding flow and the profile screen via Provider.
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

  void saveProfile(OfficerProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  void saveFitmentResult(FitmentResult result, {String? jdText}) {
    _lastFitmentResult = result;
    _lastJdText = jdText;
    notifyListeners();
  }

  void saveVerticalFitAssessment(VerticalFitAssessment assessment) {
    _lastVerticalFitAssessment = assessment;
    notifyListeners();
  }
}
