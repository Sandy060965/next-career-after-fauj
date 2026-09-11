import 'package:flutter/material.dart';

/// A section divider between groups of modules on a tab-root screen, so a
/// flat list of buttons reads as a journey with phases rather than an
/// undifferentiated list. Deliberately styled well above the module
/// buttons' own text size/weight (titleLarge + bold, vs. the buttons'
/// labelLarge) plus a colored accent bar, so it reads unambiguously as a
/// heading rather than blending in with what it's introducing. [color]
/// defaults to the theme's primary but is normally given explicitly — each
/// tab-root screen (career/jobs/learn_section_screen.dart) passes its own
/// category colour (module_catalog.dart's kCareerColor/kJobsColor/
/// kLearnColor) so every phase heading under that category reads as
/// visually part of the same group, and the wide-screen sidebar
/// (app_sidebar.dart) uses the same colours for its own phase labels.
class PhaseHeader extends StatelessWidget {
  const PhaseHeader(this.title, {super.key, this.color});

  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(color: resolvedColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: resolvedColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
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
