import '../../core/services/authenticated_http.dart';
import '../../core/services/profile_repository.dart';

class SupportTicketException implements Exception {
  SupportTicketException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef SubmitSupportTicket = Future<void> Function({
  required ProfileRepository repository,
  required String message,
});

Future<void> httpSubmitSupportTicket({
  required ProfileRepository repository,
  required String message,
}) async {
  final response = await authenticatedPost(repository, '/support-ticket', {'message': message});
  if (response.statusCode != 200) {
    throw SupportTicketException(
      "Couldn't send your message (${response.statusCode}). Please try again.",
    );
  }
}
