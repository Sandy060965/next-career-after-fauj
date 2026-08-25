import '../../core/models/officer_profile.dart';

/// Corps/Arm/Branch, keyed by service — real, well-known, unclassified
/// organisational affiliations (not an ACR or service-record field; closer
/// to "which engineering discipline" for a civilian professional). Optional
/// at onboarding: a null value just means no Corps/Arm-based signal is
/// used, the same "never fill with a guessed default" rule as everywhere
/// else profile data is missing.
const Map<OfficerService, List<String>> kCorpsByService = {
  OfficerService.army: [
    'Infantry',
    'Armoured Corps',
    'Regiment of Artillery',
    'Corps of Army Air Defence',
    'Corps of Engineers',
    'Corps of Signals',
    'Army Aviation Corps',
    'Mechanised Infantry',
    'Army Service Corps (ASC)',
    'Army Ordnance Corps (AOC)',
    'Corps of Electronics & Mechanical Engineers (EME)',
    'Army Medical Corps (AMC)',
    'Army Dental Corps (ADC)',
    'Military Nursing Service (MNS)',
    'Corps of Military Police (CMP)',
    'Military Intelligence',
    "Judge Advocate General's Department (JAG)",
    'Army Education Corps (AEC)',
    'Army Postal Service (APS)',
    'Remount & Veterinary Corps (RVC)',
    'Pioneer Corps',
    'Intelligence Corps',
  ],
  OfficerService.navy: [
    'Executive Branch (Seaman/Gunnery/Navigation)',
    'Executive Branch (Air Traffic Control/Observer)',
    'Engineering Branch',
    'Electrical Branch',
    'Education Branch',
    'Logistics Branch',
    'Medical Branch (Navy)',
    "Judge Advocate General's Branch (Navy)",
  ],
  OfficerService.airForce: [
    'Flying Branch',
    'Technical Branch (Engineering)',
    'Administration Branch',
    'Logistics Branch',
    'Accounts Branch',
    'Education Branch',
    'Meteorology Branch',
    'Medical Branch (Air Force)',
    "Judge Advocate General's Branch (Air Force)",
  ],
};
