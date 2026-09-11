import 'package:flutter/material.dart';

import '../../core/routing/module_catalog.dart';
import '../../core/widgets/home_button.dart';
import '../../core/widgets/section_list_widgets.dart';

/// The "Career" tab root — orientation tools plus the self-assessment and
/// gap-analysis chain (Career Vertical Fit → Target Role Strategy →
/// JD Match → Refined CV / Gap Roadmap). Renders from [kCareerModules],
/// the same data the wide-screen sidebar (app_sidebar.dart) reads, so the
/// two stay in sync automatically.
class CareerSectionScreen extends StatelessWidget {
  const CareerSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Career'), actions: const [HomeButton()]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        children: [
          for (final phase in kCareerModules) ...[
            PhaseHeader(phase.title, color: kCareerColor),
            for (final module in phase.modules)
              ModuleButton(keyName: module.keyName, route: module.route, label: module.label),
          ],
        ],
      ),
    );
  }
}
