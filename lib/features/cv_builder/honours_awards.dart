/// Real, standard Indian Armed Forces personal decorations, medals,
/// commendations, and training honours, spanning all three services —
/// curated content, same fixed-list-only discipline as
/// `skill_equivalency.dart`'s course list, so nothing here is guessed or
/// invented. Deliberately excludes civilian state honours (Bharat Ratna,
/// Padma awards) — those are a different category of recognition, not a
/// personal service decoration.
class HonourCategory {
  const HonourCategory({required this.name, required this.awards});

  final String name;
  final List<String> awards;
}

const List<HonourCategory> kHonourCategories = [
  HonourCategory(
    name: 'National Gallantry & Valour',
    awards: [
      'Param Vir Chakra (PVC)',
      'Maha Vir Chakra (MVC)',
      'Vir Chakra (VrC)',
      'Ashoka Chakra (AC)',
      'Kirti Chakra (KC)',
      'Shaurya Chakra (SC)',
    ],
  ),
  HonourCategory(
    name: 'Distinguished / Operational Service Decorations',
    awards: [
      'Sarvottam Yudh Seva Medal (SYSM)',
      'Uttam Yudh Seva Medal (UYSM)',
      'Yudh Seva Medal (YSM)',
      'Param Vishisht Seva Medal (PVSM)',
      'Ati Vishisht Seva Medal (AVSM)',
      'Vishisht Seva Medal (VSM)',
    ],
  ),
  HonourCategory(
    name: 'Service-Specific Gallantry / Devotion to Duty',
    awards: [
      'Sena Medal (Gallantry) — Indian Army',
      'Sena Medal (Devotion to Duty) — Indian Army',
      'Nao Sena Medal (Gallantry) — Indian Navy',
      'Nao Sena Medal (Devotion to Duty) — Indian Navy',
      'Vayu Sena Medal (Gallantry) — Indian Air Force',
      'Vayu Sena Medal (Devotion to Duty) — Indian Air Force',
    ],
  ),
  HonourCategory(
    name: 'Operational / Campaign / Service Medals',
    awards: [
      'General Service Medal–1947',
      'Samanya Seva Medal–1965',
      'Special Service Medal',
      'Samar Seva Star–1965',
      'Poorvi Star',
      'Paschimi Star',
      'Operation Vijay Star',
      'Operation Vijay Medal',
      'Operation Parakram Medal',
      'Siachen Glacier Medal',
      'Raksha Medal–1965',
      'Sangram Medal',
      'Sainya Seva Medal',
      'High Altitude Medal',
      'Videsh Seva Medal',
      'Wound Medal',
    ],
  ),
  HonourCategory(
    name: 'Long Service / Good Service / Territorial Army',
    awards: [
      'Meritorious Service Medal',
      'Long Service and Good Conduct Medal',
      '30 Years Long Service Medal',
      '20 Years Long Service Medal',
      '9 Years Long Service Medal',
      'Territorial Army Decoration',
      'Territorial Army Medal',
    ],
  ),
  HonourCategory(
    name: 'Independence / Commemorative Medals',
    awards: [
      'Indian Independence Medal–1947',
      'Independence Medal–1950',
      '25th Independence Anniversary Medal',
      '50th Independence Anniversary Medal',
      '75th Independence Anniversary Medal',
    ],
  ),
  HonourCategory(
    name: 'Mention-in-Despatches & Formal Service Commendations',
    awards: [
      'Mention-in-Despatches (MID)',
      'Chief of Army Staff Commendation Card',
      'Army Commander Commendation Card',
      'Chief of Naval Staff Commendation',
      'Navy Commander / Flag Officer Commendation',
      'Chief of Air Staff Commendation',
      'Air Officer Commanding-in-Chief Commendation',
      'Chief of Defence Staff Commendation Card',
    ],
  ),
  HonourCategory(
    name: 'Institutional & Training Honours',
    awards: [
      'Sword of Honour — Indian Military Academy (IMA), Dehradun',
      "President's Gold Medal — Indian Military Academy (IMA), Dehradun",
      'Sword of Honour — Officers Training Academy (OTA), Chennai',
      "President's Gold Medal — National Defence Academy (NDA), Khadakwasla",
      'Sword of Honour — Indian Naval Academy (INA), Ezhimala',
      'Chief of the Naval Staff Gold Medal — Indian Naval Academy (INA), Ezhimala',
      'Sword of Honour — Air Force Academy (AFA), Dundigal',
      "President's Plaque / Trophy — Air Force Academy (AFA), Dundigal",
      'Scudder Medal — Defence Services Staff College (DSSC), Wellington',
    ],
  ),
  HonourCategory(
    name: 'Other Official National / Defence Recognition',
    awards: [
      'Jeevan Raksha Padak',
      'Uttam Jeevan Raksha Padak',
      'Parakram Padak',
    ],
  ),
  HonourCategory(
    name: 'UN / Foreign / International',
    awards: [
      'United Nations Medal',
      'Foreign / Allied Military Decoration',
      'Commonwealth / International Military Award',
    ],
  ),
];

/// Sentinel award-dropdown value that reveals a manual text field — for a
/// real honour/award not covered by the fixed lists above. Offered in
/// every category rather than as a top-level entry of its own.
const kOtherHonourOption = 'Other (please specify)';

/// Sentinel category — picking it skips straight to manual entry, for an
/// award that doesn't fit any category below.
const kOtherCategoryOption = 'Other / Not Listed';

List<String> get kAllHonoursAndAwards => [
      for (final c in kHonourCategories) ...c.awards,
    ];

/// Reverse lookup so a cached [AwardEntry] can pre-select its category —
/// null for a manually-typed ("Other") entry, or one from a list version
/// before this award no longer exists.
String? categoryForAward(String name) {
  for (final c in kHonourCategories) {
    if (c.awards.contains(name)) return c.name;
  }
  return null;
}
