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
import 'package:babysteps_app/screens/onboarding_nurture_global_screen.dart';
import 'package:babysteps_app/screens/onboarding_goals_screen.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

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
  Baby? _babyBeingEdited;

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

  void _updateBaby(Baby baby) {
    setState(() {
      final index = _babies.indexWhere((b) => b.id == baby.id);
      if (index != -1) {
        _babies[index] = baby;
      }
    });
  }

  void _startEditBaby(Baby baby) {
    setState(() {
      _babyBeingEdited = baby;
      _nameController.text = baby.name;
      _selectedDate = baby.birthdate;
    });
  }

  void _cancelEdit() {
    setState(() {
      _babyBeingEdited = null;
      _nameController.clear();
      _selectedDate = null;
    });
  }

  void _deleteBaby(Baby baby) async {
    setState(() {
      _babies.removeWhere((b) => b.id == baby.id);
    });
    if (_babyBeingEdited?.id == baby.id) {
      _cancelEdit();
    }
    
    // Delete from backend
    try {
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      await babyProvider.deleteBaby(baby.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting baby: $e')),
        );
      }
    }
  }

  void _submitAddBaby() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      if (_babyBeingEdited != null) {
        final updated = _babyBeingEdited!.copyWith(
          name: _nameController.text.trim(),
          birthdate: _selectedDate,
        );
        _updateBaby(updated);
        _cancelEdit();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Baby updated')),
        );
      } else {
        final baby = Baby(
          id: _uuid.v4(),
          name: _nameController.text.trim(),
          birthdate: _selectedDate!,
          completedMilestones: [],
        );
        _addBaby(baby);
        _nameController.clear();
        setState(() {
          _selectedDate = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Baby added')),
        );
      }
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
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            OnboardingAppBar(
              onBackPressed: () {
                Navigator.of(context).pushReplacementWithFade(
                  const OnboardingGoalsScreen(),
                );
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Title
                    const Text(
                      'Your Baby',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your baby\'s details',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Inline Add Baby Form
                    Form(
                      key: _formKey,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Baby\'s Name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.all(14),
                                ),
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
                                      final initial = _selectedDate ?? DateTime.now();
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: initial,
                                        firstDate: DateTime(2015),
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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryPurple,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    _babyBeingEdited != null ? 'Save Changes' : 'Add Baby',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                ),
                              ),
                              if (_babyBeingEdited != null) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _cancelEdit,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(color: AppTheme.primaryPurple, width: 1.5),
                                      foregroundColor: AppTheme.primaryPurple,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Cancel Edit'),
                                  ),
                                ),
                              ],
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
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        baby.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Born: ${DateFormat.yMMMd().format(baby.birthdate)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(FeatherIcons.edit2, color: AppTheme.primaryPurple),
                                      onPressed: () {
                                        _startEditBaby(baby);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(FeatherIcons.trash2, color: Color(0xFFEF4444)),
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text('Delete baby?'),
                                              content: Text('Are you sure you want to delete ${baby.name}?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        if (confirmed == true) {
                                          _deleteBaby(baby);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: (_babies.isNotEmpty && !_isLoading)
                    ? () async {
                        setState(() => _isLoading = true);
                        try {
                          final babyProvider = Provider.of<BabyProvider>(context, listen: false);
                          await babyProvider.initialize();
                          final existingIds = babyProvider.babies.map((b) => b.id).toSet();
                          for (final baby in _babies) {
                            if (!existingIds.contains(baby.id)) {
                              await babyProvider.createBaby(baby);
                            } else {
                              // Ensure existing record is up to date (name/birthdate edits)
                              await babyProvider.updateBabyRecord(baby);
                            }
                          }
                          if (!mounted) return;
                          Navigator.of(context).pushWithFade(
                            OnboardingGenderScreen(babies: _babies, initialIndex: 0),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Next',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
