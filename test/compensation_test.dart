import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/compensation/compensation_estimate.dart';
import 'package:next_career_after_fauj/features/compensation/compensation_screen.dart';
import 'package:next_career_after_fauj/features/fitment/fitment_result.dart';
import 'package:provider/provider.dart';

const _stubFitmentResult = FitmentResult(
  fitmentScore: 7,
  scoreRationale: 'Test',
  requirementBreakdown: [],
  originalCvExcerpt: 'Excerpt',
  refinedCv: 'Refined',
  dimensionGaps: [],
  gapRoadmap: [],
);

Future<CompensationEstimate> _stubEstimate({required String jdText, String? cvText}) async {
  return const CompensationEstimate(
    jobTitle: 'Chief Operating Officer',
    location: 'Mumbai, India',
    minSalary: 4500000,
    maxSalary: 8200000,
    medianSalary: 6100000,
    currency: 'INR',
    period: 'YEAR',
    confidence: 'CONFIDENT',
    publisher: 'Glassdoor',
    negotiationGuidance: 'Test negotiation guidance.',
  );
}

Future<CompensationEstimate> _stubNoData({required String jdText, String? cvText}) async {
  return const CompensationEstimate(
    jobTitle: 'Niche Executive Role',
    location: 'Mumbai, India',
    negotiationGuidance: 'Guidance without market data.',
  );
}

Widget _wrap(Widget child, {ProfileRepository? repository}) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository ?? ProfileRepository(),
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

void main() {
  testWidgets('prompts to run JD Match when no JD is cached yet', (tester) async {
    await tester.pumpWidget(_wrap(const CompensationScreen(estimateCompensation: _stubEstimate)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('goToJdMatchButton')), findsOneWidget);
  });

  testWidgets('shows the real market range and negotiation guidance once a JD is cached',
      (tester) async {
    final repository = ProfileRepository()
      ..saveFitmentResult(_stubFitmentResult, jdText: 'COO role in manufacturing');

    await tester.pumpWidget(
      _wrap(
        const CompensationScreen(estimateCompensation: _stubEstimate),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('marketDataCard')), findsOneWidget);
    expect(find.textContaining('4,500,000'), findsOneWidget);
    expect(find.textContaining('via Glassdoor'), findsOneWidget);
    expect(find.text('Test negotiation guidance.'), findsOneWidget);
  });

  testWidgets('shows a no-data card when the real API has nothing for this role', (tester) async {
    final repository = ProfileRepository()
      ..saveFitmentResult(_stubFitmentResult, jdText: 'Extremely niche role');

    await tester.pumpWidget(
      _wrap(
        const CompensationScreen(estimateCompensation: _stubNoData),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('noMarketDataCard')), findsOneWidget);
    expect(find.text('Guidance without market data.'), findsOneWidget);
  });
}
