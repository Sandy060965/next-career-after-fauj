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

/// The officer's own mentor pledge — pure data capture, so this is limited
/// to submitting, withdrawing, and reading back their own pledge. Uses
/// [authenticatedPost] rather than a fixed token so a mid-session-expired
/// access token is silently refreshed instead of failing outright.
class NetworkService {
  const NetworkService({required this.profileRepository});

  final ProfileRepository profileRepository;

  Future<void> optIn({
    required String displayName,
    required String email,
    required CallFrequency callFrequency,
    required int sessionMinutes,
    String? vertical,
    String? city,
    String? currentCompany,
    DateTime? joiningDate,
  }) async {
    final response = await _post('/network/opt-in', {
      'displayName': displayName,
      'email': email,
      'vertical': vertical,
      'city': city,
      'currentCompany': currentCompany,
      'joiningDate': joiningDate?.toIso8601String(),
      'callFrequency': callFrequency.wireValue,
      'sessionMinutes': sessionMinutes,
    });
    _throwIfError(response, fallback: 'Could not save your pledge.');
  }

  Future<void> optOut() async {
    final response = await _post('/network/opt-out', {});
    _throwIfError(response, fallback: 'Could not withdraw your pledge.');
  }

  Future<MentorPledge?> myListing() async {
    final response = await _post('/network/my-listing', {});
    _throwIfError(response, fallback: 'Could not load your pledge.');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final listing = json['listing'];
    return listing == null ? null : MentorPledge.fromJson(listing as Map<String, dynamic>);
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
