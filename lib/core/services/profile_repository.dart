import 'package:flutter/foundation.dart';

import '../models/officer_profile.dart';

/// In-memory holder for the officer's profile, shared between the
/// onboarding flow and the profile screen via Provider.
class ProfileRepository extends ChangeNotifier {
  OfficerProfile? _profile;

  OfficerProfile? get profile => _profile;

  void saveProfile(OfficerProfile profile) {
    _profile = profile;
    notifyListeners();
  }
}
