import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/member_select/providers/active_member_provider.dart';

/// Shell scaffold: BottomNavigationBar on phones, NavigationRail on tablets.
/// Also houses the member-switcher in the app bar.
class ResponsiveScaffold extends ConsumerWidget {
  const ResponsiveScaffold({required this.child, super.key});
  final Widget child;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.checklist), label: 'Chores'),
    NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Rewards'),
  ];

  static const _adminDestination =
      NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Admin');

  static const _paths = ['/chores', '/rewards', '/admin'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider).value;
    final isAdmin = authState?.isAdmin ?? false;
    final memberName = ref.watch(activeMemberNameProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _paths.indexOf(location).clamp(0, isAdmin ? 2 : 1);

    final destinations = [
      ..._destinations,
      if (isAdmin) _adminDestination,
    ];

    void onTap(int idx) {
      final path = _paths[idx];
      if (path != location) context.go(path);
    }

    final appBar = AppBar(
      title: const Text('ChoreChampion'),
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/select-member'),
          icon: const Icon(Icons.person),
          label: Text(memberName ?? 'Select'),
        ),
      ],
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= kTabletBreakpoint) {
        // Tablet: NavigationRail
        return Scaffold(
          appBar: appBar,
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onTap,
                labelType: NavigationRailLabelType.all,
                destinations: destinations
                    .map((d) => NavigationRailDestination(
                          icon: d.icon,
                          label: Text(d.label),
                        ))
                    .toList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        );
      }

      // Phone: BottomNavigationBar
      return Scaffold(
        appBar: appBar,
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onTap,
          destinations: destinations,
        ),
      );
    });
  }
}
