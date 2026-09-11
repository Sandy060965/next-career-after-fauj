import 'package:flutter/material.dart';

import '../routing/app_routes.dart';

/// A persistent "back to Home" AppBar action — added to every in-shell
/// screen so an officer is never more than one tap from the main shell, no
/// matter how many screens deep they've navigated. `AppRoutes.profile`
/// resolves to `MainShell` (see main.dart), and `pushNamedAndRemoveUntil`
/// clears the whole navigation stack, so a fresh `MainShell` always opens
/// back on the Home tab.
class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('homeButton'),
      icon: const Icon(Icons.home_outlined),
      tooltip: 'Home',
      onPressed: () => Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.profile, (route) => false),
    );
  }
}
