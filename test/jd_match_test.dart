import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:officer_career_app/core/theme/app_theme.dart';
import 'package:officer_career_app/features/jd_match/jd_match_screen.dart';

Widget _appUnderTest({required Future<String?> Function() pickFile}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: JdMatchScreen(pickFile: pickFile),
  );
}

void main() {
  testWidgets('pasting a JD and checking match shows a captured summary', (tester) async {
    await tester.pumpWidget(_appUnderTest(pickFile: () async => null));

    // Submitting empty shows a validation error instead of a fake result.
    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();
    expect(find.text('Paste a job description to continue'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('jdTextField')),
      'Looking for a logistics manager with 10 years experience.',
    );
    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();

    expect(find.text('Received'), findsOneWidget);
    expect(find.text('Looking for a logistics manager with 10 years experience.'), findsWidgets);
    expect(find.textContaining('coming in a future release'), findsOneWidget);
  });

  testWidgets('uploading a JD file and checking match shows the file name', (tester) async {
    await tester.pumpWidget(_appUnderTest(pickFile: () async => 'job-description.pdf'));

    await tester.tap(find.byKey(const Key('jdInput_upload')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();
    expect(find.text('Upload a job description to continue'), findsOneWidget);

    await tester.tap(find.byKey(const Key('jdBrowseButton')));
    await tester.pumpAndSettle();
    expect(find.text('job-description.pdf'), findsWidgets);

    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();

    expect(find.text('Received'), findsOneWidget);
  });
}
