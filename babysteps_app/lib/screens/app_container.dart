import 'package:flutter/material.dart';
import 'package:babysteps_app/screens/home_screen.dart';
import 'package:babysteps_app/screens/milestones_screen.dart';
import 'package:babysteps_app/screens/progress_screen.dart';
import 'package:babysteps_app/screens/sleep_schedule_screen.dart';
import 'package:babysteps_app/screens/focus_screen.dart';
import 'package:babysteps_app/widgets/bottom_nav_bar.dart';
import 'package:babysteps_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/screens/premium_required_screen.dart';

class AppContainer extends StatefulWidget {
  final int initialIndex;

  const AppContainer({super.key, this.initialIndex = 2}); // Default to Advice tab (index 2)

  @override
  State<AppContainer> createState() => _AppContainerState();
}

class _AppContainerState extends State<AppContainer> {
  late int _currentIndex; // 0: Progress, 1: Milestones, 2: Advice, 3: Focus, 4: Sleep
  bool _showingPremiumGate = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // Build only the currently selected screen to avoid constructing off-screen tabs
  Widget _screenForIndex(int index) {
    switch (index) {
      case 0:
        return const ProgressScreen();
      case 1:
        return const MilestonesScreen(showBottomNav: false);
      case 2:
        return const HomeScreen(showBottomNav: false);
      case 3:
        return const FocusScreen();
      case 4:
        return const SleepScheduleScreen();
      default:
        return const HomeScreen(showBottomNav: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bool isPaidUser = authProvider.isPaidUser;
    final bool isFreeUser = !isPaidUser;
    final allowedIndices = {0, 1};
    final bool canAccessCurrent = !isFreeUser || allowedIndices.contains(_currentIndex);

    if (_showingPremiumGate && !isFreeUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _showingPremiumGate = false;
        });
      });
    }

    if (!_showingPremiumGate && isFreeUser && !canAccessCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentIndex = 0;
          _showingPremiumGate = true;
        });
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          _screenForIndex(_currentIndex),
          if (_showingPremiumGate)
            PremiumRequiredScreen(
              onClose: () {
                setState(() {
                  _showingPremiumGate = false;
                  _currentIndex = 0;
                });
              },
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (isFreeUser && !allowedIndices.contains(index)) {
            setState(() {
              _showingPremiumGate = true;
            });
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
