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
    this.fetchSupportTickets = httpFetchAdminSupportTickets,
    this.resolveTicket = httpResolveSupportTicket,
    this.fetchAllowedPhones = httpFetchAllowedPhones,
    this.addAllowedPhone = httpAddAllowedPhone,
    this.removeAllowedPhone = httpRemoveAllowedPhone,
    this.fetchLoginHistory = httpFetchLoginHistory,
  });

  final FetchAdminOfficers fetchOfficers;
  final FetchAdminSupportTickets fetchSupportTickets;
  final ResolveSupportTicket resolveTicket;
  final FetchAllowedPhones fetchAllowedPhones;
  final AddAllowedPhone addAllowedPhone;
  final RemoveAllowedPhone removeAllowedPhone;
  final FetchLoginHistory fetchLoginHistory;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _controller = TextEditingController();
  bool _isChecking = false;
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
            fetchSupportTickets: widget.fetchSupportTickets,
            resolveTicket: widget.resolveTicket,
            fetchAllowedPhones: widget.fetchAllowedPhones,
            addAllowedPhone: widget.addAllowedPhone,
            removeAllowedPhone: widget.removeAllowedPhone,
            fetchLoginHistory: widget.fetchLoginHistory,
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
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Admin key'),
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
