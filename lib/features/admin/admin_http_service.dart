import 'dart:convert';

import 'package:http/http.dart' as http;

import 'admin_officer_summary.dart';
import 'support_ticket_summary.dart';

const _baseUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');

class AdminException implements Exception {
  AdminException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<http.Response> _post(String path, String adminKey, [Map<String, dynamic> body = const {}]) {
  return http.post(
    Uri.parse('$_baseUrl$path'),
    headers: {
      'content-type': 'application/json',
      'x-app-key': _appSharedKey,
      'x-admin-key': adminKey,
    },
    body: jsonEncode(body),
  );
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
