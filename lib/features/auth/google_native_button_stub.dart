import 'package:flutter/widgets.dart';

import '../../core/services/google_auth_service.dart';

/// Never actually built — phone_verification_screen.dart only reaches this
/// on non-web platforms, where the app's own OutlinedButton (calling
/// GoogleAuthService.signIn() directly) is used instead of a rendered
/// Google-owned widget. Exists solely so the conditional import resolves on
/// non-web platform builds.
Widget buildGoogleNativeButton({
  required GoogleAuthService googleAuthService,
  required ValueChanged<String> onIdToken,
  required ValueChanged<String> onError,
}) {
  throw UnsupportedError('The rendered Google button is only implemented for web.');
}
