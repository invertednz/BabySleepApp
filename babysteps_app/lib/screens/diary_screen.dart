import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/models/diary_entry.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/services/supabase_service.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/widgets/add_note_sheet.dart';
import 'package:babysteps_app/widgets/note_card.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late DateTime _selectedDate;
  late ScrollController _scrollController;

  final Map<DateTime, List<DiaryEntry>> _entries = {};
  bool _isLoading = false;
  bool _isAuthenticated = false;

  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    _scrollController = ScrollController(initialScrollOffset: (7 - (DateTime.now().weekday)) * 68.0);
    _isAuthenticated = supabase.Supabase.instance.client.auth.currentUser != null;
    if (_isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEntries();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String? _getBabyId() {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    return babyProvider.selectedBaby?.id;
  }

  Future<void> _loadEntries() async {
    final babyId = _getBabyId();
    if (babyId == null || !_isAuthenticated) return;

    setState(() => _isLoading = true);

    try {
      final entries = await _supabaseService.getDiaryEntries(babyId);
      if (!mounted) return;
      setState(() {
        _entries.clear();
        for (final entry in entries) {
          final dateKey = DateUtils.dateOnly(entry.timestamp);
          if (_entries.containsKey(dateKey)) {
            _entries[dateKey]!.add(entry);
          } else {
            _entries[dateKey] = [entry];
          }
        }
        // Sort each day's entries by time descending
        for (final key in _entries.keys) {
          _entries[key]!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load diary entries: $e')),
      );
    }
  }

  List<DiaryEntry> _getEntriesForSelectedDate() {
    return _entries[_selectedDate] ?? [];
  }

  String _getBabyLabel() {
    final babyProvider = Provider.of<BabyProvider>(context);
    final baby = babyProvider.selectedBaby;
    if (baby == null) return 'My Baby';

    final name = baby.name.trim().isNotEmpty ? baby.name.trim() : 'My Baby';

    // Calculate age
    final now = DateTime.now();
    final birthdate = baby.birthdate;
    final months = (now.year - birthdate.year) * 12 + now.month - birthdate.month;
    if (months < 1) {
      final days = now.difference(birthdate).inDays;
      return '$name \u00B7 ${days}d';
    } else if (months < 24) {
      return '$name \u00B7 $months mo';
    } else {
      final years = months ~/ 12;
      final remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return '$name \u00B7 ${years}y';
      }
      return '$name \u00B7 ${years}y ${remainingMonths}m';
    }
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
                    child: Text(
                      _getBabyLabel(),
                      style: const TextStyle(
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFA67EB7)))
                  : _buildEntriesList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteSheet(context),
        backgroundColor: const Color(0xFFA67EB7),
        child: const Icon(Icons.add),
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
        itemCount: 30,
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
                border: Border.all(color: AppTheme.lightPurple),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E().format(date),
                    style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat.d().format(date),
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
            Text('No diary entries yet. Start logging your baby\'s day!', style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Dismissible(
          key: Key(entry.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Entry'),
                content: const Text('Are you sure you want to delete this diary entry?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ) ?? false;
          },
          onDismissed: (_) => _deleteEntry(entry),
          child: NoteCard(entry: entry),
        );
      },
    );
  }

  Future<void> _deleteEntry(DiaryEntry entry) async {
    final dateKey = DateUtils.dateOnly(entry.timestamp);

    // Remove from local state immediately
    setState(() {
      _entries[dateKey]?.removeWhere((e) => e.id == entry.id);
      if (_entries[dateKey]?.isEmpty ?? false) {
        _entries.remove(dateKey);
      }
    });

    // Delete from Supabase
    if (_isAuthenticated) {
      try {
        await _supabaseService.deleteDiaryEntry(entry.id);
      } catch (e) {
        if (!mounted) return;
        // Re-add the entry since delete failed
        setState(() {
          if (_entries.containsKey(dateKey)) {
            _entries[dateKey]!.add(entry);
            _entries[dateKey]!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          } else {
            _entries[dateKey] = [entry];
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete entry: $e')),
        );
      }
    }
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
      final dateKey = DateUtils.dateOnly(newEntry.timestamp);

      // Update local state immediately
      setState(() {
        if (_entries.containsKey(dateKey)) {
          _entries[dateKey]!.add(newEntry);
        } else {
          _entries[dateKey] = [newEntry];
        }
        _entries[dateKey]!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });

      // Save to Supabase
      if (_isAuthenticated) {
        final babyId = _getBabyId();
        if (babyId != null) {
          try {
            await _supabaseService.saveDiaryEntry(babyId, newEntry);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Entry saved locally but failed to sync: $e')),
            );
          }
        }
      }
    }
  }
}
