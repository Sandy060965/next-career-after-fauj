import '../../core/models/officer_profile.dart';

/// Real, sourced 7th CPC Defence Pay Matrix data — deliberately kept in one
/// small, clearly-dated file. When the 8th Pay Commission's matrix is
/// notified, only this file needs a refresh; nothing else in the app
/// hardcodes a rank-to-pay lookup, so no other screen or calculation
/// changes. Sources: 7th CPC Report (Dept. of Expenditure) and the
/// Committee on Allowances Report.
enum DefenceRank {
  major('Major', 'Lieutenant Commander', 'Squadron Leader', _level10B, true),
  ltCol('Lieutenant Colonel', 'Commander', 'Wing Commander', _level12A, true),
  col('Colonel', 'Captain', 'Group Captain', _level13, true),
  brig('Brigadier', 'Commodore', 'Air Commodore', _level13A, true),
  majGen('Major General', 'Rear Admiral', 'Air Vice Marshal', _level14, false),
  ltGen('Lieutenant General', 'Vice Admiral', 'Air Marshal', _level15, false);

  const DefenceRank(this.armyLabel, this.navyLabel, this.airForceLabel, this.payMatrix, this.drawsMsp);

  final String armyLabel;
  final String navyLabel;
  final String airForceLabel;

  /// Basic pay by matrix index (index 0 = index 1 of the real matrix, i.e.
  /// pay on first entering this rank/level).
  final List<int> payMatrix;

  /// MSP applies up to Brigadier-equivalent; there is no separate MSP for
  /// Major General and above (those are apex-scale appointments).
  final bool drawsMsp;

  String labelFor(OfficerService service) {
    switch (service) {
      case OfficerService.army:
        return armyLabel;
      case OfficerService.navy:
        return navyLabel;
      case OfficerService.airForce:
        return airForceLabel;
    }
  }

  /// Basic pay for the given 1-based index within this rank's level,
  /// clamped to the matrix's actual range.
  int basicPayAtIndex(int index) {
    final clamped = index.clamp(1, payMatrix.length);
    return payMatrix[clamped - 1];
  }
}

// 7th CPC Defence Pay Matrix, ₹/month. Levels enhanced 2.57x → 2.67x for
// 12A & 13 with effect from 2 July 2018.
const _level10B = [
  61300, 63100, 65000, 67000, 69000, 71100, 73200, 75400, 77700, 80000,
  82400, 84900, 87400, 90000, 92700, 95500, 98400, 101400, 104400, 107500,
  110700, 114000, 117400, 120900, 124500, 128200, 132000, 136000, 140100, 144300,
  148600, 153100, 157700, 162400, 167300, 172300, 177500, 182800, 188300, 193900,
];

const _level12A = [
  121200, 124800, 128500, 132400, 136400, 140500, 144700, 149000, 153500, 158100,
  162800, 167700, 172700, 177900, 183200, 188700, 194400, 200200, 206200, 212400,
];

const _level13 = [
  130600, 134500, 138500, 142700, 147000, 151400, 155900, 160600, 165400, 170400,
  175500, 180800, 186200, 191800, 197600, 203500, 209600, 215900,
];

const _level13A = [
  139600, 143800, 148100, 152500, 157100, 161800, 166700, 171700, 176900, 182200,
  187700, 193300, 199100, 205100, 211300, 217600,
];

const _level14 = [
  144200, 148500, 153000, 157600, 162300, 167200, 172200, 177400, 182700, 188200,
  193800, 199600, 205600, 211800, 218200,
];

const _level15 = [
  182200, 187700, 193300, 199100, 205100, 211300, 217600, 224100,
];

/// Military Service Pay — flat, real, current figure (7th CPC), part of
/// basic pay for DA/HRA purposes. Does not apply to [DefenceRank.majGen]
/// and above.
const num militaryServicePay = 15500;

/// Current Dearness Allowance rate, effective from the 1 Jan 2026 revision.
/// DA revises roughly every six months (January and July) independent of
/// the Pay Commission cycle, so this is deliberately exposed as an
/// *editable default* everywhere it's used, never applied silently — the
/// officer should confirm the current rate from their own payslip.
const num currentDaPercent = 0.60;

/// A pre-filled example an officer can load into the calculator to see a
/// realistic starting point, then edit with their own real figures. Basic
/// pay is real 7th CPC matrix data; every downstream figure (DA, benefits)
/// remains editable. Not a prediction of any individual's actual pay —
/// actual placement in the matrix depends on an officer's own promotion
/// and increment history, which this cannot know.
class IllustrativeMilitaryProfile {
  const IllustrativeMilitaryProfile({
    required this.service,
    required this.rank,
    required this.yearsOfService,
    required this.matrixIndex,
    required this.note,
  });

  final OfficerService service;
  final DefenceRank rank;
  final int yearsOfService;
  final int matrixIndex;
  final String note;

  String get label => '${rank.labelFor(service)} · $yearsOfService yrs service';

  num get basicPay => rank.basicPayAtIndex(matrixIndex);
}

/// The 8 rank/tenure milestones requested, each shown for all three
/// services. Where two milestones share a rank (Major-equivalent at 10 &
/// 14 years, to bracket typical SSC exit; Colonel-equivalent at 25 & 30
/// years), the later one adds one matrix increment per additional year in
/// that rank — everywhere else the milestone is shown at that rank's
/// starting basic pay (matrix index 1), i.e. "just promoted." Real career
/// progression varies by officer, arm and service; treat these as
/// illustrative starting points, not a forecast.
final List<IllustrativeMilitaryProfile> illustrativeMilitaryProfiles = [
  for (final service in OfficerService.values) ...[
    IllustrativeMilitaryProfile(
      service: service,
      rank: DefenceRank.major,
      yearsOfService: 10,
      matrixIndex: 1,
      note: 'SSC officer, early exit window',
    ),
    IllustrativeMilitaryProfile(
      service: service,
      rank: DefenceRank.major,
      yearsOfService: 14,
      matrixIndex: 5,
      note: 'SSC officer, extended tenure exit window',
    ),
    IllustrativeMilitaryProfile(
      service: service,
      rank: DefenceRank.ltCol,
      yearsOfService: 20,
      matrixIndex: 1,
      note: 'Time-scale promotion, mid-career',
    ),
    IllustrativeMilitaryProfile(
      service: service,
      rank: DefenceRank.col,
      yearsOfService: 25,
      matrixIndex: 1,
      note: 'Select-grade promotion',
    ),
    IllustrativeMilitaryProfile(
      service: service,
      rank: DefenceRank.col,
      yearsOfService: 30,
      matrixIndex: 6,
      note: 'Extended tenure at rank',
    ),
    IllustrativeMilitaryProfile(
      service: service,
      rank: DefenceRank.brig,
      yearsOfService: 35,
      matrixIndex: 1,
      note: 'Select-grade promotion',
    ),
    IllustrativeMilitaryProfile(
      service: service,
      rank: DefenceRank.majGen,
      yearsOfService: 37,
      matrixIndex: 1,
      note: 'Select-grade promotion, apex scale — no MSP',
    ),
    IllustrativeMilitaryProfile(
      service: service,
      rank: DefenceRank.ltGen,
      yearsOfService: 39,
      matrixIndex: 1,
      note: 'Select-grade promotion, apex scale — no MSP',
    ),
  ],
];
