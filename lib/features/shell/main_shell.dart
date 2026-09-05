import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../core/services/officer_progress_sync.dart';
import '../../core/services/profile_repository.dart';
import '../dashboard/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import 'career_section_screen.dart';
import 'jobs_section_screen.dart';
import 'learn_section_screen.dart';

/// The app's persistent top-level navigation — five sections (Home, Career,
/// Jobs, Learn, Profile) reached via a bottom bar on narrow screens or a
/// side rail on wide ones, replacing the old flat 25-button Profile screen.
/// Each of the 25 feature screens is unchanged internally — they're reached
/// by pushing on top of whichever tab is active, exactly as before.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const _wideBreakpoint = 900.0;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget, once per app session — reports how far this officer
    // has got for the admin dashboard. Never blocks or surfaces to the
    // officer if it fails.
    syncOfficerProgress(context.read<ProfileRepository>());
  }

  static const _destinations = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    (icon: Icons.trending_up_outlined, selectedIcon: Icons.trending_up, label: 'Career'),
    (icon: Icons.work_outline, selectedIcon: Icons.work, label: 'Jobs'),
    (icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, label: 'Learn'),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
  ];

  static const _tabs = [
    DashboardScreen(),
    CareerSectionScreen(),
    JobsSectionScreen(),
    LearnSectionScreen(),
    ProfileScreen(),
  ];

  void _openAssistant() {
    Navigator.of(context).pushNamed(AppRoutes.aiAssistant);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= MainShell._wideBreakpoint;
    final body = IndexedStack(index: _index, children: _tabs);

    final fab = FloatingActionButton.extended(
      key: const Key('assistantFab'),
      onPressed: _openAssistant,
      icon: const Icon(Icons.auto_awesome_outlined),
      label: const Text('Assistant'),
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              leading: const SizedBox(height: 16),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: fab,
      );
    }

    return Scaffold(
      body: body,
      floatingActionButton: fab,
      bottomNavigationBar: NavigationBar(
        key: const Key('mainNavBar'),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              key: ValueKey('navTab_${d.label}'),
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
