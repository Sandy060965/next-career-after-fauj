import 'package:flutter/material.dart';

import 'admin_dashboard_screen.dart';
import 'admin_http_service.dart';

/// Gate for the admin dashboard — not part of the officer-facing app, not
/// linked from anywhere in the nav, reached only by typing the /admin URL
/// directly. The admin key is held in memory only for this screen's
/// lifetime (never persisted to disk), so it must be re-entered each visit.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({
    super.key,
    this.fetchOfficers = httpFetchAdminOfficers,
    this.linkOfficerEmail = httpLinkOfficerEmail,
    this.fetchSupportTickets = httpFetchAdminSupportTickets,
    this.resolveTicket = httpResolveSupportTicket,
    this.fetchAllowedPhones = httpFetchAllowedPhones,
    this.addAllowedPhone = httpAddAllowedPhone,
    this.removeAllowedPhone = httpRemoveAllowedPhone,
    this.fetchAllowedEmails = httpFetchAllowedEmails,
    this.addAllowedEmail = httpAddAllowedEmail,
    this.removeAllowedEmail = httpRemoveAllowedEmail,
    this.fetchPhoneRecoveryGrants = httpFetchPhoneRecoveryGrants,
    this.grantPhoneRecovery = httpGrantPhoneRecovery,
    this.revokePhoneRecoveryGrant = httpRevokePhoneRecoveryGrant,
    this.fetchLoginHistory = httpFetchLoginHistory,
    this.fetchCourseSubmissions = httpFetchCourseSubmissions,
    this.approveCourseSubmission = httpApproveCourseSubmission,
    this.rejectCourseSubmission = httpRejectCourseSubmission,
  });

  final FetchAdminOfficers fetchOfficers;
  final LinkOfficerEmail linkOfficerEmail;
  final FetchAdminSupportTickets fetchSupportTickets;
  final ResolveSupportTicket resolveTicket;
  final FetchAllowedPhones fetchAllowedPhones;
  final AddAllowedPhone addAllowedPhone;
  final RemoveAllowedPhone removeAllowedPhone;
  final FetchAllowedEmails fetchAllowedEmails;
  final AddAllowedEmail addAllowedEmail;
  final RemoveAllowedEmail removeAllowedEmail;
  final FetchPhoneRecoveryGrants fetchPhoneRecoveryGrants;
  final GrantPhoneRecovery grantPhoneRecovery;
  final RevokePhoneRecoveryGrant revokePhoneRecoveryGrant;
  final FetchLoginHistory fetchLoginHistory;
  final FetchCourseSubmissions fetchCourseSubmissions;
  final ApproveCourseSubmission approveCourseSubmission;
  final RejectCourseSubmission rejectCourseSubmission;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _controller = TextEditingController();
  bool _isChecking = false;
  bool _isKeyVisible = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Enter the admin key.');
      return;
    }
    setState(() {
      _isChecking = true;
      _error = null;
    });
    try {
      // Verifying the key by making a real call, rather than a separate
      // "check password" endpoint — one less thing to keep in sync.
      await widget.fetchOfficers(key);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(
            adminKey: key,
            fetchOfficers: widget.fetchOfficers,
            linkOfficerEmail: widget.linkOfficerEmail,
            fetchSupportTickets: widget.fetchSupportTickets,
            resolveTicket: widget.resolveTicket,
            fetchAllowedPhones: widget.fetchAllowedPhones,
            addAllowedPhone: widget.addAllowedPhone,
            removeAllowedPhone: widget.removeAllowedPhone,
            fetchAllowedEmails: widget.fetchAllowedEmails,
            addAllowedEmail: widget.addAllowedEmail,
            removeAllowedEmail: widget.removeAllowedEmail,
            fetchPhoneRecoveryGrants: widget.fetchPhoneRecoveryGrants,
            grantPhoneRecovery: widget.grantPhoneRecovery,
            revokePhoneRecoveryGrant: widget.revokePhoneRecoveryGrant,
            fetchLoginHistory: widget.fetchLoginHistory,
            fetchCourseSubmissions: widget.fetchCourseSubmissions,
            approveCourseSubmission: widget.approveCourseSubmission,
            rejectCourseSubmission: widget.rejectCourseSubmission,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('adminKeyField'),
                  controller: _controller,
                  obscureText: !_isKeyVisible,
                  decoration: InputDecoration(
                    labelText: 'Admin key',
                    suffixIcon: IconButton(
                      key: const Key('toggleAdminKeyVisibilityButton'),
                      icon: Icon(_isKeyVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      tooltip: _isKeyVisible ? 'Hide admin key' : 'Show admin key',
                      onPressed: () => setState(() => _isKeyVisible = !_isKeyVisible),
                    ),
                  ),
                  onSubmitted: (_) => _unlock(),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('adminUnlockButton'),
                    onPressed: _isChecking ? null : _unlock,
                    child: _isChecking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Unlock'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
