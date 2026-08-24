import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/financial_planner/financial_plan.dart';
import 'package:next_career_after_fauj/features/financial_planner/financial_planner_screen.dart';
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
  tester.view.physicalSize = const Size(430, 3200);
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
      await tester.tap(find.byKey(const Key('calculateButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('financialPlanResult')), findsOneWidget);
      expect(repo.lastFinancialPlanInput, isNotNull);
      expect(repo.lastFinancialPlanInput!.annualFixedPay, 1200000);
      expect(repo.lastFinancialPlanInput!.drawsPension, isFalse);
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
