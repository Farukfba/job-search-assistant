import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'job_search_screen.dart';
import 'profile_screen.dart';
import 'tracker_screen.dart';

/// Owns the bottom nav and keeps all four tab screens alive across
/// switches via IndexedStack. Because IndexedStack preserves state
/// instead of recreating screens, each screen's initState only ever
/// runs once per session — so anything that changes data elsewhere
/// (saving a job from JobDetailScreen) needs to explicitly tell the
/// relevant screen(s) to reload. That's what the GlobalKeys and
/// refresh methods below are for.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static _MainShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainShellState>();

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _homeKey = GlobalKey<HomeScreenState>();
  final _trackerKey = GlobalKey<TrackerScreenState>();

  /// Call after a job is saved elsewhere (e.g. JobDetailScreen) so
  /// both the tracker and home's pipeline stats reflect it without
  /// needing a logout.
  void refreshTracker() {
    _trackerKey.currentState?.reload();
    _homeKey.currentState?.reload();
  }

  /// Lets Home's quick-search and "view tracker" shortcuts switch tabs
  /// without each screen needing to know about Navigator routes.
  void goToTab(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(key: _homeKey),
      const JobSearchScreen(),
      TrackerScreen(key: _trackerKey),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Tracker'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}