import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/models/concern.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/screens/app_container.dart';
import 'package:babysteps_app/screens/onboarding_baby_screen.dart';
import 'package:babysteps_app/screens/onboarding_gender_screen.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/providers/auth_provider.dart';
import 'package:babysteps_app/utils/app_animations.dart';
import 'package:babysteps_app/widgets/onboarding_app_bar.dart';

class OnboardingConcernsScreen extends StatefulWidget {
  final List<Baby> babies;
  final List<Concern> initialConcerns;
  final int initialIndex;
  
  const OnboardingConcernsScreen({
    required this.babies,
    this.initialConcerns = const [],
    this.initialIndex = 0,
    super.key,
  });

  @override
  State<OnboardingConcernsScreen> createState() => _OnboardingConcernsScreenState();
}

class _OnboardingConcernsScreenState extends State<OnboardingConcernsScreen> {
  late List<Concern> _concerns;
  final TextEditingController _concernController = TextEditingController();
  bool _isSaving = false;
  late Baby _selectedBaby;
  final Set<String> _selectedConcerns = {};
  final TextEditingController _customController = TextEditingController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _concerns = List.from(widget.initialConcerns);
    if (widget.babies.isNotEmpty) {
      _currentIndex = (widget.initialIndex >= 0 && widget.initialIndex < widget.babies.length)
          ? widget.initialIndex
          : 0;
      _selectedBaby = widget.babies[_currentIndex];
    }
    _loadForCurrentBaby();
  }

  Future<void> _loadForCurrentBaby() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    // Select baby then fetch concerns via provider
    babyProvider.selectBaby(_selectedBaby.id);
    final concerns = await babyProvider.getConcerns();
    if (!mounted) return;
    setState(() {
      _concerns = concerns;
    });
    _syncSelectedSelectionsFromConcerns();
  }

  List<Widget> _buildConcernCards() {
    final suggestions = _suggestedConcernsForAge(_selectedBaby);
    // Include any custom selections not in suggestions so they display as cards
    final customSelected = _selectedConcerns.where((s) => !suggestions.contains(s)).toList();
    final items = [...suggestions, ...customSelected];

    return items.map((label) {
      final isSelected = _selectedConcerns.contains(label);
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
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
          child: ListTile(
            onTap: () async {
              if (!isSelected) {
                setState(() => _selectedConcerns.add(label));
                await _addConcernWithText(label);
              } else {
                setState(() => _selectedConcerns.remove(label));
                await _removeConcernByText(label);
              }
            },
            title: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryPurple : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppTheme.primaryPurple)
                : const Icon(Icons.circle_outlined, color: AppTheme.textSecondary),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      );
    }).toList();
  }

  // Add a concern from suggested chip text and persist to Supabase
  Future<void> _addConcernWithText(String text) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final concern = Concern(
      id: tempId,
      text: text,
      isResolved: false,
      createdAt: DateTime.now(),
    );

    setState(() {
      _concerns.add(concern);
    });

    try {
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      await babyProvider.createConcern(
        babyId: _selectedBaby.id,
        text: concern.text,
        isResolved: concern.isResolved,
        createdAt: concern.createdAt,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving concern: $e')),
        );
      }
    }
  }

  // Remove a concern by its text label (used for suggested chips)
  Future<void> _removeConcernByText(String text) async {
    final idx = _concerns.indexWhere((c) => c.text == text);
    if (idx == -1) return;
    final concern = _concerns[idx];

    setState(() {
      _concerns.removeAt(idx);
    });

    try {
      // Only attempt remote delete if we have a non-temp id
      if (!concern.id.startsWith('temp_')) {
        final babyProvider = Provider.of<BabyProvider>(context, listen: false);
        await babyProvider.deleteConcern(concernId: concern.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting concern: $e')),
        );
      }
    }
  }

  // Keep selected items in sync with existing concerns list
  void _syncSelectedSelectionsFromConcerns() {
    final existing = _concerns.map((c) => c.text).toSet();
    _selectedConcerns
      ..clear()
      ..addAll(existing);
  }

  // Provide 7-8 age-based suggested concerns
  List<String> _suggestedConcernsForAge(Baby baby) {
    final weeks = DateTime.now().difference(baby.birthdate).inDays ~/ 7;
    if (weeks <= 8) {
      return [
        'Feeding frequency',
        'Weight gain',
        'Jaundice',
        'Sleep duration',
        'Spit-up/reflux',
        'Diaper output',
        'Crying/colic',
        'Umbilical cord healing',
      ];
    } else if (weeks <= 17) {
      return [
        'Tummy time tolerance',
        'Head shape/flat spots',
        'Feeding amounts',
        'Gas/discomfort',
        'Day-night reversal',
        'Dry skin/eczema',
        'Vaccination reactions',
      ];
    } else if (weeks <= 26) {
      return [
        'Rolling safety',
        'Introducing solids',
        'Allergy reactions',
        'Constipation',
        'Teething discomfort',
        'Sleep regressions',
        'Coughs/colds',
      ];
    } else if (weeks <= 39) {
      return [
        'Crawling safety',
        'Choking hazards',
        'Separation anxiety',
        'Ear infections',
        'Fever management',
        'Sleep schedule',
        'Biting/teething',
      ];
    } else if (weeks <= 52) {
      return [
        'Walking safety',
        'Weaning/bottle transition',
        'Milk intake',
        'Food variety/picky eating',
        'Rashes/eczema',
        'Night wakings',
        'Stranger anxiety',
      ];
    } else if (weeks <= 78) {
      return [
        'Speech development',
        'Behavior/tantrums',
        'Allergies',
        'Constipation/diarrhea',
        'Sleep transitions',
        'Milk vs water intake',
        'Bumps/bruises',
      ];
    } else if (weeks <= 104) {
      return [
        'Toilet training readiness',
        'Eating variety',
        'Sleep resistance',
        'Sharing/behavior',
        'Seasonal illnesses',
        'Skin rashes',
        'Allergic reactions',
      ];
    } else {
      return [
        'Toilet training progress',
        'Night waking',
        'Picky eating',
        'Speech clarity',
        'Behavior outbursts',
        'Allergies/asthma',
        'Injury prevention',
      ];
    }
  }

  @override
  void dispose() {
    _concernController.dispose();
    super.dispose();
  }

  Future<void> _addConcern() async {
    if (_concernController.text.trim().isEmpty) return;
    
    final concern = Concern(
      id: DateTime.now().toString(), // Temporary ID until saved to Supabase
      text: _concernController.text.trim(),
      isResolved: false,
      createdAt: DateTime.now(),
    );
    
    setState(() {
      _concerns.add(concern);
      _concernController.clear();
    });
    
    try {
      // Save to Supabase via provider
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      await babyProvider.createConcern(
        babyId: _selectedBaby.id,
        text: concern.text,
        isResolved: concern.isResolved,
        createdAt: concern.createdAt,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving concern: $e')),
        );
      }
    }
  }

  Future<void> _toggleConcern(String concernId) async {
    final index = _concerns.indexWhere((concern) => concern.id == concernId);
    if (index != -1) {
      final concern = _concerns[index];
      final newIsResolved = !concern.isResolved;
      final DateTime? resolvedAt = newIsResolved ? DateTime.now() : null;
      
      setState(() {
        _concerns[index] = concern.copyWith(
          isResolved: newIsResolved,
          resolvedAt: resolvedAt,
        );
      });
      
      try {
        // Update in Supabase via provider
        final babyProvider = Provider.of<BabyProvider>(context, listen: false);
        await babyProvider.updateConcern(
          concernId: concernId,
          isResolved: newIsResolved,
          resolvedAt: resolvedAt,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating concern: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteConcern(String concernId) async {
    final index = _concerns.indexWhere((concern) => concern.id == concernId);
    if (index != -1) {
      setState(() {
        _concerns.removeAt(index);
      });
      
      try {
        // Delete from Supabase via provider
        final babyProvider = Provider.of<BabyProvider>(context, listen: false);
        await babyProvider.deleteConcern(concernId: concernId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting concern: $e')),
          );
        }
      }
    }
  }

  void _showAddConcernDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Concern'),
        content: TextField(
          controller: _concernController,
          decoration: const InputDecoration(
            hintText: 'Enter your concern',
          ),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _addConcern();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _goNext() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Mark onboarding as complete in Supabase
      final babyProvider = Provider.of<BabyProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Save any remaining concerns data if needed
      for (final concern in _concerns) {
        if (concern.id.startsWith('temp_')) {
          await babyProvider.createConcern(
            babyId: _selectedBaby.id,
            text: concern.text,
            isResolved: concern.isResolved,
            createdAt: concern.createdAt,
            resolvedAt: concern.resolvedAt,
          );
        }
      }
      
      // If multiple babies, advance through babies first
      if (_currentIndex < widget.babies.length - 1) {
        setState(() {
          _currentIndex += 1;
          _selectedBaby = widget.babies[_currentIndex];
        });
        await _loadForCurrentBaby();
      } else {
        // Proceed to Gender step when last baby is done
        if (mounted) {
          Navigator.of(context).pushWithFade(
            OnboardingGenderScreen(babies: widget.babies, initialIndex: 0),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing onboarding: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingAppBar(
              onBackPressed: () async {
                if (_currentIndex > 0) {
                  setState(() {
                    _currentIndex -= 1;
                    _selectedBaby = widget.babies[_currentIndex];
                  });
                  await _loadForCurrentBaby();
                } else {
                  if (!mounted) return;
                  Navigator.of(context).pushReplacementWithFade(
                    OnboardingBabyScreen(initialBabies: widget.babies),
                  );
                }
              },
            ),
            const OnboardingProgressBar(progress: 0.85),
            // Main content: title, subtitle, grid and custom add
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Which concerns do you want to track for ${_selectedBaby.name}?',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Tap to select from common concerns for this age, or add your own below.',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  Builder(builder: (context) {
                    final suggestions = _suggestedConcernsForAge(_selectedBaby);
                    final customSelected = _selectedConcerns.where((s) => !suggestions.contains(s)).toList();
                    final items = [...suggestions, ...customSelected];
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 3.0,
                      children: items.map((label) {
                        final isSelected = _selectedConcerns.contains(label);
                        return GestureDetector(
                          onTap: () async {
                            if (!isSelected) {
                              setState(() => _selectedConcerns.add(label));
                              await _addConcernWithText(label);
                            } else {
                              setState(() => _selectedConcerns.remove(label));
                              await _removeConcernByText(label);
                            }
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
                  const SizedBox(height: 16),
                  const Text('Add your own', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customController,
                          decoration: const InputDecoration(
                            hintText: 'Enter a custom concern',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final text = _customController.text.trim();
                          if (text.isEmpty) return;
                          if (_selectedConcerns.contains(text)) return;
                          setState(() {
                            _selectedConcerns.add(text);
                            _customController.clear();
                          });
                          await _addConcernWithText(text);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
                        child: const Text('Add'),
                      )
                    ],
                  ),
                ],
              ),
            ),
            
            // Navigation button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: (_isSaving || _selectedConcerns.isEmpty) ? null : _goNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentIndex < widget.babies.length - 1
                            ? 'Next: ${widget.babies[_currentIndex + 1].name}'
                            : 'Next',
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildHeader() { return const SizedBox.shrink(); }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.lightPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FeatherIcons.clipboard,
              size: 48,
              color: AppTheme.darkPurple.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No concerns yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tap the + button to add concerns or questions about your baby\'s health',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddConcernDialog,
            icon: const Icon(FeatherIcons.plus),
            label: const Text('Add First Concern'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcernsList() {
    final sortedConcerns = List<Concern>.from(_concerns)
      ..sort((a, b) {
        // Active concerns first, then by creation date (newest first)
        if (a.isResolved != b.isResolved) {
          return a.isResolved ? 1 : -1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedConcerns.length,
      itemBuilder: (context, index) {
        final concern = sortedConcerns[index];
        return _buildConcernItem(concern, index);
      },
    );
  }

  Widget _buildConcernItem(Concern concern, int index) {
    return Dismissible(
      key: Key(concern.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(FeatherIcons.trash2, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteConcern(concern.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: concern.isResolved
              ? Colors.grey.shade100
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: concern.isResolved
                ? Colors.grey.shade300
                : AppTheme.lightPurple,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: InkWell(
            onTap: () => _toggleConcern(concern.id),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: concern.isResolved
                    ? AppTheme.darkPurple
                    : Colors.white,
                border: Border.all(
                  color: concern.isResolved
                      ? AppTheme.darkPurple
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: concern.isResolved
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          title: Text(
            concern.text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: concern.isResolved
                  ? Colors.grey.shade500
                  : AppTheme.textPrimary,
              decoration: concern.isResolved
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  concern.isResolved && concern.resolvedAt != null
                      ? 'Resolved: ${_formatDate(concern.resolvedAt!)}'  
                      : _formatDate(concern.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
