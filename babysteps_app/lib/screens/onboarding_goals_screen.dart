import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/screens/onboarding_baby_screen.dart';
import 'package:babysteps_app/screens/onboarding_nurture_global_screen.dart';

class OnboardingGoalsScreen extends StatefulWidget {
  const OnboardingGoalsScreen({super.key});

  @override
  State<OnboardingGoalsScreen> createState() => _OnboardingGoalsScreenState();
}

class _OnboardingGoalsScreenState extends State<OnboardingGoalsScreen> {
  final Set<String> _selected = {};
  final TextEditingController _customController = TextEditingController();

  final List<String> _options = const [
    'Strong friendship with my child',
    'Curiosity & intelligence',
    'Confidence & resilience',
    'Kindness & empathy',
    'Healthy routines & habits',
    'Love of outdoors & movement',
    'Creativity & playfulness',
  ];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final prefs = await babyProvider.getUserPreferences();
    final existing = List<String>.from(prefs['goals'] ?? <String>[]);
    setState(() {
      _selected
        ..clear()
        ..addAll(existing);
      _loading = false;
    });
  }

  Future<void> _saveAndNext() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    await babyProvider.saveUserGoals(_selected.toList());
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OnboardingBabyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: const [
                  Icon(FeatherIcons.sunrise, color: AppTheme.primaryPurple, size: 32),
                  SizedBox(width: 8),
                  Text('BabySteps', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Spacer(),
                ],
              ),
            ),
            const LinearProgressIndicator(
              value: 0.3,
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
            ),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('What long-term goals do you have as a parent?',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Pick as many as you like. You can add your own.',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 16),
                    Builder(builder: (_) {
                      final customSelected = _selected.where((s) => !_options.contains(s)).toList();
                      final items = [..._options, ...customSelected];
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 3.0,
                        children: items.map((opt) {
                          final isSelected = _selected.contains(opt);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selected.remove(opt);
                                } else {
                                  _selected.add(opt);
                                }
                              });
                            },
                            child: Card(
                              elevation: isSelected ? 3 : 1,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1.5,
                                ),
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    opt,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected ? AppTheme.primaryPurple : AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }),
                    const SizedBox(height: 8),
                    const Text('Add your own', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customController,
                            onSubmitted: (value) {
                              final text = value.trim();
                              if (text.isEmpty) return;
                              setState(() {
                                _selected.add(text);
                                _customController.clear();
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: 'Enter a custom goal',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final text = _customController.text.trim();
                            if (text.isEmpty) return;
                            setState(() {
                              _selected.add(text);
                              _customController.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
                          child: const Text('Add'),
                        )
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
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const OnboardingNurtureGlobalScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selected.isEmpty ? null : _saveAndNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Next'),
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
