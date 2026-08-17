import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/profile_repository.dart';

class OtpEntryScreen extends StatefulWidget {
  OtpEntryScreen({super.key, required this.mobileNumber, AuthService? authService})
      : authService = authService ?? AuthService();

  final String mobileNumber;
  final AuthService authService;

  @override
  State<OtpEntryScreen> createState() => _OtpEntryScreenState();
}

class _OtpEntryScreenState extends State<OtpEntryScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Enter the 6-digit code')));
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final result = await widget.authService.verifyOtp(mobileNumber: widget.mobileNumber, code: code);
      if (!mounted) return;
      final repo = context.read<ProfileRepository>();
      repo.saveSession(result.token, result.account);
      Navigator.of(context).pushNamedAndRemoveUntil(
        repo.profile != null ? AppRoutes.profile : AppRoutes.onboarding,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      await widget.authService.requestOtp(widget.mobileNumber);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Code resent')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter code')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verify your number', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Enter the 6-digit code sent to +91 ${widget.mobileNumber}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('otpField'),
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: '6-digit code'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('verifyOtpButton'),
                onPressed: _isVerifying ? null : _verify,
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify'),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                key: const Key('resendCodeButton'),
                onPressed: _isResending ? null : _resend,
                child: Text(_isResending ? 'Sending…' : 'Resend code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
