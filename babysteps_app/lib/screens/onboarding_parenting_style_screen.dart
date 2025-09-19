import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/screens/onboarding_nurture_global_screen.dart';
import 'package:provider/provider.dart' as flutter_provider;
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingParentingStyleScreen extends StatefulWidget {
  final List<Baby> babies;
  final int initialIndex;
  const OnboardingParentingStyleScreen({required this.babies, this.initialIndex = 0, super.key});

  @override
  State<OnboardingParentingStyleScreen> createState() => _OnboardingParentingStyleScreenState();
}

class _OnboardingParentingStyleScreenState extends State<OnboardingParentingStyleScreen> {
  Baby? _selectedBaby;
  int _currentIndex = 0;
  final Set<String> _selectedStyles = {};
  final TextEditingController _customController = TextEditingController();

  final List<String> _styles = const [
    'Gentle & Responsive',
    'Structured & Predictable',
    'Flexible & Adaptive',
    'Attachment-Focused',
    'Routine-Led',
    'Play-Centered',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.babies.isNotEmpty) {
      _currentIndex = (widget.initialIndex >= 0 && widget.initialIndex < widget.babies.length)
          ? widget.initialIndex
          : 0;
      _selectedBaby = widget.babies[_currentIndex];
    }
  }

  void _toggle(String style) {
    setState(() {
      if (_selectedStyles.contains(style)) {
        _selectedStyles.remove(style);
      } else {
        _selectedStyles.add(style);
      }
    });
  }

  Future<void> _back() async {
    // Log out and go to Login
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _next() async {
    // Persist global parenting styles
    final babyProvider = flutter_provider.Provider.of<BabyProvider>(context, listen: false);
    await babyProvider.saveUserParentingStyles(_selectedStyles.toList());
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OnboardingNurtureGlobalScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header like Gender screen
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(FeatherIcons.sunrise, color: AppTheme.primaryPurple, size: 32),
                  const SizedBox(width: 8),
                  const Text('BabySteps', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (widget.babies.isNotEmpty && _selectedBaby != null)
                    Text(_selectedBaby!.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const LinearProgressIndicator(
              value: 0.1,
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('What is your parenting style?',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Pick as many as you like. You can add your own.',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  // Merge base styles with any custom selections so customs appear inline
                  Builder(builder: (context) {
                    final customSelected = _selectedStyles.where((s) => !_styles.contains(s)).toList();
                    final items = [..._styles, ...customSelected];
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 3.0,
                      children: items.map((label) {
                        final isSelected = _selectedStyles.contains(label);
                        return GestureDetector(
                          onTap: () => _toggle(label),
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
                                  label,
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
                              _selectedStyles.add(text);
                              _customController.clear();
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Enter a custom parenting style',
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
                            _selectedStyles.add(text);
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
                      onPressed: _back,
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
                      onPressed: _selectedStyles.isEmpty ? null : _next,
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
            ),
          ],
        ),
      ),
    );
  }
}
