import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/screens/onboarding_milestones_screen.dart';
import 'package:babysteps_app/screens/onboarding_gender_screen.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';
import 'package:babysteps_app/widgets/staggered_animation.dart';

const Color _activitiesBackgroundColor = Colors.white;

const Color _cardIdleBackground = Colors.white;
const Color _cardSelectedBackground = Color(0xFFF4ECFB);
const Color _loveAccentColor = Color(0xFF34D399);

const Map<String, IconData> _activityIconMappings = {
  'sleep': FeatherIcons.moon,
  'feeding': FeatherIcons.feather,
  'music': FeatherIcons.music,
  'tummy': FeatherIcons.trendingUp,
  'walk': FeatherIcons.mapPin,
  'reading': FeatherIcons.bookOpen,
  'play': FeatherIcons.smile,
  'outdoor': FeatherIcons.sun,
  'water': FeatherIcons.droplet,
  'drawing': FeatherIcons.edit3,
  'blocks': FeatherIcons.grid,
  'dance': FeatherIcons.activity,
};

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
  final Map<String, IconData> _iconAssignments = <String, IconData>{};
  final Set<IconData> _allocatedIcons = <IconData>{};

  static const List<IconData> _iconPalette = <IconData>[
    FeatherIcons.moon,
    FeatherIcons.feather,
    FeatherIcons.music,
    FeatherIcons.trendingUp,
    FeatherIcons.mapPin,
    FeatherIcons.bookOpen,
    FeatherIcons.smile,
    FeatherIcons.sun,
    FeatherIcons.droplet,
    FeatherIcons.edit3,
    FeatherIcons.grid,
    FeatherIcons.activity,
    FeatherIcons.camera,
    FeatherIcons.book,
    FeatherIcons.briefcase,
    FeatherIcons.coffee,
    FeatherIcons.heart,
    FeatherIcons.monitor,
    FeatherIcons.scissors,
    FeatherIcons.sliders,
    FeatherIcons.zap,
    FeatherIcons.award,
    FeatherIcons.cpu,
    FeatherIcons.film,
    FeatherIcons.box,
    FeatherIcons.framer,
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = (widget.initialIndex >= 0 && widget.initialIndex < widget.babies.length) ? widget.initialIndex : 0;
    _selectedBaby = widget.babies[_currentIndex];
    _iconAssignments.clear();
    _allocatedIcons.clear();
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
        _iconAssignments.clear();
        _allocatedIcons.clear();
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
        _iconAssignments.clear();
        _allocatedIcons.clear();
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
    
    // Build four lists by status
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
    
    // Always save locally for persistence during onboarding
    await babyProvider.savePendingBabyActivities(_selectedBaby.id, loves, hates);
    
    try {
      // Ensure the baby exists before saving activities (FK constraint)
      await babyProvider.initialize();
      final existingIds = babyProvider.babies.map((b) => b.id).toSet();
      if (!existingIds.contains(_selectedBaby.id)) {
        try {
          await babyProvider.createBaby(_selectedBaby);
        } catch (e) {
          // In guest mode, save fails. Data is already stored locally.
          final message = e.toString();
          if (!message.contains('User not authenticated')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving baby: $e')),
              );
            }
          }
          // Activities are saved locally, so continue anyway
          return;
        }
      }
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
    } catch (e) {
      // In guest mode, save fails. Data is already stored locally.
      final message = e.toString();
      if (!message.contains('User not authenticated')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving activities: $e')),
          );
        }
      }
    }
  }
  Future<void> _next() async {
    await _save();
    if (_currentIndex < widget.babies.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedBaby = widget.babies[_currentIndex];
      });
      await _load();
    } else {
      if (!mounted) return;
      Navigator.of(context).pushWithFade(
        OnboardingMilestonesScreen(babies: widget.babies),
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
      Navigator.of(context).pushReplacementWithFade(
        OnboardingGenderScreen(babies: widget.babies, initialIndex: _currentIndex),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestionsForAge(_selectedBaby);
    // Merge suggestions with any previously added labels
    final items = <String>{...suggestions, ..._labels}.toList();
    final hasSelection = _status.values.any((s) => s == 'love' || s == 'hate' || s == 'neutral');

    void _handleStatusToggle(String label, String? newStatus) {
      setState(() {
        if (newStatus == null) {
          _status.remove(label);
        } else {
          _status[label] = newStatus;
          _labels.add(label);
        }
      });
    }

    Color statusColor(String? s) {
      switch (s) {
        case 'love':
          return _loveAccentColor;
        case 'hate':
          return Colors.redAccent;
        case 'neutral':
          return const Color(0xFFF59E0B);
        case 'skipped':
          return Colors.blueGrey;
        default:
          return AppTheme.primaryPurple;
      }
    }

    IconData _iconForLabel(String label) {
      if (_iconAssignments.containsKey(label)) {
        return _iconAssignments[label]!;
      }

      IconData? icon;
      final lower = label.toLowerCase();
      for (final pair in _activityIconMappings.entries) {
        if (lower.contains(pair.key) && !_allocatedIcons.contains(pair.value)) {
          icon = pair.value;
          break;
        }
      }

      icon ??= _iconPalette.firstWhere(
        (candidate) => !_allocatedIcons.contains(candidate),
        orElse: () => _iconPalette.first,
      );

      _iconAssignments[label] = icon;
      _allocatedIcons.add(icon);
      return icon;
    }

    Widget buildActivityIcon(String label, String? status) {
      final icon = _iconForLabel(label);
      final accent = statusColor(status);
      final active = status != null;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: active
              ? LinearGradient(
                  colors: [
                    accent.withOpacity(0.25),
                    accent.withOpacity(0.05),
                  ],
                )
              : null,
          color: active ? null : AppTheme.lightPurple.withOpacity(0.28),
          border: Border.all(
            color: active ? accent.withOpacity(0.55) : AppTheme.primaryPurple.withOpacity(0.22),
            width: active ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : AppTheme.primaryPurple.withOpacity(0.75),
          size: 26,
        ),
      );
    }

    Widget emojiButton(String emoji, Color accent, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : AppTheme.lightPurple.withOpacity(0.26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent.withOpacity(0.8) : AppTheme.primaryPurple.withOpacity(0.25),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Text(
            emoji,
            style: TextStyle(
              fontSize: 18,
              color: selected ? accent : AppTheme.textPrimary,
            ),
          ),
        ),
      );
    }

    String statusText(String? s) {
      switch (s) {
        case 'love':
          return 'Loved';
        case 'hate':
          return 'Disliked';
        case 'neutral':
          return 'Neutral';
        case 'skipped':
          return 'Skipped';
        default:
          return '';
      }
    }

    Widget buildActivityCard(String label, int index) {
      final status = _status[label];
      final accent = statusColor(status);
      final hasStatus = status != null;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: StaggeredAnimation(
          index: index,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: hasStatus ? _cardSelectedBackground : _cardIdleBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasStatus ? accent.withOpacity(0.6) : AppTheme.primaryPurple.withOpacity(0.2),
                width: hasStatus ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(hasStatus ? 0.26 : 0.08),
                  blurRadius: hasStatus ? 20 : 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildActivityIcon(label, status),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (status != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: accent.withOpacity(0.4)),
                              ),
                              child: Text(
                                statusText(status),
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          emojiButton('🙂', _loveAccentColor, status == 'love', () {
                            _handleStatusToggle(label, status == 'love' ? null : 'love');
                          }),
                          emojiButton('😐', const Color(0xFFF59E0B), status == 'neutral', () {
                            _handleStatusToggle(label, status == 'neutral' ? null : 'neutral');
                          }),
                          emojiButton('🙁', Colors.redAccent, status == 'hate', () {
                            _handleStatusToggle(label, status == 'hate' ? null : 'hate');
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _activitiesBackgroundColor,
      body: Container(
        color: _activitiesBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              OnboardingAppBar(
                onBackPressed: _back,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    Text(
                      'Activities for ${_selectedBaby.name}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick how your child reacts to each activity using the emojis below. Choose at least one to continue.',
                      style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.85),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...items.asMap().entries.map((entry) => buildActivityCard(entry.value, entry.key)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.12)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryPurple.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add your own',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _customActivity,
                                  onSubmitted: (value) {
                                    final text = value.trim();
                                    if (text.isEmpty) return;
                                    setState(() {
                                      _labels.add(text);
                                      _customActivity.clear();
                                    });
                                  },
                                  style: const TextStyle(color: AppTheme.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'Add an activity',
                                    hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
                                    filled: true,
                                    fillColor: AppTheme.lightPurple.withOpacity(0.35),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: AppTheme.primaryPurple.withOpacity(0.2)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: AppTheme.primaryPurple.withOpacity(0.2)),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(14)),
                                      borderSide: BorderSide(color: AppTheme.primaryPurple, width: 1.6),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  final text = _customActivity.text.trim();
                                  if (text.isEmpty) return;
                                  setState(() {
                                    _labels.add(text);
                                    _customActivity.clear();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  'Add',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: ElevatedButton(
                  onPressed: hasSelection ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    minimumSize: const Size(double.infinity, 54),
                  ),
                  child: Text(
                    _currentIndex < widget.babies.length - 1
                        ? 'Next: ${widget.babies[_currentIndex + 1].name}'
                        : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}