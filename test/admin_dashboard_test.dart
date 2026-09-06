import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/admin/admin_dashboard_screen.dart';
import 'package:next_career_after_fauj/features/admin/admin_login_screen.dart';
import 'package:next_career_after_fauj/features/admin/admin_officer_summary.dart';
import 'package:next_career_after_fauj/features/admin/allowed_phone_summary.dart';
import 'package:next_career_after_fauj/features/admin/login_event.dart';
import 'package:next_career_after_fauj/features/admin/support_ticket_summary.dart';

final _officer = AdminOfficerSummary(
  id: 'officer-1',
  mobileNumber: '9876543210',
  createdAt: DateTime(2026, 1, 10),
  entitlementTier: 'free',
  rank: 'Lt Col',
  fullName: 'A Verma',
  service: 'army',
  segment: 'pmr',
  readinessScore: 72,
  readinessDimensionsCompleted: 2,
  readinessDimensionsTotal: 3,
  cvUploaded: true,
  civilianizedCvDone: true,
  builtCvDone: false,
  jdMatchDone: true,
  financialPlanDone: false,
  targetRoleStrategyDone: false,
  applicationsCount: 2,
  progressUpdatedAt: DateTime(2026, 1, 15),
);

final _neverOpenedOfficer = AdminOfficerSummary(
  id: 'officer-2',
  mobileNumber: '9123456780',
  createdAt: DateTime(2026, 1, 12),
  entitlementTier: 'free',
  readinessDimensionsCompleted: 0,
  readinessDimensionsTotal: 0,
  cvUploaded: false,
  civilianizedCvDone: false,
  builtCvDone: false,
  jdMatchDone: false,
  financialPlanDone: false,
  targetRoleStrategyDone: false,
  applicationsCount: 0,
);

final _openTicket = SupportTicketSummary(
  id: 'ticket-1',
  officerId: 'officer-1',
  mobileNumber: '9876543210',
  message: 'JD Match hangs on my PDF.',
  status: 'open',
  createdAt: DateTime(2026, 1, 16),
);

final _allowedPhone = AllowedPhoneSummary(
  mobileNumber: '9876543210',
  note: 'Cousin',
  addedAt: DateTime(2026, 1, 5),
);

// Never actually called by these tests, but AdminDashboardScreen/AdminLoginScreen
// default fetchAllowedPhones/addAllowedPhone/removeAllowedPhone to the real HTTP
// functions — every test must override them to a no-op, or it'll fire a real
// network call against the live backend and hang the test sandbox.
Future<List<AllowedPhoneSummary>> _noAllowedPhones(String key) async => [];
Future<void> _noopAdd(String key, String number, String? note) async {}
Future<void> _noopRemove(String key, String number) async {}
Future<List<LoginEvent>> _noLogins(String key) async => [];

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void main() {
  group('AdminLoginScreen', () {
    testWidgets('a correct key navigates to the dashboard', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminLoginScreen(
          fetchOfficers: (key) async => [_officer],
          fetchSupportTickets: (key) async => [_openTicket],
          resolveTicket: (key, id) async {},
          fetchAllowedPhones: _noAllowedPhones,
          addAllowedPhone: _noopAdd,
          removeAllowedPhone: _noopRemove,
          fetchLoginHistory: _noLogins,
        )),
      );

      await tester.enterText(find.byKey(const Key('adminKeyField')), 'correct-key');
      await tester.tap(find.byKey(const Key('adminUnlockButton')));
      await tester.pumpAndSettle();

      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.byKey(const Key('adminOfficersList')), findsOneWidget);
    });

    testWidgets('an incorrect key shows an error and stays on the login screen', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminLoginScreen(
          fetchOfficers: (key) async => throw Exception('Incorrect admin key.'),
          fetchSupportTickets: (key) async => [],
          resolveTicket: (key, id) async {},
          fetchAllowedPhones: _noAllowedPhones,
          addAllowedPhone: _noopAdd,
          removeAllowedPhone: _noopRemove,
          fetchLoginHistory: _noLogins,
        )),
      );

      await tester.enterText(find.byKey(const Key('adminKeyField')), 'wrong-key');
      await tester.tap(find.byKey(const Key('adminUnlockButton')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Incorrect admin key'), findsOneWidget);
      expect(find.text('Admin Dashboard'), findsNothing);
    });

    testWidgets('rejects an empty key without calling the service', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(AdminLoginScreen(
          fetchOfficers: (key) async {
            called = true;
            return [];
          },
          fetchSupportTickets: (key) async => [],
          resolveTicket: (key, id) async {},
          fetchAllowedPhones: _noAllowedPhones,
          addAllowedPhone: _noopAdd,
          removeAllowedPhone: _noopRemove,
          fetchLoginHistory: _noLogins,
        )),
      );

      await tester.tap(find.byKey(const Key('adminUnlockButton')));
      await tester.pumpAndSettle();

      expect(called, isFalse);
      expect(find.textContaining('Enter the admin key'), findsOneWidget);
    });
  });

  group('AdminDashboardScreen', () {
    testWidgets('shows officer progress including one who never opened the app', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminDashboardScreen(
          adminKey: 'key',
          fetchOfficers: (key) async => [_officer, _neverOpenedOfficer],
          fetchSupportTickets: (key) async => [],
          resolveTicket: (key, id) async {},
          fetchAllowedPhones: _noAllowedPhones,
          addAllowedPhone: _noopAdd,
          removeAllowedPhone: _noopRemove,
          fetchLoginHistory: _noLogins,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Officers (2)'), findsOneWidget);
      expect(find.textContaining('Lt Col A Verma'), findsOneWidget);
      expect(find.textContaining('Transition Readiness: 72/100'), findsOneWidget);
      expect(find.textContaining("Hasn't opened the app"), findsOneWidget);
    });

    testWidgets('resolving a ticket calls the service and refreshes the list', (tester) async {
      var resolvedId = '';
      var fetchCount = 0;
      await tester.pumpWidget(
        _wrap(AdminDashboardScreen(
          adminKey: 'key',
          fetchOfficers: (key) async => [],
          fetchSupportTickets: (key) async {
            fetchCount++;
            return fetchCount == 1 ? [_openTicket] : [];
          },
          resolveTicket: (key, id) async => resolvedId = id,
          fetchAllowedPhones: _noAllowedPhones,
          addAllowedPhone: _noopAdd,
          removeAllowedPhone: _noopRemove,
          fetchLoginHistory: _noLogins,
        )),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Support Tickets (1 open)'));
      await tester.pumpAndSettle();

      expect(find.textContaining('JD Match hangs on my PDF.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('resolveTicketButton_ticket-1')));
      await tester.pumpAndSettle();

      expect(resolvedId, 'ticket-1');
      expect(fetchCount, 2);
    });

    testWidgets('shows an error if loading fails', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminDashboardScreen(
          adminKey: 'key',
          fetchOfficers: (key) async => throw Exception('network down'),
          fetchSupportTickets: (key) async => [],
          resolveTicket: (key, id) async {},
          fetchAllowedPhones: _noAllowedPhones,
          addAllowedPhone: _noopAdd,
          removeAllowedPhone: _noopRemove,
          fetchLoginHistory: _noLogins,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('network down'), findsOneWidget);
    });

    testWidgets('shows allowed numbers and adding one calls the service and refreshes',
        (tester) async {
      String? capturedNumber;
      String? capturedNote;
      var fetchCount = 0;
      await tester.pumpWidget(
        _wrap(AdminDashboardScreen(
          adminKey: 'key',
          fetchOfficers: (key) async => [],
          fetchSupportTickets: (key) async => [],
          resolveTicket: (key, id) async {},
          fetchAllowedPhones: (key) async {
            fetchCount++;
            return fetchCount == 1 ? [_allowedPhone] : [_allowedPhone, _allowedPhone];
          },
          addAllowedPhone: (key, number, note) async {
            capturedNumber = number;
            capturedNote = note;
          },
          removeAllowedPhone: _noopRemove,
          fetchLoginHistory: _noLogins,
        )),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Allowed Numbers (1)'));
      await tester.pumpAndSettle();

      expect(find.textContaining('9876543210'), findsWidgets);
      expect(find.textContaining('Cousin'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('newAllowedPhoneField')), '9998887777');
      await tester.enterText(find.byKey(const Key('newAllowedPhoneNoteField')), 'Friend');
      await tester.tap(find.byKey(const Key('addAllowedPhoneButton')));
      await tester.pumpAndSettle();

      expect(capturedNumber, '9998887777');
      expect(capturedNote, 'Friend');
      expect(fetchCount, 2);
    });

    testWidgets('removing an allowed number calls the service', (tester) async {
      String? removedNumber;
      await tester.pumpWidget(
        _wrap(AdminDashboardScreen(
          adminKey: 'key',
          fetchOfficers: (key) async => [],
          fetchSupportTickets: (key) async => [],
          resolveTicket: (key, id) async {},
          fetchAllowedPhones: (key) async => [_allowedPhone],
          addAllowedPhone: _noopAdd,
          removeAllowedPhone: (key, number) async => removedNumber = number,
          fetchLoginHistory: _noLogins,
        )),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Allowed Numbers (1)'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('removeAllowedPhoneButton_9876543210')));
      await tester.pumpAndSettle();

      expect(removedNumber, '9876543210');
    });

    testWidgets('shows login history under the matching officer, flagging many distinct devices',
        (tester) async {
      final logins = [
        LoginEvent(
          officerId: 'officer-1',
          mobileNumber: '9876543210',
          userAgent:
              'Mozilla/5.0 (Windows NT 10.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36',
          country: 'IN',
          city: 'Delhi',
          loggedInAt: DateTime(2026, 1, 10, 9),
        ),
        LoginEvent(
          officerId: 'officer-1',
          mobileNumber: '9876543210',
          userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0) AppleWebKit/605.1.15 Safari/604.1',
          country: 'CA',
          city: 'Toronto',
          loggedInAt: DateTime(2026, 1, 12, 14),
        ),
        LoginEvent(
          officerId: 'officer-1',
          mobileNumber: '9876543210',
          userAgent: 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
          country: 'US',
          city: 'Boston',
          loggedInAt: DateTime(2026, 1, 13, 8),
        ),
      ];

      await tester.pumpWidget(
        _wrap(AdminDashboardScreen(
          adminKey: 'key',
          fetchOfficers: (key) async => [_officer],
          fetchSupportTickets: (key) async => [],
          resolveTicket: (key, id) async {},
          fetchAllowedPhones: _noAllowedPhones,
          addAllowedPhone: _noopAdd,
          removeAllowedPhone: _noopRemove,
          fetchLoginHistory: (key) async => logins,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('3 login(s) from 3 distinct device(s)'), findsOneWidget);
      expect(find.textContaining('Chrome on Windows'), findsOneWidget);
      expect(find.textContaining('Safari on iOS'), findsOneWidget);
      expect(find.textContaining('Toronto, CA'), findsOneWidget);
    });
  });
}
