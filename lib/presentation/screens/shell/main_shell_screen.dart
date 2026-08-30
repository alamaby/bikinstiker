import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../missions/missions_screen.dart';
import '../packs/packs_list_screen.dart';

/// Post-auth navigation shell: 4 tabs on a [NavigationBar] with a lazily
/// built [IndexedStack] (a tab is constructed the first time it is visited
/// and stays alive afterwards — Missions/Packs/History need the auth user to
/// be available, so building everything up-front is not safe).
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 0;
  int _maxVisited = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    MissionsScreen(),
    PacksListScreen(),
    HistoryScreen(),
  ];

  void _select(int i) {
    setState(() {
      _index = i;
      _maxVisited = _maxVisited > i ? _maxVisited : i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < _screens.length; i++)
            i <= _maxVisited ? _screens[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events_outlined),
            selectedIcon: const Icon(Icons.emoji_events_rounded),
            label: l10n.navMissions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.collections_bookmark_outlined),
            selectedIcon: const Icon(Icons.collections_bookmark_rounded),
            label: l10n.navPacks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history_rounded),
            label: l10n.navHistory,
          ),
        ],
      ),
    );
  }
}
