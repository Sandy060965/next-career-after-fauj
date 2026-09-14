import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/officer_account.dart';
import '../../core/routing/app_routes.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/google_auth_service.dart';
import '../../core/services/officer_progress_prefill.dart';
import '../../core/services/profile_repository.dart';
import 'google_native_button.dart';
import 'otp_entry_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  PhoneVerificationScreen({
    super.key,
    AuthService? authService,
    GoogleAuthService? googleAuthService,
    this.fetchProgressPrefill = httpFetchProgressPrefill,
  })  : authService = authService ?? AuthService(),
        googleAuthService = googleAuthService ?? GoogleAuthService();

  final AuthService authService;
  final GoogleAuthService googleAuthService;
  final FetchProgressPrefill fetchProgressPrefill;

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController _mobileController = TextEditingController();
  bool _isSending = false;
  bool _isGoogleSigningIn = false;
  bool _showPhoneRecovery = false;

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

  // Mirrors OtpEntryScreen._verify()'s post-auth block — both sign-in
  // methods end up with the same VerifyOtpResult shape, so saving the
  // session and deciding profile-vs-onboarding (_onSignedIn below) is
  // identical either way; only how each method's result gets there differs.

  // Non-web: the app's own button triggers the interactive picker directly.
  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleSigningIn = true);
    try {
      final result = await widget.googleAuthService.signIn();
      if (!mounted) return;
      await _onSignedIn(result.token, result.refreshToken, result.account);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGoogleSigningIn = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  // Web: the rendered Google button reports its own click via these
  // callbacks instead of a Future this widget awaits directly.
  Future<void> _handleGoogleIdToken(String idToken) async {
    setState(() => _isGoogleSigningIn = true);
    try {
      final result = await widget.googleAuthService.exchangeIdToken(idToken);
      if (!mounted) return;
      await _onSignedIn(result.token, result.refreshToken, result.account);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGoogleSigningIn = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _handleGoogleError(String message) {
    if (!mounted) return;
    setState(() => _isGoogleSigningIn = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onSignedIn(String token, String refreshToken, OfficerAccount account) async {
    final repo = context.read<ProfileRepository>();
    repo.saveSession(token, account, refreshToken: refreshToken);
    if (repo.profile == null) {
      repo.setProgressPrefill(await widget.fetchProgressPrefill(repo));
    }
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      repo.profile != null ? AppRoutes.profile : AppRoutes.onboarding,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Career After Fauj')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign in', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Sign in with the Google account you registered with — fastest, and '
              'keeps your account yours alone.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // Web can't trigger Google's picker programmatically — it
            // requires rendering Google's own button widget instead (see
            // google_native_button_web.dart), which reports its result via
            // callbacks rather than this method awaiting a Future.
            if (kIsWeb)
              buildGoogleNativeButton(
                googleAuthService: widget.googleAuthService,
                onIdToken: _handleGoogleIdToken,
                onError: _handleGoogleError,
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('googleSignInButton'),
                  onPressed: _isGoogleSigningIn ? null : _signInWithGoogle,
                  icon: _isGoogleSigningIn
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.account_circle_outlined),
                  label: Text(_isGoogleSigningIn ? 'Signing in…' : 'Sign in with Google'),
                ),
              ),
            const SizedBox(height: 24),
            // Phone-OTP is a recovery path now, not a self-service option — it
            // only works for a number an admin has temporarily granted access
            // to (see the "Phone Recovery" admin tab), so it stays out of the
            // way behind this link rather than sitting next to Google as an
            // equally-weighted choice.
            if (!_showPhoneRecovery)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('troubleSigningInButton'),
                  onPressed: () => setState(() => _showPhoneRecovery = true),
                  child: const Text('Trouble signing in?'),
                ),
              )
            else ...[
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('phone sign-in', style: Theme.of(context).textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Phone sign-in only works if the app admin has temporarily enabled it for '
                'your number. If they have, we\'ll text you a 6-digit code to confirm it\'s '
                'you. Otherwise, contact the admin or use Google above.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }
}
