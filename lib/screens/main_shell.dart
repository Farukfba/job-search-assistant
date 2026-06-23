import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'job_search_screen.dart';
import 'profile_screen.dart';
import 'tracker_screen.dart';

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

  void refreshTracker() {
    _trackerKey.currentState?.reload();
    _homeKey.currentState?.reload();
  }

  void goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final sans = GoogleFonts.inter().fontFamily!;
    final screens = [
      HomeScreen(key: _homeKey),
      const JobSearchScreen(),
      TrackerScreen(key: _trackerKey),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(index: 0, currentIndex: _index, icon: Icons.grid_view_rounded,
                    activeIcon: Icons.grid_view_rounded, label: 'Home', sans: sans,
                    onTap: () => setState(() => _index = 0)),
                _NavItem(index: 1, currentIndex: _index, icon: Icons.search_rounded,
                    activeIcon: Icons.search_rounded, label: 'Search', sans: sans,
                    onTap: () => setState(() => _index = 1)),
                _NavItem(index: 2, currentIndex: _index, icon: Icons.bar_chart_rounded,
                    activeIcon: Icons.bar_chart_rounded, label: 'Tracker', sans: sans,
                    onTap: () => setState(() => _index = 2)),
                _NavItem(index: 3, currentIndex: _index, icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded, label: 'Profile', sans: sans,
                    onTap: () => setState(() => _index = 3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String sans;
  final VoidCallback onTap;

  const _NavItem({required this.index, required this.currentIndex, required this.icon,
      required this.activeIcon, required this.label, required this.sans, required this.onTap});

  bool get _active => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(_active ? activeIcon : icon, size: 24,
              color: _active ? AppColors.green : AppColors.muted),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontFamily: sans, fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _active ? AppColors.green : AppColors.muted)),
        ]),
      ),
    );
  }
}