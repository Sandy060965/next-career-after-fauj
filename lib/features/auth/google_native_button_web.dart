import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

import '../../core/services/google_auth_service.dart';

/// Web only: google_sign_in_web does not support the interactive
/// `authenticate()` call the way native platforms do — it throws
/// UnimplementedError, and requires rendering Google's own button widget
/// instead. This widget renders that button and listens for the resulting
/// sign-in on GoogleSignIn's authenticationEvents stream (the same stream
/// `authenticate()` itself feeds on other platforms), reporting the ID
/// token or an error back to the caller via plain callbacks rather than a
/// Future — there's no synchronous "the click happened" moment to await.
Widget buildGoogleNativeButton({
  required GoogleAuthService googleAuthService,
  required ValueChanged<String> onIdToken,
  required ValueChanged<String> onError,
}) {
  return _GoogleNativeButton(
    googleAuthService: googleAuthService,
    onIdToken: onIdToken,
    onError: onError,
  );
}

class _GoogleNativeButton extends StatefulWidget {
  const _GoogleNativeButton({
    required this.googleAuthService,
    required this.onIdToken,
    required this.onError,
  });

  final GoogleAuthService googleAuthService;
  final ValueChanged<String> onIdToken;
  final ValueChanged<String> onError;

  @override
  State<_GoogleNativeButton> createState() => _GoogleNativeButtonState();
}

class _GoogleNativeButtonState extends State<_GoogleNativeButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await widget.googleAuthService.ensureInitialized();
      _subscription = GoogleSignIn.instance.authenticationEvents.listen(
        (event) {
          if (event is! GoogleSignInAuthenticationEventSignIn) return;
          final idToken = event.user.authentication.idToken;
          if (idToken == null) {
            widget.onError('Could not get a Google sign-in token.');
            return;
          }
          widget.onIdToken(idToken);
        },
        onError: (Object e) {
          widget.onError('Could not sign in with Google.');
        },
      );
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      widget.onError('Could not start Google sign-in.');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox(
        height: 40,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    return web.renderButton();
  }
}
