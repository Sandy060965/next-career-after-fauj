import 'package:flutter/material.dart';

import '../../core/routing/module_catalog.dart';
import '../../core/widgets/home_button.dart';
import '../../core/widgets/section_list_widgets.dart';

/// The "Jobs" tab root — active job search plus compensation, interview
/// aftermath, and landing. Renders from [kJobsModules], the same data the
/// wide-screen sidebar (app_sidebar.dart) reads, so the two stay in sync
/// automatically.
class JobsSectionScreen extends StatelessWidget {
  const JobsSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jobs'), actions: const [HomeButton()]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        children: [
          for (final phase in kJobsModules) ...[
            PhaseHeader(phase.title, color: kJobsColor),
            for (final module in phase.modules)
              ModuleButton(keyName: module.keyName, route: module.route, label: module.label),
          ],
        ],
      ),
    );
  }
}
