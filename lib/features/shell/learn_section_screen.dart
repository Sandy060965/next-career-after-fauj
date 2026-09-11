import 'package:flutter/material.dart';

import '../../core/routing/module_catalog.dart';
import '../../core/widgets/home_button.dart';
import '../../core/widgets/section_list_widgets.dart';

/// The "Learn" tab root — CV-building tools and interview/communication
/// preparation, grouped separately from the assessment chain under Career.
/// Renders from [kLearnModules], the same data the wide-screen sidebar
/// (app_sidebar.dart) reads, so the two stay in sync automatically.
class LearnSectionScreen extends StatelessWidget {
  const LearnSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learn'), actions: const [HomeButton()]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        children: [
          for (final phase in kLearnModules) ...[
            PhaseHeader(phase.title, color: kLearnColor),
            for (final module in phase.modules)
              ModuleButton(keyName: module.keyName, route: module.route, label: module.label),
          ],
        ],
      ),
    );
  }
}
