import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/cv_examples/cv_examples_screen.dart';
import 'package:next_career_after_fauj/features/cv_templates/cv_pdf_fonts.dart';

// PdfPreview's SizedBox(height: 700) pushes everything after it far past the
// default test viewport, and the sliver list lazily only mounts children
// near the viewport — so a tall viewport is needed for the Download button
// (and anything else below the preview) to exist in the element tree at all.
void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

Future<CvPdfFonts> _realLoadFonts() => CvPdfFonts.load();

void main() {
  testWidgets('selecting a Service narrows the Rank dropdown to that service\'s 6 tiers', (tester) async {
    await tester.pumpWidget(_wrap(CvExamplesScreen(loadFonts: _realLoadFonts, onDeliverPdf: (_, __) async {})));

    await tester.tap(find.byKey(const Key('cvExampleServiceDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Navy').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cvExampleRankDropdown')));
    await tester.pumpAndSettle();
    expect(find.text('Lieutenant Commander').last, findsOneWidget);
    expect(find.text('Commander').last, findsOneWidget);
    // An Army-only rank should not appear once Navy is selected.
    expect(find.text('Brigadier'), findsNothing);
  });

  testWidgets(
      'selecting Service, Rank, and career track shows the fictional-composite notice and a download action',
      (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(CvExamplesScreen(loadFonts: _realLoadFonts, onDeliverPdf: (_, __) async {})));

    await tester.tap(find.byKey(const Key('cvExampleServiceDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Army').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cvExampleRankDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Major').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cvExampleArchetypeDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Operations & General Management').last);
    // Not pumpAndSettle from here: PdfPreview keeps its own perpetual
    // internal state (a loading animation, since flutter test's headless
    // VM environment has no real PDF rasterizer for it to resolve
    // against) that never lets the frame queue settle — a bounded pump is
    // enough for the surrounding UI (our own widgets) to finish building.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('cvExampleFictionalNotice')), findsOneWidget);
    expect(find.byKey(const Key('cvExampleDownloadButton')), findsOneWidget);
  });

  testWidgets('tapping Download invokes the injected delivery hook with real PDF bytes', (tester) async {
    _setTallViewport(tester);
    String? deliveredFileName;
    List<int>? deliveredBytes;
    await tester.pumpWidget(_wrap(CvExamplesScreen(
      loadFonts: _realLoadFonts,
      onDeliverPdf: (bytes, fileName) async {
        deliveredBytes = bytes;
        deliveredFileName = fileName;
      },
    )));

    await tester.tap(find.byKey(const Key('cvExampleServiceDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Air Force').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cvExampleRankDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Squadron Leader').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cvExampleArchetypeDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Strategy, Transformation & Corporate Leadership').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('cvExampleDownloadButton')));
    // Not pumpAndSettle here either — same PdfPreview caveat as above.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(deliveredFileName, isNotNull);
    expect(deliveredFileName, contains('CV_Example_'));
    expect(deliveredBytes, isNotNull);
    expect(deliveredBytes, isNotEmpty);
  });
}
