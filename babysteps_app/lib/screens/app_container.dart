import 'package:flutter/material.dart';
import 'package:babysteps_app/screens/home_screen.dart';
import 'package:babysteps_app/screens/milestones_screen.dart';
import 'package:babysteps_app/screens/diary_screen.dart';
import 'package:babysteps_app/screens/concerns_screen.dart';
import 'package:babysteps_app/screens/ask_screen.dart';
import 'package:babysteps_app/widgets/bottom_nav_bar.dart';

class AppContainer extends StatefulWidget {
  const AppContainer({super.key});

  @override
  State<AppContainer> createState() => _AppContainerState();
}

class _AppContainerState extends State<AppContainer> {
  int _currentIndex = 0;
  
  // Define the list of screens to navigate between
  final List<Widget> _screens = [
    const HomeScreen(showBottomNav: false),
    const MilestonesScreen(showBottomNav: false),
    const DiaryScreen(),
    const ConcernsScreen(),
    const AskScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
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
