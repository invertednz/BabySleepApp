import 'package:flutter/material.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/screens/login_screen.dart';
import 'package:babysteps_app/screens/onboarding_gender_screen.dart';
import 'package:babysteps_app/screens/onboarding_concerns_screen.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:babysteps_app/screens/onboarding_nurture_global_screen.dart';
import 'package:babysteps_app/screens/onboarding_goals_screen.dart';

class OnboardingBabyScreen extends StatefulWidget {
  final List<Baby>? initialBabies;
  const OnboardingBabyScreen({this.initialBabies, super.key});

  @override
  State<OnboardingBabyScreen> createState() => _OnboardingBabyScreenState();
}

class _OnboardingBabyScreenState extends State<OnboardingBabyScreen> {
  final List<Baby> _babies = [];
  final _uuid = const Uuid();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // If we navigated back from later onboarding steps, preload the passed babies
    if (widget.initialBabies != null && widget.initialBabies!.isNotEmpty) {
      _babies.addAll(widget.initialBabies!);
    }
    // Also load any existing babies from Supabase so the list isn't empty
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final babyProvider = Provider.of<BabyProvider>(context, listen: false);
        await babyProvider.initialize();
        if (!mounted) return;
        setState(() {
          // Merge existing provider babies if not already present
          final existingIds = _babies.map((b) => b.id).toSet();
          for (final b in babyProvider.babies) {
            if (!existingIds.contains(b.id)) {
              _babies.add(b);
            }
          }
        });
      } catch (_) {
        // Ignore fetch errors here; user can still add a baby
      }
    });
  }

  void _addBaby(Baby baby) {
    setState(() {
      _babies.add(baby);
    });
  }

  void _submitAddBaby() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final baby = Baby(
        id: _uuid.v4(),
        name: _nameController.text.trim(),
        birthdate: _selectedDate!,
        completedMilestones: [],
      );
      _addBaby(baby);

      // Clear form for next entry
      _nameController.clear();
      setState(() {
        _selectedDate = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Baby added')),
      );
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a birthdate')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  IconButton(
                    icon: const Icon(FeatherIcons.helpCircle, color: AppTheme.textSecondary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Progress Bar
            const LinearProgressIndicator(
              value: 0.4,
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Title
                    const Text('Your Baby', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Add your baby\'s details', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                    const SizedBox(height: 24),
                    // Inline Add Baby Form
                    Form(
                      key: _formKey,
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(labelText: 'Baby\'s Name'),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedDate == null
                                          ? 'No date chosen'
                                          : 'Born: ${DateFormat.yMMMd().format(_selectedDate!)}',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (pickedDate != null) {
                                        setState(() {
                                          _selectedDate = pickedDate;
                                        });
                                      }
                                    },
                                    child: const Text('Choose Date'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _submitAddBaby,
                                  child: const Text('Add Baby'),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Baby List
                    Expanded(
                      child: ListView.builder(
                        itemCount: _babies.length,
                        itemBuilder: (context, index) {
                          final baby = _babies[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(baby.name),
                              subtitle: Text('Born: ${DateFormat.yMMMd().format(baby.birthdate)}'),
                              trailing: IconButton(
                                icon: const Icon(FeatherIcons.edit2),
                                onPressed: () { /* TODO: Implement edit */ },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Navigation Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => const OnboardingGoalsScreen()),
                              );
                            },
                            child: const Text('Back'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.textSecondary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (_babies.isNotEmpty && !_isLoading)
                                ? () async {
                                    setState(() => _isLoading = true);
                                    try {
                                      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
                                      // Ensure provider has the latest babies from DB
                                      await babyProvider.initialize();
                                      final existingIds = babyProvider.babies.map((b) => b.id).toSet();
                                      // Create any babies not yet persisted
                                      for (final baby in _babies) {
                                        if (!existingIds.contains(baby.id)) {
                                          await babyProvider.createBaby(baby);
                                        }
                                      }
                                      if (!mounted) return;
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => OnboardingConcernsScreen(babies: _babies)),
                                      );
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error saving babies: $e')),
                                        );
                                      }
                                    } finally {
                                      if (mounted) setState(() => _isLoading = false);
                                    }
                                  }
                                : null,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Next'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
