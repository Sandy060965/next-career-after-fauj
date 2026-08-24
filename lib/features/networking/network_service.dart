import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/services/authenticated_http.dart';
import '../../core/services/profile_repository.dart';
import 'network_models.dart';

class NetworkServiceException implements Exception {
  NetworkServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The officer's own view into the networking directory. Every call needs
/// the officer's session — unlike the other HTTP services in this app, this
/// one always acts as (or on behalf of) a specific, authenticated officer,
/// since it reads and writes other officers' data too. Uses
/// [authenticatedPost] rather than a fixed token so a mid-session-expired
/// access token is silently refreshed instead of failing outright.
class NetworkService {
  const NetworkService({required this.profileRepository});

  final ProfileRepository profileRepository;

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
    final response = await _post('/network/opt-in', {
      'channel': channel.wireValue,
      'displayName': displayName,
      'email': email,
      'vertical': vertical,
      'city': city,
      'currentCompany': currentCompany,
      'callFrequency': callFrequency.wireValue,
      'callSlots': callSlots.map((s) => s.toJson()).toList(),
      'offersReferrals': offersReferrals,
    });
    _throwIfError(response, fallback: 'Could not save your listing.');
  }

  Future<void> optOut() async {
    final response = await _post('/network/opt-out', {});
    _throwIfError(response, fallback: 'Could not remove your listing.');
  }

  Future<NetworkContact?> myListing() async {
    final response = await _post('/network/my-listing', {});
    _throwIfError(response, fallback: 'Could not load your listing.');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final listing = json['listing'];
    return listing == null ? null : NetworkContact.fromJson(listing as Map<String, dynamic>);
  }

  Future<List<NetworkContact>> browse({NetworkChannel? channel, String? vertical, String? city}) async {
    final response = await _post('/network/browse', {
      if (channel != null) 'channel': channel.wireValue,
      if (vertical != null) 'vertical': vertical,
      if (city != null) 'city': city,
    });
    _throwIfError(response, fallback: 'Could not load the directory.');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['contacts'] as List)
        .map((e) => NetworkContact.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> requestConnection({
    required String volunteerOfficerId,
    required AskType askType,
    required String requesterDisplayName,
    int? slotIndex,
    String? requesterNote,
  }) async {
    final response = await _post('/network/request', {
      'volunteerOfficerId': volunteerOfficerId,
      'askType': askType.wireValue,
      'slotIndex': slotIndex,
      'requesterDisplayName': requesterDisplayName,
      'requesterNote': requesterNote,
    });
    _throwIfError(response, fallback: 'Could not send that request.');
  }

  Future<void> respond({required String requestId, required bool accept}) async {
    final response = await _post('/network/respond', {'requestId': requestId, 'accept': accept});
    _throwIfError(response, fallback: 'Could not respond to that request.');
  }

  Future<List<IncomingRequest>> myQueue() async {
    final response = await _post('/network/my-queue', {});
    _throwIfError(response, fallback: 'Could not load your request queue.');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['requests'] as List)
        .map((e) => IncomingRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OutgoingRequest>> myRequests() async {
    final response = await _post('/network/my-requests', {});
    _throwIfError(response, fallback: 'Could not load your sent requests.');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['requests'] as List)
        .map((e) => OutgoingRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) {
    return authenticatedPost(profileRepository, path, body);
  }

  void _throwIfError(http.Response response, {required String fallback}) {
    if (response.statusCode == 200) return;
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw NetworkServiceException(json['error'] as String? ?? fallback);
    } on NetworkServiceException {
      rethrow;
    } catch (_) {
      throw NetworkServiceException(fallback);
    }
  }
}
