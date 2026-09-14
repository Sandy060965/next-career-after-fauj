import 'dart:convert';

import 'package:http/http.dart' as http;

import 'admin_officer_summary.dart';
import 'allowed_email_summary.dart';
import 'allowed_phone_summary.dart';
import 'course_submission_summary.dart';
import 'login_event.dart';
import 'phone_recovery_grant.dart';
import 'support_ticket_summary.dart';

const _baseUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');
// Bounds a stalled connection so it surfaces a clear error instead of
// leaving the request pending forever with no feedback.
const _requestTimeout = Duration(seconds: 30);

class AdminException implements Exception {
  AdminException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<http.Response> _post(String path, String adminKey, [Map<String, dynamic> body = const {}]) {
  return http
      .post(
        Uri.parse('$_baseUrl$path'),
        headers: {
          'content-type': 'application/json',
          'x-app-key': _appSharedKey,
          'x-admin-key': adminKey,
        },
        body: jsonEncode(body),
      )
      .timeout(_requestTimeout);
}

typedef FetchAdminOfficers = Future<List<AdminOfficerSummary>> Function(String adminKey);
typedef FetchAdminSupportTickets = Future<List<SupportTicketSummary>> Function(String adminKey);
typedef ResolveSupportTicket = Future<void> Function(String adminKey, String ticketId);

Future<List<AdminOfficerSummary>> httpFetchAdminOfficers(String adminKey) async {
  final response = await _post('/admin/officers', adminKey);
  if (response.statusCode == 401) {
    throw AdminException('Incorrect admin key.');
  }
  if (response.statusCode != 200) {
    throw AdminException('Could not load officers (${response.statusCode}).');
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return (json['officers'] as List)
      .map((e) => AdminOfficerSummary.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<List<SupportTicketSummary>> httpFetchAdminSupportTickets(String adminKey) async {
  final response = await _post('/admin/support-tickets', adminKey);
  if (response.statusCode == 401) {
    throw AdminException('Incorrect admin key.');
  }
  if (response.statusCode != 200) {
    throw AdminException('Could not load support tickets (${response.statusCode}).');
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return (json['tickets'] as List)
      .map((e) => SupportTicketSummary.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<void> httpResolveSupportTicket(String adminKey, String ticketId) async {
  final response = await _post('/admin/resolve-ticket', adminKey, {'id': ticketId});
  if (response.statusCode != 200) {
    throw AdminException('Could not resolve this ticket (${response.statusCode}).');
  }
}

typedef LinkOfficerEmail = Future<void> Function(String adminKey, String officerId, String email);

Future<void> httpLinkOfficerEmail(String adminKey, String officerId, String email) async {
  final response = await _post('/admin/link-officer-email', adminKey, {
    'officerId': officerId,
    'email': email,
  });
  if (response.statusCode == 409) {
    throw AdminException('That email is already linked to a different officer account.');
  }
  if (response.statusCode != 200) {
    throw AdminException('Could not link this email (${response.statusCode}).');
  }
}

typedef FetchAllowedPhones = Future<List<AllowedPhoneSummary>> Function(String adminKey);
typedef AddAllowedPhone = Future<void> Function(String adminKey, String mobileNumber, String? note);
typedef RemoveAllowedPhone = Future<void> Function(String adminKey, String mobileNumber);

Future<List<AllowedPhoneSummary>> httpFetchAllowedPhones(String adminKey) async {
  final response = await _post('/admin/allowed-phones', adminKey);
  if (response.statusCode == 401) {
    throw AdminException('Incorrect admin key.');
  }
  if (response.statusCode != 200) {
    throw AdminException('Could not load allowed numbers (${response.statusCode}).');
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return (json['phones'] as List)
      .map((e) => AllowedPhoneSummary.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<void> httpAddAllowedPhone(String adminKey, String mobileNumber, String? note) async {
  final response = await _post('/admin/add-allowed-phone', adminKey, {
    'mobileNumber': mobileNumber,
    if (note != null && note.isNotEmpty) 'note': note,
  });
  if (response.statusCode != 200) {
    throw AdminException('Could not add this number (${response.statusCode}).');
  }
}

Future<void> httpRemoveAllowedPhone(String adminKey, String mobileNumber) async {
  final response =
      await _post('/admin/remove-allowed-phone', adminKey, {'mobileNumber': mobileNumber});
  if (response.statusCode != 200) {
    throw AdminException('Could not remove this number (${response.statusCode}).');
  }
}

typedef FetchAllowedEmails = Future<List<AllowedEmailSummary>> Function(String adminKey);
typedef AddAllowedEmail = Future<void> Function(String adminKey, String email, String? note);
typedef RemoveAllowedEmail = Future<void> Function(String adminKey, String email);

Future<List<AllowedEmailSummary>> httpFetchAllowedEmails(String adminKey) async {
  final response = await _post('/admin/allowed-emails', adminKey);
  if (response.statusCode == 401) {
    throw AdminException('Incorrect admin key.');
  }
  if (response.statusCode != 200) {
    throw AdminException('Could not load allowed emails (${response.statusCode}).');
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return (json['emails'] as List)
      .map((e) => AllowedEmailSummary.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<void> httpAddAllowedEmail(String adminKey, String email, String? note) async {
  final response = await _post('/admin/add-allowed-email', adminKey, {
    'email': email,
    if (note != null && note.isNotEmpty) 'note': note,
  });
  if (response.statusCode != 200) {
    throw AdminException('Could not add this email (${response.statusCode}).');
  }
}

Future<void> httpRemoveAllowedEmail(String adminKey, String email) async {
  final response = await _post('/admin/remove-allowed-email', adminKey, {'email': email});
  if (response.statusCode != 200) {
    throw AdminException('Could not remove this email (${response.statusCode}).');
  }
}

typedef FetchPhoneRecoveryGrants = Future<List<PhoneRecoveryGrant>> Function(String adminKey);
typedef GrantPhoneRecovery = Future<void> Function(String adminKey, String mobileNumber, String? note);
typedef RevokePhoneRecoveryGrant = Future<void> Function(String adminKey, String id);

Future<List<PhoneRecoveryGrant>> httpFetchPhoneRecoveryGrants(String adminKey) async {
  final response = await _post('/admin/phone-recovery-grants', adminKey);
  if (response.statusCode == 401) {
    throw AdminException('Incorrect admin key.');
  }
  if (response.statusCode != 200) {
    throw AdminException('Could not load phone recovery grants (${response.statusCode}).');
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return (json['grants'] as List)
      .map((e) => PhoneRecoveryGrant.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<void> httpGrantPhoneRecovery(String adminKey, String mobileNumber, String? note) async {
  final response = await _post('/admin/grant-phone-recovery', adminKey, {
    'mobileNumber': mobileNumber,
    if (note != null && note.isNotEmpty) 'note': note,
  });
  if (response.statusCode != 200) {
    throw AdminException('Could not grant phone recovery (${response.statusCode}).');
  }
}

Future<void> httpRevokePhoneRecoveryGrant(String adminKey, String id) async {
  final response = await _post('/admin/revoke-phone-recovery', adminKey, {'id': id});
  if (response.statusCode != 200) {
    throw AdminException('Could not revoke this grant (${response.statusCode}).');
  }
}

typedef FetchLoginHistory = Future<List<LoginEvent>> Function(String adminKey);

Future<List<LoginEvent>> httpFetchLoginHistory(String adminKey) async {
  final response = await _post('/admin/login-history', adminKey);
  if (response.statusCode == 401) {
    throw AdminException('Incorrect admin key.');
  }
  if (response.statusCode != 200) {
    throw AdminException('Could not load login history (${response.statusCode}).');
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return (json['logins'] as List)
      .map((e) => LoginEvent.fromJson(e as Map<String, dynamic>))
      .toList();
}

typedef FetchCourseSubmissions = Future<List<CourseSubmissionSummary>> Function(String adminKey);
typedef ApproveCourseSubmission = Future<void> Function(String adminKey, String id);
typedef RejectCourseSubmission = Future<void> Function(String adminKey, String id);

Future<List<CourseSubmissionSummary>> httpFetchCourseSubmissions(String adminKey) async {
  final response = await _post('/admin/course-submissions', adminKey);
  if (response.statusCode == 401) {
    throw AdminException('Incorrect admin key.');
  }
  if (response.statusCode != 200) {
    throw AdminException('Could not load course submissions (${response.statusCode}).');
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return (json['submissions'] as List)
      .map((e) => CourseSubmissionSummary.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<void> httpApproveCourseSubmission(String adminKey, String id) async {
  final response = await _post('/admin/approve-course-submission', adminKey, {'id': id});
  if (response.statusCode != 200) {
    throw AdminException('Could not approve this submission (${response.statusCode}).');
  }
}

Future<void> httpRejectCourseSubmission(String adminKey, String id) async {
  final response = await _post('/admin/reject-course-submission', adminKey, {'id': id});
  if (response.statusCode != 200) {
    throw AdminException('Could not reject this submission (${response.statusCode}).');
  }
}
