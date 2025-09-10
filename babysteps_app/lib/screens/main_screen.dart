import 'package:flutter/material.dart';
import 'package:babysteps_app/screens/home_screen.dart';
import 'package:babysteps_app/screens/milestones_screen.dart';
import 'package:babysteps_app/screens/diary_screen.dart';
import 'package:babysteps_app/screens/concerns_screen.dart';
import 'package:babysteps_app/screens/ask_ai_screen.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    MilestonesScreen(),
    DiaryScreen(),
    ConcernsScreen(),
    AskAiScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
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
            icon: Icon(FeatherIcons.messageCircle),
            label: 'Ask',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
