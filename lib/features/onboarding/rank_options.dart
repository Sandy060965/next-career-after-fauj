import '../../core/models/officer_profile.dart';

/// Commissioned-officer rank progressions, keyed by service. Used to
/// constrain the Rank dropdown to values valid for the selected Service.
const Map<OfficerService, List<String>> kRanksByService = {
  OfficerService.army: [
    'Lieutenant',
    'Captain',
    'Major',
    'Lieutenant Colonel',
    'Colonel',
    'Brigadier',
    'Major General',
    'Lieutenant General',
    'General',
  ],
  OfficerService.navy: [
    'Sub Lieutenant',
    'Lieutenant',
    'Lieutenant Commander',
    'Commander',
    'Captain',
    'Commodore',
    'Rear Admiral',
    'Vice Admiral',
    'Admiral',
  ],
  OfficerService.airForce: [
    'Flying Officer',
    'Flight Lieutenant',
    'Squadron Leader',
    'Wing Commander',
    'Group Captain',
    'Air Commodore',
    'Air Vice Marshal',
    'Air Marshal',
    'Air Chief Marshal',
  ],
};
