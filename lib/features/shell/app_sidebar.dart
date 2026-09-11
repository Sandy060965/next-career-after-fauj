import 'package:flutter/material.dart';

import '../../core/routing/module_catalog.dart';

/// The wide-screen (≥900px) persistent navigation — replaces an icon-only
/// rail with every module listed under its category, grouped by phase
/// exactly as the Career/Jobs/Learn tab-root screens themselves render
/// them (both read from the same lib/core/routing/module_catalog.dart data),
/// so switching modules never needs two clicks (tab, then module) once
/// this sidebar is showing. Reaching Home/Career/Jobs/Learn/Profile itself
/// still switches the shell's own tab, exactly like the rail it replaces.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _tabLabels = ['Home', 'Career', 'Jobs', 'Learn', 'Profile'];
  static const _tabIcons = [
    Icons.home_outlined,
    Icons.trending_up_outlined,
    Icons.work_outline,
    Icons.menu_book_outlined,
    Icons.person_outline,
  ];
  static const _selectedTabIcons = [
    Icons.home,
    Icons.trending_up,
    Icons.work,
    Icons.menu_book,
    Icons.person,
  ];

  // Index 1 = Career, 2 = Jobs, 3 = Learn — matches MainShell's _tabs order.
  static const _moduleCatalogByTab = {1: kCareerModules, 2: kJobsModules, 3: kLearnModules};
  static const _phaseColorByTab = {1: kCareerColor, 2: kJobsColor, 3: kLearnColor};

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          for (var i = 0; i < _tabLabels.length; i++) ...[
            _TabTile(
              key: ValueKey('sidebarTab_${_tabLabels[i]}'),
              icon: selectedIndex == i ? _selectedTabIcons[i] : _tabIcons[i],
              label: _tabLabels[i],
              selected: selectedIndex == i,
              onTap: () => onDestinationSelected(i),
            ),
            if (_moduleCatalogByTab.containsKey(i))
              for (final phase in _moduleCatalogByTab[i]!) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 16, 4),
                  child: Text(
                    phase.title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: _phaseColorByTab[i],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                for (final module in phase.modules)
                  _ModuleTile(
                    key: ValueKey('sidebarModule_${module.keyName}'),
                    label: module.label,
                    onTap: () => Navigator.of(context).pushNamed(module.route),
                  ),
              ],
          ],
        ],
      ),
    );
  }
}

class _TabTile extends StatelessWidget {
  const _TabTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? colorScheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: selected ? colorScheme.onSecondaryContainer : null),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: selected ? colorScheme.onSecondaryContainer : null,
                        fontWeight: selected ? FontWeight.bold : null,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 16, 8),
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ),
    );
  }
}
