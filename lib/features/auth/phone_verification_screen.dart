import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import 'otp_entry_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  PhoneVerificationScreen({super.key, AuthService? authService})
      : authService = authService ?? AuthService();

  final AuthService authService;

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController _mobileController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final mobileNumber = _mobileController.text.trim();
    if (mobileNumber.length != 10 || int.tryParse(mobileNumber) == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Enter a valid 10-digit mobile number')));
      return;
    }

    setState(() => _isSending = true);
    try {
      await widget.authService.requestOtp(mobileNumber);
      if (!mounted) return;
      setState(() => _isSending = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpEntryScreen(mobileNumber: mobileNumber, authService: widget.authService),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Next Career After Fauj')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verify your mobile number', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'We\'ll text you a 6-digit code to confirm it\'s you. '
              'Used only to secure your account — never shared.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('phoneField'),
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(labelText: 'Mobile number', prefixText: '+91 '),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('sendCodeButton'),
                onPressed: _isSending ? null : _sendCode,
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
