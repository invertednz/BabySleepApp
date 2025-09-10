import 'package:flutter/material.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/screens/login_screen.dart';
import 'package:babysteps_app/screens/onboarding_gender_screen.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:uuid/uuid.dart';

class OnboardingBabyScreen extends StatefulWidget {
  const OnboardingBabyScreen({super.key});

  @override
  State<OnboardingBabyScreen> createState() => _OnboardingBabyScreenState();
}

class _OnboardingBabyScreenState extends State<OnboardingBabyScreen> {
  final List<Baby> _babies = [];
  final _uuid = const Uuid();
  bool _isLoading = false;

  void _addBaby(Baby baby) {
    setState(() {
      _babies.add(baby);
    });
  }

  Future<void> _showAddBabyDialog() async {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    DateTime? _selectedDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add a Baby'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Baby\'s Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _selectedDate != null) {
                      final baby = Baby(
                        id: _uuid.v4(), // Temporary ID until saved to Supabase
                        name: _nameController.text,
                        birthdate: _selectedDate!,
                        completedMilestones: [],
                      );
                      Navigator.of(context).pop();
                      _addBaby(baby);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
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
              value: 0.2,
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
                    // Add Baby Button
                    OutlinedButton.icon(
                      onPressed: _showAddBabyDialog,
                      icon: const Icon(FeatherIcons.plus),
                      label: const Text('Add Another Baby'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryPurple),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 50),
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
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
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
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => OnboardingGenderScreen(babies: _babies)),
                                    );
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
