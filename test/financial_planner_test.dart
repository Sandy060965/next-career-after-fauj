import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
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
        ),
      );
      expect(result.monthlyCostOfLivingDelta, 23000);
      expect(result.effectiveMonthlyGuaranteed, 100000 - 23000);
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
        FinancialPlanInput(
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
        FinancialPlanInput(
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
      expect(result.breakEvenCorporateCompensation, result.militaryCurrentEconomicCompensation + 120000);
      expect(
        result.recommendedTargetCompensation,
        closeTo(result.breakEvenCorporateCompensation * 1.2, 0.01),
      );
      expect(
        result.economicGap,
        result.corporateRiskAdjustedCompensation -
            result.militaryCurrentEconomicCompensation -
            120000,
      );
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
      expect(major10.basicPay, 61300);
      expect(major14.basicPay, greaterThan(major10.basicPay));
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
      expect(basicPayField.controller!.text, '61300');
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
  });
}
