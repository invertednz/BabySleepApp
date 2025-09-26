import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/screens/onboarding_milestones_screen.dart';
import 'package:babysteps_app/screens/onboarding_gender_screen.dart';

class OnboardingActivitiesLovesHatesScreen extends StatefulWidget {
  final List<Baby> babies;
  final int initialIndex;
  const OnboardingActivitiesLovesHatesScreen({required this.babies, this.initialIndex = 0, super.key});

  @override
  State<OnboardingActivitiesLovesHatesScreen> createState() => _OnboardingActivitiesLovesHatesScreenState();
}

class _OnboardingActivitiesLovesHatesScreenState extends State<OnboardingActivitiesLovesHatesScreen> {
  late Baby _selectedBaby;
  int _currentIndex = 0;
  // Track per-activity status: love | hate | neutral | skipped
  final Map<String, String> _status = <String, String>{};
  final Set<String> _labels = <String>{};
  final TextEditingController _customActivity = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentIndex = (widget.initialIndex >= 0 && widget.initialIndex < widget.babies.length) ? widget.initialIndex : 0;
    _selectedBaby = widget.babies[_currentIndex];
    // Defer initial load to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    // Fire-and-forget save so we persist latest changes even if user leaves unexpectedly
    _save();
    _customActivity.dispose();
    super.dispose();
  }

  List<String> _suggestionsForAge(Baby baby) {
    final weeks = DateTime.now().difference(baby.birthdate).inDays ~/ 7;
    if (weeks <= 8) {
      return ['Feeding', 'Sleeping', 'Skin-to-skin', 'Bath time', 'Soft music'];
    } else if (weeks <= 26) {
      return ['Tummy time', 'Rattles', 'Short walks', 'Reading picture books', 'Gentle massage'];
    } else if (weeks <= 52) {
      return ['Blocks', 'Music & dance', 'Peekaboo', 'Outdoor stroller walks', 'Water play'];
    } else if (weeks <= 104) {
      return ['Drawing', 'Playground (swings/slides)', 'Pretend play', 'Scooters/balance bikes', 'Story time'];
    } else {
      return ['Building forts', 'Simple board games', 'Nature walks', 'Helping in kitchen', 'Ride-on toys'];
    }
  }

  Future<void> _load() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    // Try new dated preferences first
    final prefs = await babyProvider.getBabyActivityPreferences(babyId: _selectedBaby.id);
    if (prefs.isNotEmpty) {
      setState(() {
        _status.clear();
        _labels.clear();
        for (final e in prefs) {
          final label = (e['label'] as String).trim();
          final s = (e['status'] as String).toLowerCase();
          if (label.isEmpty) continue;
          if (s == 'love' || s == 'hate' || s == 'neutral' || s == 'skipped') {
            _status[label] = s;
            _labels.add(label);
          }
        }
      });
    } else {
      // Fallback: legacy array storage
      final map = await babyProvider.getBabyActivities(babyId: _selectedBaby.id);
      setState(() {
        _status.clear();
        _labels.clear();
        for (final l in (map['loves'] ?? <String>[])) {
          _status[l] = 'love';
          _labels.add(l);
        }
        for (final h in (map['hates'] ?? <String>[])) {
          _status[h] = 'hate';
          _labels.add(h);
        }
      });
    }
  }

  Future<void> _save() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    // Ensure the baby exists before saving activities (FK constraint)
    await babyProvider.initialize();
    final existingIds = babyProvider.babies.map((b) => b.id).toSet();
    if (!existingIds.contains(_selectedBaby.id)) {
      try {
        await babyProvider.createBaby(_selectedBaby);
      } catch (_) {
        // If creation fails, bail out to avoid FK error
        return;
      }
    }
    // Build four lists by status and save
    final loves = <String>[];
    final hates = <String>[];
    final neutral = <String>[];
    final skipped = <String>[];
    _status.forEach((label, s) {
      switch (s) {
        case 'love': loves.add(label); break;
        case 'hate': hates.add(label); break;
        case 'neutral': neutral.add(label); break;
        case 'skipped': skipped.add(label); break;
      }
    });
    // Save new dated preferences with current timestamp
    await babyProvider.upsertBabyActivityPreferences(
      babyId: _selectedBaby.id,
      loves: loves,
      hates: hates,
      neutral: neutral,
      skipped: skipped,
      recordedAt: DateTime.now(),
    );
    // Back-compat: keep legacy arrays in sync (only loves/hates)
    await babyProvider.saveBabyActivities(
      babyId: _selectedBaby.id,
      loves: loves,
      hates: hates,
    );
  }

  Future<void> _next() async {
    await _save();
    if (_currentIndex < widget.babies.length - 1) {
      setState(() {
        _currentIndex += 1;
        _selectedBaby = widget.babies[_currentIndex];
      });
      await _load();
    } else {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => OnboardingMilestonesScreen(babies: widget.babies)),
      );
    }
  }

  Future<void> _back() async {
    await _save();
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex -= 1;
        _selectedBaby = widget.babies[_currentIndex];
      });
      await _load();
    } else {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OnboardingGenderScreen(babies: widget.babies, initialIndex: _currentIndex),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestionsForAge(_selectedBaby);
    // Merge suggestions with any previously added labels
    final items = <String>{...suggestions, ..._labels}.toList();
    final hasSelection = _status.values.any((s) => s == 'love' || s == 'hate' || s == 'neutral' || s == 'skipped');

    Widget emojiButton(String emoji, Color color, bool selected, VoidCallback onTap) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: selected ? color : color.withOpacity(0.5)),
          backgroundColor: selected ? color.withOpacity(0.1) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      );
    }

    Color statusColor(String? s) {
      switch (s) {
        case 'love': return Colors.green;
        case 'hate': return Colors.redAccent;
        case 'neutral': return Colors.amber;
        case 'skipped': return Colors.grey;
        default: return const Color(0xFFE5E7EB);
      }
    }

    String statusText(String? s) {
      switch (s) {
        case 'love': return 'Loved';
        case 'hate': return 'Hated';
        case 'neutral': return 'Neutral';
        case 'skipped': return 'Skipped';
        default: return '';
      }
    }

    Widget buildActivityRow(String label) {
      final s = _status[label];
      final sc = statusColor(s);
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: s == null ? const Color(0xFFE5E7EB) : sc, width: s == null ? 1 : 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
                  if (s != null) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sc.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: sc.withOpacity(0.5)),
                    ),
                    child: Text(statusText(s), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sc)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            emojiButton('×', Colors.grey, s == 'skipped', () {
              setState(() { _status[label] = 'skipped'; _labels.add(label); });
            }),
            const SizedBox(width: 8),
            emojiButton('🙂', Colors.green, s == 'love', () {
              setState(() { _status[label] = 'love'; _labels.add(label); });
            }),
            const SizedBox(width: 8),
            emojiButton('😐', Colors.amber, s == 'neutral', () {
              setState(() { _status[label] = 'neutral'; _labels.add(label); });
            }),
            const SizedBox(width: 8),
            emojiButton('🙁', Colors.redAccent, s == 'hate', () {
              setState(() { _status[label] = 'hate'; _labels.add(label); });
            }),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(FeatherIcons.sunrise, color: AppTheme.primaryPurple, size: 32),
                  const SizedBox(width: 8),
                  const Text('BabySteps', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(_selectedBaby.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const LinearProgressIndicator(
              value: 0.65,
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Activities for ${_selectedBaby.name}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Pick how your child reacts to these activities using the emojis. Choose at least one to continue.', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  // Activities list
                  ...items.map(buildActivityRow),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customActivity,
                          onSubmitted: (value) {
                            final text = value.trim();
                            if (text.isEmpty) return;
                            setState(() { _labels.add(text); _customActivity.clear(); });
                          },
                          decoration: const InputDecoration(hintText: 'Add an activity', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final text = _customActivity.text.trim();
                          if (text.isEmpty) return;
                          setState(() { _labels.add(text); _customActivity.clear(); });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _back,
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: hasSelection ? _next : null,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: Text(_currentIndex < widget.babies.length - 1 ? 'Next: ${widget.babies[_currentIndex + 1].name}' : 'Next'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
