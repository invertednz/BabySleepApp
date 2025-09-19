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
  final Set<String> _loves = {};
  final Set<String> _hates = {};
  final TextEditingController _customLove = TextEditingController();
  final TextEditingController _customHate = TextEditingController();

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
    _customLove.dispose();
    _customHate.dispose();
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
    final map = await babyProvider.getBabyActivities(babyId: _selectedBaby.id);
    setState(() {
      _loves
        ..clear()
        ..addAll(map['loves'] ?? <String>[]);
      _hates
        ..clear()
        ..addAll(map['hates'] ?? <String>[]);
    });
  }

  Future<void> _save() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    await babyProvider.saveBabyActivities(
      babyId: _selectedBaby.id,
      loves: _loves.toList(),
      hates: _hates.toList(),
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
    final canContinue = _loves.isNotEmpty || _hates.isNotEmpty;

    Widget buildGrid(Set<String> selected, void Function(String) onTap) {
      final customExtras = selected.where((s) => !suggestions.contains(s)).toList();
      final items = [...suggestions, ...customExtras];
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 3.0,
        children: items.map((label) {
          final isSelected = selected.contains(label);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selected.remove(label);
                } else {
                  selected.add(label);
                }
              });
            },
            child: Card(
              elevation: isSelected ? 3 : 1,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade300, width: isSelected ? 2 : 1.5),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? AppTheme.primaryPurple : AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          );
        }).toList(),
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
                  Text('Loves & Hates for ${_selectedBaby.name}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Tell us activities your child loves and dislikes right now. This helps tailor tips and ideas.', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  const Text('Loves', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  buildGrid(_loves, (s) {}),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customLove,
                          onSubmitted: (value) {
                            final text = value.trim();
                            if (text.isEmpty) return;
                            setState(() { _loves.add(text); _customLove.clear(); });
                          },
                          decoration: const InputDecoration(hintText: 'Add a love', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final text = _customLove.text.trim();
                          if (text.isEmpty) return;
                          setState(() { _loves.add(text); _customLove.clear(); });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Hates', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  buildGrid(_hates, (s) {}),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customHate,
                          onSubmitted: (value) {
                            final text = value.trim();
                            if (text.isEmpty) return;
                            setState(() { _hates.add(text); _customHate.clear(); });
                          },
                          decoration: const InputDecoration(hintText: 'Add a hate', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final text = _customHate.text.trim();
                          if (text.isEmpty) return;
                          setState(() { _hates.add(text); _customHate.clear(); });
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
                      onPressed: canContinue ? _next : null,
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
