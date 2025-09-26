import 'package:flutter/material.dart';
import 'package:babysteps_app/screens/home_screen.dart';
import 'package:babysteps_app/screens/milestones_screen.dart';
import 'package:babysteps_app/screens/progress_screen.dart';
import 'package:babysteps_app/screens/concerns_screen.dart';
import 'package:babysteps_app/screens/ask_screen.dart';
import 'package:babysteps_app/screens/focus_screen.dart';
import 'package:babysteps_app/widgets/bottom_nav_bar.dart';

class AppContainer extends StatefulWidget {
  final int initialIndex;

  const AppContainer({super.key, this.initialIndex = 4}); // Default to Home page (index 4)

  @override
  State<AppContainer> createState() => _AppContainerState();
}

class _AppContainerState extends State<AppContainer> {
  late int _currentIndex; // 0: Concerns, 1: Progress, 2: Focus, 3: Milestones, 4: Home

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // Build only the currently selected screen to avoid constructing off-screen tabs
  Widget _screenForIndex(int index) {
    switch (index) {
      case 0:
        return const ConcernsScreen();
      case 1:
        return const ProgressScreen();
      case 2:
        return const FocusScreen();
      case 3:
        return const MilestonesScreen(showBottomNav: false);
      case 4:
        return const HomeScreen(showBottomNav: false);
      default:
        return const HomeScreen(showBottomNav: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screenForIndex(_currentIndex),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
