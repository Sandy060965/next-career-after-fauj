import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/support/support_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return ChangeNotifierProvider<ProfileRepository>(
    create: (_) => ProfileRepository(),
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('submitting a message shows a confirmation', (tester) async {
    String? captured;
    await tester.pumpWidget(
      _wrap(SupportScreen(
        submitTicket: ({required repository, required message}) async {
          captured = message;
        },
      )),
    );

    await tester.enterText(
      find.byKey(const Key('supportMessageField')),
      'JD Match keeps hanging on my PDF.',
    );
    await tester.tap(find.byKey(const Key('submitSupportTicketButton')));
    await tester.pumpAndSettle();

    expect(captured, 'JD Match keeps hanging on my PDF.');
    expect(find.byKey(const Key('supportTicketSentMessage')), findsOneWidget);
  });

  testWidgets('rejects an empty message without calling the service', (tester) async {
    var called = false;
    await tester.pumpWidget(
      _wrap(SupportScreen(
        submitTicket: ({required repository, required message}) async {
          called = true;
        },
      )),
    );

    await tester.tap(find.byKey(const Key('submitSupportTicketButton')));
    await tester.pumpAndSettle();

    expect(called, isFalse);
    expect(find.textContaining('describe what you need help with'), findsOneWidget);
  });

  testWidgets('shows an error message if submission fails', (tester) async {
    await tester.pumpWidget(
      _wrap(SupportScreen(
        submitTicket: ({required repository, required message}) async {
          throw Exception('network down');
        },
      )),
    );

    await tester.enterText(find.byKey(const Key('supportMessageField')), 'hello');
    await tester.tap(find.byKey(const Key('submitSupportTicketButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('network down'), findsOneWidget);
  });

  testWidgets('"Send another message" clears the form after a successful send', (tester) async {
    await tester.pumpWidget(
      _wrap(SupportScreen(
        submitTicket: ({required repository, required message}) async {},
      )),
    );

    await tester.enterText(find.byKey(const Key('supportMessageField')), 'hello');
    await tester.tap(find.byKey(const Key('submitSupportTicketButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sendAnotherSupportMessageButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('supportMessageField')), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(const Key('supportMessageField')));
    expect(field.controller?.text, isEmpty);
  });
}
