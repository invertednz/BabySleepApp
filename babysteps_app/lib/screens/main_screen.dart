import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/screens/home_screen.dart';
import 'package:babysteps_app/screens/milestones_screen.dart';
import 'package:babysteps_app/screens/diary_screen.dart';
import 'package:babysteps_app/screens/concerns_screen.dart';
import 'package:babysteps_app/screens/sleep_schedule_screen.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _lastBabyId;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _buildWidgetOptions(String? babyId) {
    // Use babyId as key to force rebuild when baby changes
    return <Widget>[
      HomeScreen(key: ValueKey('home_$babyId')),
      MilestonesScreen(key: ValueKey('milestones_$babyId')),
      DiaryScreen(key: ValueKey('diary_$babyId')),
      ConcernsScreen(key: ValueKey('concerns_$babyId')),
      SleepScheduleScreen(key: ValueKey('sleep_$babyId')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final babyProvider = Provider.of<BabyProvider>(context);
    final currentBabyId = babyProvider.selectedBaby?.id;

    // Check if baby has changed
    if (_lastBabyId != currentBabyId) {
      // Baby changed, rebuild will happen automatically
      _lastBabyId = currentBabyId;
    }

    final widgetOptions = _buildWidgetOptions(currentBabyId);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensures all labels are shown
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(FeatherIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(FeatherIcons.award),
            label: 'Milestones',
          ),
          BottomNavigationBarItem(
            icon: Icon(FeatherIcons.bookOpen),
            label: 'Diary',
          ),
          BottomNavigationBarItem(
            icon: Icon(FeatherIcons.alertCircle),
            label: 'Concerns',
          ),
          BottomNavigationBarItem(
            icon: Icon(FeatherIcons.moon),
            label: 'Sleep',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
