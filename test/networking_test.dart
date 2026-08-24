import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/networking/network_browse_screen.dart';
import 'package:next_career_after_fauj/features/networking/network_directory_screen.dart';
import 'package:next_career_after_fauj/features/networking/network_models.dart';
import 'package:next_career_after_fauj/features/networking/network_my_requests_screen.dart';
import 'package:next_career_after_fauj/features/networking/network_opt_in_screen.dart';
import 'package:next_career_after_fauj/features/networking/network_queue_screen.dart';
import 'package:next_career_after_fauj/features/networking/network_service.dart'
    show NetworkService, NetworkServiceException;
import 'package:provider/provider.dart';

class _FakeNetworkService extends NetworkService {
  _FakeNetworkService({
    this.listing,
    this.contacts = const [],
    this.incomingRequests = const [],
    this.outgoingRequests = const [],
    this.optInError,
    this.requestError,
  }) : super(sessionToken: 'test-token');

  NetworkContact? listing;
  List<NetworkContact> contacts;
  List<IncomingRequest> incomingRequests;
  List<OutgoingRequest> outgoingRequests;
  final Object? optInError;
  final Object? requestError;

  final List<Map<String, dynamic>> optInCalls = [];
  bool optedOut = false;
  final List<String> respondedIds = [];
  final List<bool> respondedAccept = [];
  final List<Map<String, dynamic>> connectionRequests = [];

  @override
  Future<void> optIn({
    required NetworkChannel channel,
    required String displayName,
    required String email,
    required CallFrequency callFrequency,
    required List<CallSlot> callSlots,
    required bool offersReferrals,
    String? vertical,
    String? city,
    String? currentCompany,
  }) async {
    if (optInError != null) throw optInError!;
    optInCalls.add({
      'channel': channel,
      'displayName': displayName,
      'email': email,
      'callFrequency': callFrequency,
      'callSlots': callSlots,
      'offersReferrals': offersReferrals,
    });
  }

  @override
  Future<void> optOut() async {
    optedOut = true;
  }

  @override
  Future<NetworkContact?> myListing() async => listing;

  @override
  Future<List<NetworkContact>> browse({NetworkChannel? channel, String? vertical, String? city}) async =>
      contacts;

  @override
  Future<void> requestConnection({
    required String volunteerOfficerId,
    required AskType askType,
    required String requesterDisplayName,
    int? slotIndex,
    String? requesterNote,
  }) async {
    if (requestError != null) throw requestError!;
    connectionRequests.add({
      'volunteerOfficerId': volunteerOfficerId,
      'askType': askType,
      'slotIndex': slotIndex,
    });
  }

  @override
  Future<void> respond({required String requestId, required bool accept}) async {
    respondedIds.add(requestId);
    respondedAccept.add(accept);
  }

  @override
  Future<List<IncomingRequest>> myQueue() async => incomingRequests;

  @override
  Future<List<OutgoingRequest>> myRequests() async => outgoingRequests;
}

const _contact = NetworkContact(
  officerId: 'officer-9',
  channel: NetworkChannel.transitioned,
  displayName: 'Col B Rao (Retd)',
  callFrequency: CallFrequency.weekly,
  callSlots: [
    CallSlot(dayOfWeek: 'Wed', startTime: '19:00'),
    CallSlot(dayOfWeek: 'Sat', startTime: '10:00'),
  ],
  offersReferrals: true,
  vertical: 'Operations',
  city: 'Pune',
  currentCompany: 'Acme Corp',
  slotAvailability: [true, false],
);

const _contactJson = {
  'officerId': 'officer-9',
  'channel': 'transitioned',
  'displayName': 'Col B Rao (Retd)',
  'callFrequency': 'weekly',
  'callSlots': [
    {'dayOfWeek': 'Wed', 'startTime': '19:00'},
    {'dayOfWeek': 'Sat', 'startTime': '10:00'},
  ],
  'offersReferrals': true,
  'vertical': 'Operations',
  'city': 'Pune',
  'currentCompany': 'Acme Corp',
  'slotAvailability': [true, false],
};

ProfileRepository _repositoryWithProfile() {
  return ProfileRepository()
    ..saveProfile(
      OfficerProfile(
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
        segment: OfficerSegment.pmr,
        cvFileName: 'resume.pdf',
        cvExtractedText: 'Sample CV text',
      ),
    );
}

Widget _wrap(Widget child, {ProfileRepository? repository}) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository ?? _repositoryWithProfile(),
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

void main() {
  group('model serialization round-trips', () {
    test('CallSlot', () {
      const slot = CallSlot(dayOfWeek: 'Mon', startTime: '09:30');
      final restored = CallSlot.fromJson(slot.toJson());
      expect(restored.dayOfWeek, 'Mon');
      expect(restored.startTime, '09:30');
    });

    test('NetworkContact', () {
      final restored = NetworkContact.fromJson(_contactJson);
      expect(restored.officerId, _contact.officerId);
      expect(restored.channel, NetworkChannel.transitioned);
      expect(restored.callFrequency, CallFrequency.weekly);
      expect(restored.callSlots.length, 2);
      expect(restored.callSlots[0].dayOfWeek, 'Wed');
      expect(restored.offersReferrals, true);
      expect(restored.slotAvailability, [true, false]);
    });

    test('NetworkContact.fromJson never carries an email unless present', () {
      final restored = NetworkContact.fromJson(_contactJson);
      expect(restored.email, isNull);

      final withEmail = NetworkContact.fromJson({..._contactJson, 'email': 'b.rao@example.com'});
      expect(withEmail.email, 'b.rao@example.com');
    });

    test('IncomingRequest', () {
      final restored = IncomingRequest.fromJson({
        'id': 'req-1',
        'requesterDisplayName': 'Maj C Singh',
        'requesterNote': null,
        'askType': 'call',
        'slotIndex': 0,
        'createdAt': '2026-01-05T10:00:00.000Z',
      });
      expect(restored.id, 'req-1');
      expect(restored.askType, AskType.call);
      expect(restored.slotIndex, 0);
    });

    test('OutgoingRequest reveals email only once accepted', () {
      final pending = OutgoingRequest.fromJson({
        'id': 'req-2',
        'volunteerDisplayName': 'Col B Rao (Retd)',
        'volunteerEmail': null,
        'askType': 'referral',
        'status': 'pending',
        'createdAt': '2026-01-05T10:00:00.000Z',
      });
      expect(pending.volunteerEmail, isNull);
      expect(pending.status, ConnectionRequestStatus.pending);

      final accepted = OutgoingRequest.fromJson({
        'id': 'req-2',
        'volunteerDisplayName': 'Col B Rao (Retd)',
        'volunteerEmail': 'b.rao@example.com',
        'askType': 'referral',
        'status': 'accepted',
        'createdAt': '2026-01-05T10:00:00.000Z',
      });
      expect(accepted.volunteerEmail, 'b.rao@example.com');
      expect(accepted.status, ConnectionRequestStatus.accepted);
    });
  });

  group('NetworkDirectoryScreen', () {
    testWidgets('shows not-listed state when the officer has no listing', (tester) async {
      final service = _FakeNetworkService(listing: null);
      await tester.pumpWidget(_wrap(NetworkDirectoryScreen(networkService: service)));
      await tester.pumpAndSettle();

      expect(find.text("You're not listed yet"), findsOneWidget);
      expect(find.byKey(const Key('becomeVolunteerButton')), findsOneWidget);
      expect(find.byKey(const Key('myQueueButton')), findsNothing);
    });

    testWidgets('shows listing details and lets the officer remove themselves', (tester) async {
      final service = _FakeNetworkService(listing: _contact);
      await tester.pumpWidget(_wrap(NetworkDirectoryScreen(networkService: service)));
      await tester.pumpAndSettle();

      expect(find.textContaining("You're listed as"), findsOneWidget);
      expect(find.byKey(const Key('myQueueButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('optOutButton')));
      await tester.pumpAndSettle();

      expect(service.optedOut, isTrue);
      expect(find.text("You're not listed yet"), findsOneWidget);
      expect(find.text('Removed from the directory'), findsOneWidget);
    });
  });

  group('NetworkOptInScreen', () {
    testWidgets('rejects an empty display name without calling optIn', (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = _FakeNetworkService();
      await tester.pumpWidget(_wrap(NetworkOptInScreen(networkService: service)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('displayNameField')), '');
      await tester.tap(find.byKey(const Key('saveListingButton')));
      await tester.pump();

      expect(find.text('Required'), findsWidgets);
      expect(service.optInCalls, isEmpty);
    });

    testWidgets('saves with the pre-filled name/email and default weekly single slot',
        (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = _FakeNetworkService();
      await tester.pumpWidget(_wrap(NetworkOptInScreen(networkService: service)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveListingButton')));
      await tester.pumpAndSettle();

      expect(service.optInCalls, hasLength(1));
      final call = service.optInCalls.single;
      expect(call['displayName'], 'Lt Col A Verma');
      expect(call['email'], 'a.verma@example.com');
      expect(call['callFrequency'], CallFrequency.weekly);
      expect((call['callSlots'] as List<CallSlot>).length, 1);
      expect(call['offersReferrals'], isFalse);
    });

    testWidgets('switching to the transitioned channel reveals company field and referrals switch',
        (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = _FakeNetworkService();
      await tester.pumpWidget(_wrap(NetworkOptInScreen(networkService: service)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('companyField')), findsNothing);
      expect(find.byKey(const Key('offersReferralsSwitch')), findsNothing);

      await tester.tap(find.byKey(const Key('channel_transitioned')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('companyField')), findsOneWidget);
      expect(find.byKey(const Key('offersReferralsSwitch')), findsOneWidget);

      await tester.tap(find.byKey(const Key('offersReferralsSwitch')));
      await tester.tap(find.byKey(const Key('saveListingButton')));
      await tester.pumpAndSettle();

      expect(service.optInCalls.single['offersReferrals'], isTrue);
    });

    testWidgets('selecting 2 slots adds a second day/time row', (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = _FakeNetworkService();
      await tester.pumpWidget(_wrap(NetworkOptInScreen(networkService: service)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('slotDayDropdown_1')), findsNothing);

      await tester.tap(find.text('2 slots'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('slotDayDropdown_1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('saveListingButton')));
      await tester.pumpAndSettle();

      expect((service.optInCalls.single['callSlots'] as List<CallSlot>).length, 2);
    });

    testWidgets('shows an error message when saving the listing fails', (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = _FakeNetworkService(optInError: NetworkServiceException('Could not save'));
      await tester.pumpWidget(_wrap(NetworkOptInScreen(networkService: service)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveListingButton')));
      await tester.pumpAndSettle();

      expect(find.text('Could not save'), findsOneWidget);
    });
  });

  group('NetworkBrowseScreen', () {
    testWidgets('lists volunteers and requests an available call slot', (tester) async {
      final service = _FakeNetworkService(contacts: [_contact]);
      await tester.pumpWidget(_wrap(NetworkBrowseScreen(networkService: service)));
      await tester.pumpAndSettle();

      expect(find.text('Col B Rao (Retd)'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('slotChip_Wed_19:00')));
      await tester.pumpAndSettle();

      expect(service.connectionRequests, hasLength(1));
      expect(service.connectionRequests.single['askType'], AskType.call);
      expect(service.connectionRequests.single['slotIndex'], 0);
      expect(find.text('Call request sent'), findsOneWidget);
    });

    testWidgets('a booked slot cannot be tapped', (tester) async {
      final service = _FakeNetworkService(contacts: [_contact]);
      await tester.pumpWidget(_wrap(NetworkBrowseScreen(networkService: service)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('slotChip_Sat_10:00')));
      await tester.pumpAndSettle();

      expect(service.connectionRequests, isEmpty);
    });

    testWidgets('requests a referral from a volunteer that offers them', (tester) async {
      final service = _FakeNetworkService(contacts: [_contact]);
      await tester.pumpWidget(_wrap(NetworkBrowseScreen(networkService: service)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('requestReferral_officer-9')));
      await tester.pumpAndSettle();

      expect(service.connectionRequests.single['askType'], AskType.referral);
      expect(find.text('Referral request sent'), findsOneWidget);
    });

    testWidgets('shows an error message when a request fails, e.g. the weekly referral cap',
        (tester) async {
      final service = _FakeNetworkService(
        contacts: [_contact],
        requestError: NetworkServiceException('Only 1 referral request per week'),
      );
      await tester.pumpWidget(_wrap(NetworkBrowseScreen(networkService: service)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('requestReferral_officer-9')));
      await tester.pumpAndSettle();

      expect(find.text('Only 1 referral request per week'), findsOneWidget);
    });
  });

  group('NetworkQueueScreen', () {
    testWidgets('accepting an incoming request calls respond with accept=true', (tester) async {
      final service = _FakeNetworkService(
        incomingRequests: [
          IncomingRequest(
            id: 'req-5',
            requesterDisplayName: 'Maj C Singh',
            askType: AskType.call,
            slotIndex: 0,
            createdAt: DateTime(2026, 1, 5),
          ),
        ],
      );
      await tester.pumpWidget(_wrap(NetworkQueueScreen(networkService: service)));
      await tester.pumpAndSettle();

      expect(find.text('Maj C Singh'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('acceptRequest_req-5')));
      await tester.pumpAndSettle();

      expect(service.respondedIds, ['req-5']);
      expect(service.respondedAccept, [true]);
      expect(find.text('Accepted'), findsOneWidget);
    });

    testWidgets('declining calls respond with accept=false', (tester) async {
      final service = _FakeNetworkService(
        incomingRequests: [
          IncomingRequest(
            id: 'req-6',
            requesterDisplayName: 'Maj D Rao',
            askType: AskType.referral,
            createdAt: DateTime(2026, 1, 5),
          ),
        ],
      );
      await tester.pumpWidget(_wrap(NetworkQueueScreen(networkService: service)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('declineRequest_req-6')));
      await tester.pumpAndSettle();

      expect(service.respondedIds, ['req-6']);
      expect(service.respondedAccept, [false]);
      expect(find.text('Declined'), findsOneWidget);
    });
  });

  group('NetworkMyRequestsScreen', () {
    testWidgets('reveals the volunteer email only once the request is accepted', (tester) async {
      final service = _FakeNetworkService(
        outgoingRequests: [
          OutgoingRequest(
            id: 'req-7',
            volunteerDisplayName: 'Col B Rao (Retd)',
            askType: AskType.call,
            status: ConnectionRequestStatus.pending,
            createdAt: DateTime(2026, 1, 5),
          ),
          OutgoingRequest(
            id: 'req-8',
            volunteerDisplayName: 'Col E Menon (Retd)',
            volunteerEmail: 'e.menon@example.com',
            askType: AskType.referral,
            status: ConnectionRequestStatus.accepted,
            createdAt: DateTime(2026, 1, 5),
          ),
        ],
      );
      await tester.pumpWidget(_wrap(NetworkMyRequestsScreen(networkService: service)));
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('e.menon@example.com'), findsOneWidget);
      expect(find.byKey(const ValueKey('copyEmail_req-8')), findsOneWidget);
      expect(find.byKey(const ValueKey('copyEmail_req-7')), findsNothing);
    });
  });
}
