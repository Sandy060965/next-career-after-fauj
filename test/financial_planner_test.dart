import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/compensation/compensation_estimate.dart';
import 'package:next_career_after_fauj/features/financial_planner/financial_plan.dart';
import 'package:next_career_after_fauj/features/financial_planner/financial_planner_screen.dart';
import 'package:next_career_after_fauj/features/financial_planner/military_pay_data.dart';
import 'package:provider/provider.dart';

OfficerProfile _profile({required OfficerSegment segment}) => OfficerProfile(
      rank: 'Lt Col',
      fullName: 'Lt Col A Verma',
      dateOfBirth: DateTime(1978, 5, 10),
      workExperienceYears: 18,
      workExperienceMonths: 2,
      releaseStatus: ReleaseStatus.tentative,
      releaseDate: DateTime(2027, 6, 30),
      service: OfficerService.army,
      mobileNumber: '9876543210',
      email: 'a.verma@example.com',
      segment: segment,
      cvFileName: 'resume.pdf',
      cvExtractedText: 'Sample CV text',
    );

Widget _wrap(ProfileRepository repository) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(theme: AppTheme.light, home: const FinancialPlannerScreen()),
  );
}

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 9000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('calculateFinancialPlan', () {
    test('taxable income at or below the ₹12L rebate threshold owes no tax', () {
      final result = calculateFinancialPlan(
        const FinancialPlanInput(drawsPension: false, annualFixedPay: 1200000),
      );
      expect(result.annualTaxGuaranteed, 0);
      expect(result.netMonthlyGuaranteed, 100000);
    });

    test('applies New Tax Regime slabs above the rebate threshold', () {
      final result = calculateFinancialPlan(
        const FinancialPlanInput(drawsPension: false, annualFixedPay: 2000000),
      );
      expect(result.annualTaxGuaranteed, 192400);
      expect(result.netMonthlyGuaranteed, closeTo(150633.33, 0.01));
    });

    test('pension is only counted toward gross income when drawsPension is true', () {
      final withPension = calculateFinancialPlan(
        const FinancialPlanInput(drawsPension: true, monthlyPension: 50000, annualFixedPay: 600000),
      );
      final withoutPension = calculateFinancialPlan(
        const FinancialPlanInput(drawsPension: false, monthlyPension: 999999, annualFixedPay: 600000),
      );
      // 50,000 * 12 + 600,000 = 1,200,000 gross — exactly the rebate threshold, so still zero tax.
      expect(withPension.netMonthlyGuaranteed, 100000);
      // monthlyPension is ignored entirely when drawsPension is false.
      expect(withoutPension.netMonthlyGuaranteed, closeTo(50000, 0.01));
    });

    test('variable pay affects the with-variable scenario only', () {
      final result = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 1200000,
          annualVariablePay: 300000,
        ),
      );
      expect(result.netMonthlyGuaranteed, 100000);
      expect(result.netMonthlyWithVariable, greaterThan(result.netMonthlyGuaranteed));
    });

    test('cost-of-living deltas sum and reduce the effective net income', () {
      final result = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 1200000,
          monthlyRentDelta: 20000,
          monthlyHealthcareDelta: 5000,
          monthlySchoolFeeDelta: -2000,
          monthlyTransportDelta: 3000,
        ),
      );
      expect(result.monthlyCostOfLivingDelta, 26000);
      expect(result.effectiveMonthlyGuaranteed, 100000 - 26000);
    });

    test('negotiation guidance differs for pensioners vs. non-pensioners', () {
      final pensioner = calculateFinancialPlan(
        const FinancialPlanInput(drawsPension: true, monthlyPension: 60000, annualFixedPay: 1200000),
      );
      final nonPensioner = calculateFinancialPlan(
        const FinancialPlanInput(drawsPension: false, annualFixedPay: 1200000),
      );
      expect(pensioner.negotiationGuidance, contains('guaranteed income floor'));
      expect(nonPensioner.negotiationGuidance, contains('no pension cushion'));
    });

    test('flags a cost-of-living warning only once the delta is a large share of net income', () {
      final small = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 1200000,
          monthlyRentDelta: 2000,
        ),
      );
      final large = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 1200000,
          monthlyRentDelta: 30000,
        ),
      );
      expect(small.negotiationGuidance, isNot(contains('is not automatically a raise')));
      expect(large.negotiationGuidance, contains('is not automatically a raise'));
    });

    test('military cash compensation adds MSP and DA only for ranks that draw MSP', () {
      final major = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 0,
          rank: DefenceRank.major,
          militaryBasicPay: 100000,
          militaryDaPercent: 0.5,
        ),
      );
      // (100000 + 15500) * 12 * 1.5 = 2,079,000
      expect(major.militaryCashCompensation, 2079000);

      final majGen = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 0,
          rank: DefenceRank.majGen,
          militaryBasicPay: 200000,
          militaryDaPercent: 0.5,
        ),
      );
      // No MSP at Major General: 200000 * 12 * 1.5 = 3,600,000
      expect(majGen.militaryCashCompensation, 3600000);
    });

    test('housing benefit only applies while in government accommodation', () {
      final inQuarter = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 0,
          inGovtAccommodation: true,
          comparableMonthlyMarketRent: 50000,
          actualMonthlyAccommodationCost: 5000,
        ),
      );
      expect(inQuarter.militaryCurrentEconomicCompensation, 540000); // (50000-5000)*12

      final notInQuarter = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 0,
          comparableMonthlyMarketRent: 50000,
          actualMonthlyAccommodationCost: 5000,
        ),
      );
      expect(notInQuarter.militaryCurrentEconomicCompensation, 0);
    });

    test('deferred pension value is excluded from current economic compensation', () {
      final result = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: true,
          monthlyPension: 60000,
          annualFixedPay: 0,
          militaryBasicPay: 100000,
        ),
      );
      // (100000 * 12) * (1 + 0.60 default DA) = 1,920,000 — no pension folded in.
      expect(result.militaryCurrentEconomicCompensation, 1920000);
      expect(result.militaryDeferredAnnualEquivalent, 720000);
    });

    test('break-even, recommended target and economic gap follow the officer-entered risk premium', () {
      final result = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 1500000,
          monthlyRentDelta: 10000,
          desiredRiskPremiumPercent: 20,
        ),
      );
      expect(result.transitionCostAdjustmentAnnual, 120000);
      expect(result.breakEvenCorporateCompensation, result.militaryCashCompensation + 120000);
      expect(
        result.recommendedTargetCompensation,
        closeTo(result.breakEvenCorporateCompensation * 1.2, 0.01),
      );
      expect(
        result.economicGap,
        result.corporateRiskAdjustedCompensation - result.breakEvenCorporateCompensation,
      );
    });

    test(
        "break-even uses cash compensation, not economic value, so a housing benefit isn't "
        'double-counted against its own transition-cost delta', () {
      // The officer enters BOTH: (a) the value of free government housing
      // (comparableMonthlyMarketRent vs. what they actually pay), which
      // feeds militaryCurrentEconomicCompensation, and (b) a rent delta
      // describing the same real-world change (going from ~0 to paying
      // full market rent after leaving). Break-even must not count that
      // swing twice just because it's entered on two different fields.
      final result = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 0,
          militaryBasicPay: 100000,
          inGovtAccommodation: true,
          comparableMonthlyMarketRent: 50000,
          actualMonthlyAccommodationCost: 5000,
          monthlyRentDelta: 45000, // same ₹45,000/month swing as the housing benefit above
        ),
      );
      // Current economic value DOES include the ₹540,000/year housing benefit...
      expect(
        result.militaryCurrentEconomicCompensation,
        result.militaryCashCompensation + 540000,
      );
      // ...but break-even must be built on cash + the delta ONLY, not
      // cash + housing benefit + delta, which would count the same
      // ₹540,000 swing twice.
      expect(
        result.breakEvenCorporateCompensation,
        result.militaryCashCompensation + 540000,
      );
      expect(
        result.breakEvenCorporateCompensation,
        isNot(result.militaryCurrentEconomicCompensation + 540000),
      );
    });

    test('flags transition costs only once they look implausibly large vs. current cash pay', () {
      final plausible = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 1200000,
          militaryBasicPay: 100000, // cash ~= 100000*12*1.6 = 1,920,000
          monthlyRentDelta: 20000, // 240,000/year =~ 12.5% of cash
        ),
      );
      expect(plausible.negotiationGuidance, isNot(contains('unusually high')));

      final implausible = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 1200000,
          militaryBasicPay: 100000, // cash ~= 1,920,000
          monthlyRentDelta: 100000, // 1,200,000/year =~ 62.5% of cash
        ),
      );
      expect(implausible.negotiationGuidance, contains('unusually high'));
    });

    test('one-time amounts pass through without affecting any annual figure', () {
      final withOneTimes = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 1500000,
          oneTimeGratuityAndDsop: 2500000,
          joiningBonusOneTime: 300000,
          oneTimeEchsSubscription: 80000,
        ),
      );
      final withoutOneTimes = calculateFinancialPlan(
        const FinancialPlanInput(drawsPension: false, annualFixedPay: 1500000),
      );
      expect(withOneTimes.oneTimeGratuityAndDsop, 2500000);
      expect(withOneTimes.oneTimeJoiningBonus, 300000);
      expect(withOneTimes.oneTimeEchsSubscription, 80000);
      expect(withOneTimes.militaryCurrentEconomicCompensation,
          withoutOneTimes.militaryCurrentEconomicCompensation);
      expect(withOneTimes.corporateGuaranteedCompensation, withoutOneTimes.corporateGuaranteedCompensation);
    });

    test('headline CTC is guaranteed compensation plus full variable and equity, unweighted', () {
      final result = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 2000000,
          annualVariablePay: 500000,
          variableAchievementPercent: 80,
          annualEquityValue: 300000,
        ),
      );
      expect(result.headlineCtc, 2000000 + 500000 + 300000);
      // Risk-adjusted uses the achievement %, unlike headline CTC.
      expect(result.corporateRiskAdjustedCompensation, 2000000 + 500000 * 0.8);
    });

    test('flags variable-heavy and equity-heavy offers only once they cross their thresholds', () {
      final variableHeavy = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 1000000,
          annualVariablePay: 400000, // 400k / 1.4M = ~28.6% > 25%
        ),
      );
      expect(variableHeavy.negotiationGuidance, contains('performance-linked variable pay'));

      final variableLight = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 1000000,
          annualVariablePay: 100000, // 100k / 1.1M = ~9% < 25%
        ),
      );
      expect(variableLight.negotiationGuidance, isNot(contains('performance-linked variable pay')));

      final equityHeavy = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 1000000,
          annualEquityValue: 200000, // 200k / 1.2M = ~16.7% > 10%
        ),
      );
      expect(equityHeavy.negotiationGuidance, contains('Equity (ESOP/RSU)'));

      final equityLight = calculateFinancialPlan(
        const FinancialPlanInput(
          drawsPension: false,
          annualFixedPay: 1000000,
          annualEquityValue: 50000, // 50k / 1.05M = ~4.8% < 10%
        ),
      );
      expect(equityLight.negotiationGuidance, isNot(contains('Equity (ESOP/RSU)')));
    });
  });

  group('illustrativeMilitaryProfiles', () {
    test('covers all 8 requested rank/tenure milestones for all three services', () {
      expect(illustrativeMilitaryProfiles.length, 24);
      for (final service in OfficerService.values) {
        final years = illustrativeMilitaryProfiles
            .where((p) => p.service == service)
            .map((p) => p.yearsOfService)
            .toList();
        expect(years, containsAll([10, 14, 20, 25, 30, 35, 37, 39]));
      }
    });

    test('basic pay uses real 7th CPC matrix figures and rises with the later milestone', () {
      final major10 = illustrativeMilitaryProfiles
          .firstWhere((p) => p.service == OfficerService.army && p.rank == DefenceRank.major && p.yearsOfService == 10);
      final major14 = illustrativeMilitaryProfiles
          .firstWhere((p) => p.service == OfficerService.army && p.rank == DefenceRank.major && p.yearsOfService == 14);
      // Major is a time-scale promotion at ~6 years of service (real,
      // sourced), so a "10 years of service" milestone has already drawn 4
      // annual increments — index 5 (69,000), not index 1 (61,300, "just
      // promoted") — matching how many years they've plainly been a Major.
      expect(major10.basicPay, 69000);
      expect(major14.basicPay, greaterThan(major10.basicPay));
    });

    test('a Colonel at 25 years of service shows pay reflecting years already spent at that '
        'rank, not day-one Colonel pay', () {
      // Colonel is a selection-grade promotion typically reached at ~16
      // years of service, so by 25 years of total service that officer has
      // plainly been a Colonel for ~9 years — a real, reported bug was that
      // this milestone showed the Level 13 matrix's very first (lowest)
      // figure instead.
      final col25 = illustrativeMilitaryProfiles.firstWhere(
        (p) => p.service == OfficerService.army && p.rank == DefenceRank.col && p.yearsOfService == 25,
      );
      const level13FirstIndexPay = 130600;
      expect(col25.basicPay, greaterThan(level13FirstIndexPay));
      expect(col25.basicPay, 175500);
    });

    test('basic pay rises monotonically across every milestone, never lower for a senior/later '
        'rank than a junior/earlier one', () {
      // A second real, reported bug: an earlier version reset each rank's
      // pay to that level's own floor on promotion instead of applying pay
      // protection (never placing a promoted officer below what they drew
      // the moment before), which let e.g. a 35-year Brigadier show less
      // pay than a 30-year Colonel. The 8 milestones are already ordered by
      // both rank and years of service, so basic pay must strictly
      // increase down the list for every service.
      for (final service in OfficerService.values) {
        final milestones =
            illustrativeMilitaryProfiles.where((p) => p.service == service).toList();
        for (var i = 1; i < milestones.length; i++) {
          expect(
            milestones[i].basicPay,
            greaterThanOrEqualTo(milestones[i - 1].basicPay),
            reason: '${milestones[i].label} should not be paid less than '
                '${milestones[i - 1].label}',
          );
        }
      }
    });
  });

  group('FinancialPlannerScreen', () {
    testWidgets('defaults the pension toggle on for a PMR officer', (tester) async {
      _setTallViewport(tester);
      final repo = ProfileRepository()..saveProfile(_profile(segment: OfficerSegment.pmr));
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      final toggle = tester.widget<SwitchListTile>(find.byKey(const Key('drawsPensionSwitch')));
      expect(toggle.value, isTrue);
      expect(find.byKey(const Key('monthlyPensionField')), findsOneWidget);
    });

    testWidgets('defaults the pension toggle off for an SSC officer', (tester) async {
      _setTallViewport(tester);
      final repo = ProfileRepository()..saveProfile(_profile(segment: OfficerSegment.ssc));
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      final toggle = tester.widget<SwitchListTile>(find.byKey(const Key('drawsPensionSwitch')));
      expect(toggle.value, isFalse);
      expect(find.byKey(const Key('monthlyPensionField')), findsNothing);
    });

    testWidgets('rejects a missing fixed pay without showing a result', (tester) async {
      _setTallViewport(tester);
      final repo = ProfileRepository()..saveProfile(_profile(segment: OfficerSegment.ssc));
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('calculateButton')));
      await tester.tap(find.byKey(const Key('calculateButton')));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
      expect(find.byKey(const Key('financialPlanResult')), findsNothing);
    });

    testWidgets('calculating shows the result and persists the input', (tester) async {
      _setTallViewport(tester);
      final repo = ProfileRepository()..saveProfile(_profile(segment: OfficerSegment.ssc));
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fixedPayField')), '1200000');
      await tester.ensureVisible(find.byKey(const Key('calculateButton')));
      await tester.tap(find.byKey(const Key('calculateButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('financialPlanResult')), findsOneWidget);
      expect(repo.lastFinancialPlanInput, isNotNull);
      expect(repo.lastFinancialPlanInput!.annualFixedPay, 1200000);
      expect(repo.lastFinancialPlanInput!.drawsPension, isFalse);
    });

    testWidgets('the transition cost total breaks down by rent, healthcare, school and transport',
        (tester) async {
      _setTallViewport(tester);
      final repo = ProfileRepository()..saveProfile(_profile(segment: OfficerSegment.ssc));
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fixedPayField')), '1200000');
      await tester.enterText(find.byKey(const Key('rentDeltaField')), '10000');
      await tester.enterText(find.byKey(const Key('healthcareDeltaField')), '5000');
      await tester.enterText(find.byKey(const Key('schoolFeeDeltaField')), '3000');
      await tester.enterText(find.byKey(const Key('transportDeltaField')), '2000');
      await tester.ensureVisible(find.byKey(const Key('calculateButton')));
      await tester.tap(find.byKey(const Key('calculateButton')));
      await tester.pumpAndSettle();

      // Annualised, in the "does this offer clear the bar" breakdown:
      // ₹10,000/month rent delta -> ₹120,000/year.
      expect(find.text('· Rent (annual)'), findsOneWidget);
      expect(find.textContaining('120,000'), findsWidgets);
      // Monthly, in the "after your cost-of-living change" card.
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Healthcare'), findsOneWidget);
      expect(find.text("Children's education"), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
    });

    testWidgets(
        'the current-benefits total breaks down by housing, education (with child count), '
        'medical and CSD', (tester) async {
      _setTallViewport(tester);
      final repo = ProfileRepository()..saveProfile(_profile(segment: OfficerSegment.ssc));
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fixedPayField')), '1200000');
      await tester.enterText(find.byKey(const Key('dependentChildrenField')), '2');
      await tester.enterText(find.byKey(const Key('schoolCostComparableField')), '180000');
      await tester.enterText(find.byKey(const Key('schoolCostActualField')), '60000');
      await tester.enterText(find.byKey(const Key('medicalBenchmarkField')), '50000');
      await tester.ensureVisible(find.byKey(const Key('calculateButton')));
      await tester.tap(find.byKey(const Key('calculateButton')));
      await tester.pumpAndSettle();

      expect(find.text('· Housing'), findsOneWidget);
      expect(find.text('· Education (2 children)'), findsOneWidget);
      // 180,000 * 2 - 60,000 = 300,000 — confirms both children are counted.
      expect(find.textContaining('300,000'), findsWidgets);
      expect(find.text('· Medical'), findsOneWidget);
      expect(find.text('· CSD/other savings'), findsOneWidget);
    });

    testWidgets('Target is flagged once it drifts too far above real market data', (tester) async {
      _setTallViewport(tester);
      final repo = ProfileRepository()..saveProfile(_profile(segment: OfficerSegment.ssc));
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fixedPayField')), '1200000');
      await tester.enterText(find.byKey(const Key('militaryBasicPayField')), '150000');
      await tester.enterText(find.byKey(const Key('rentDeltaField')), '150000');
      await tester.ensureVisible(find.byKey(const Key('calculateButton')));
      await tester.tap(find.byKey(const Key('calculateButton')));
      await tester.pumpAndSettle();

      expect(find.textContaining('above real market pay'), findsNothing);

      repo.saveCompensationEstimate(
        const CompensationEstimate(
          jobTitle: 'COO',
          location: 'Mumbai',
          maxSalary: 500000, // Well below the target this input produces.
          negotiationGuidance: 'n/a',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('above real market pay'), findsOneWidget);
    });

    testWidgets('loading an illustrative example pre-fills rank, years and basic pay', (tester) async {
      _setTallViewport(tester);
      final repo = ProfileRepository()..saveProfile(_profile(segment: OfficerSegment.pmr));
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('examplePickerDropdown')));
      await tester.tap(find.byKey(const Key('examplePickerDropdown')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Major · 10 yrs service (SSC officer, early exit window)').first);
      await tester.pumpAndSettle();

      final basicPayField =
          tester.widget<TextFormField>(find.byKey(const Key('militaryBasicPayField')));
      expect(basicPayField.controller!.text, '69000');
      final yearsField =
          tester.widget<TextFormField>(find.byKey(const Key('yearsOfServiceField')));
      expect(yearsField.controller!.text, '10');
    });

    testWidgets('re-opening with a saved plan pre-fills fields and shows the result immediately',
        (tester) async {
      _setTallViewport(tester);
      final repo = ProfileRepository()..saveProfile(_profile(segment: OfficerSegment.pmr));
      await repo.saveFinancialPlanInput(
        const FinancialPlanInput(drawsPension: true, monthlyPension: 60000, annualFixedPay: 1500000),
      );

      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('financialPlanResult')), findsOneWidget);
      expect(find.text('60000'), findsOneWidget);
      expect(find.text('1500000'), findsOneWidget);
    });

    testWidgets('the full calculation panel expands to show every O-01 to O-09 output',
        (tester) async {
      _setTallViewport(tester);
      final repo = ProfileRepository()..saveProfile(_profile(segment: OfficerSegment.ssc));
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fixedPayField')), '1200000');
      await tester.ensureVisible(find.byKey(const Key('calculateButton')));
      await tester.tap(find.byKey(const Key('calculateButton')));
      await tester.pumpAndSettle();

      expect(find.textContaining('O-01 ·'), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('fullCalculationTile')));
      await tester.tap(find.byKey(const Key('fullCalculationTile')));
      await tester.pumpAndSettle();

      for (final id in ['O-01', 'O-02', 'O-03', 'O-04', 'O-05', 'O-06', 'O-07', 'O-08', 'O-09']) {
        expect(find.textContaining('$id ·'), findsOneWidget, reason: 'missing $id');
      }
    });

    testWidgets('Stretch stays unshown with no cached market data, and appears once one exists',
        (tester) async {
      _setTallViewport(tester);
      final repo = ProfileRepository()..saveProfile(_profile(segment: OfficerSegment.ssc));
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('fixedPayField')), '1200000');
      await tester.ensureVisible(find.byKey(const Key('calculateButton')));
      await tester.tap(find.byKey(const Key('calculateButton')));
      await tester.pumpAndSettle();

      expect(find.textContaining('not shown yet'), findsOneWidget);
      expect(find.textContaining('negotiation ceiling'), findsNothing);

      repo.saveCompensationEstimate(
        const CompensationEstimate(
          jobTitle: 'COO',
          location: 'Mumbai',
          maxSalary: 2000000,
          negotiationGuidance: 'n/a',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('not shown yet'), findsNothing);
      expect(find.textContaining('negotiation ceiling'), findsOneWidget);
    });
  });
}
