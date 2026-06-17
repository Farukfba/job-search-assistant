import 'package:flutter/material.dart';
import 'job_search_screen.dart';
import 'tracker_screen.dart';

/// Owns the bottom nav and keeps JobSearchScreen / TrackerScreen alive
/// across tab switches via IndexedStack. Because IndexedStack preserves
/// state instead of recreating screens, TrackerScreen's initState only
/// ever runs once — so anything that changes tracker data elsewhere
/// (saving a job from JobDetailScreen) needs to explicitly tell this
/// screen to reload. That's what trackerKey + refreshTracker are for.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static _MainShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainShellState>();

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _trackerKey = GlobalKey<TrackerScreenState>();

  /// Call this from anywhere with access to MainShell's BuildContext
  /// (via MainShell.of(context)?.refreshTracker()) right after a job
  /// is saved, so the tracker reflects it without needing a logout.
  void refreshTracker() {
    _trackerKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const JobSearchScreen(),
      TrackerScreen(key: _trackerKey),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Tracker'),
        ],
      ),
    );
  }
}