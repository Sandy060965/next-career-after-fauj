import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/admin/admin_dashboard_screen.dart';
import 'package:next_career_after_fauj/features/admin/admin_login_screen.dart';
import 'package:next_career_after_fauj/features/admin/admin_officer_summary.dart';
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

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void main() {
  group('AdminLoginScreen', () {
    testWidgets('a correct key navigates to the dashboard', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminLoginScreen(
          fetchOfficers: (key) async => [_officer],
          fetchSupportTickets: (key) async => [_openTicket],
          resolveTicket: (key, id) async {},
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
        )),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('network down'), findsOneWidget);
    });
  });
}
