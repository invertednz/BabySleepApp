import 'package:flutter/material.dart';
import 'package:babysteps_app/models/diary_entry.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/widgets/add_note_sheet.dart';
import 'package:babysteps_app/widgets/note_card.dart';
import 'package:intl/intl.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late DateTime _selectedDate;
  late ScrollController _scrollController;

  // Dummy data for demonstration
  final Map<DateTime, List<DiaryEntry>> _entries = {
    DateTime.now().subtract(const Duration(days: 1)): [
      DiaryEntry(id: '1', type: NoteType.feeding, title: 'Morning Feed', content: 'Drank 150ml of formula.', timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 8))),
    ],
    DateTime.now(): [
      DiaryEntry(id: '2', type: NoteType.sleep, title: 'Afternoon Nap', content: 'Slept for 1.5 hours.', timestamp: DateTime.now().subtract(const Duration(hours: 4))),
      DiaryEntry(id: '3', type: NoteType.activity, title: 'Tummy Time', content: 'Enjoyed tummy time for 15 minutes.', timestamp: DateTime.now().subtract(const Duration(hours: 2))),
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    // Scroll controller to center the selected date
    _scrollController = ScrollController(initialScrollOffset: (7 - (DateTime.now().weekday)) * 68.0); // Heuristic to center today
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<DiaryEntry> _getEntriesForSelectedDate() {
    return _entries[_selectedDate] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE6D7F2), Color(0xFFC8A2C8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'BabySteps',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Luna · 10 mo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildDateSlider(),
            Expanded(
              child: _buildEntriesList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteSheet(context),
        child: const Icon(Icons.add),
        backgroundColor: Color(0xFFA67EB7),
      ),
    );
  }

  Widget _buildDateSlider() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: 30, // Show 15 days past and 15 days future
        itemBuilder: (context, index) {
          final date = DateUtils.dateOnly(DateTime.now()).add(Duration(days: index - 15));
          final isSelected = date == _selectedDate;
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryPurple : AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.lightPurple)
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E().format(date), // Day of week (e.g., 'Mon')
                    style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat.d().format(date), // Day of month (e.g., '12')
                    style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEntriesList() {
    final entries = _getEntriesForSelectedDate();

    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('No entries for this day.', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return NoteCard(entry: entries[index]);
      },
    );
  }

  void _showAddNoteSheet(BuildContext context) async {
    final newEntry = await showModalBottomSheet<DiaryEntry>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width > 480 ? 480 : double.infinity,
      ),
      builder: (context) => AddNoteSheet(selectedDate: _selectedDate),
    );

    if (newEntry != null) {
      setState(() {
        final dateKey = DateUtils.dateOnly(newEntry.timestamp);
        if (_entries.containsKey(dateKey)) {
          _entries[dateKey]!.add(newEntry);
        } else {
          _entries[dateKey] = [newEntry];
        }
        // Sort entries by time
        _entries[dateKey]!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    }
  }
}
