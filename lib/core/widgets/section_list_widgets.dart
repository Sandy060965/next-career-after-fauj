import 'package:flutter/material.dart';

/// A section divider between groups of modules on a tab-root screen, so a
/// flat list of buttons reads as a journey with phases rather than an
/// undifferentiated list.
class PhaseHeader extends StatelessWidget {
  const PhaseHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// A single full-width module entry point, used across the Profile,
/// Career, Jobs, and Learn tab-root screens so every module link looks and
/// behaves identically regardless of which section it's grouped under.
class ModuleButton extends StatelessWidget {
  const ModuleButton({super.key, required this.keyName, required this.route, required this.label});

  final String keyName;
  final String route;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          key: Key(keyName),
          onPressed: () => Navigator.of(context).pushNamed(route),
          child: Text(label),
        ),
      ),
    );
  }
}
