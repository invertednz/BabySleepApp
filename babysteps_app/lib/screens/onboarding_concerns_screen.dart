import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/models/concern.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/screens/app_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/providers/auth_provider.dart';

class OnboardingConcernsScreen extends StatefulWidget {
  final List<Baby> babies;
  final List<Concern> initialConcerns;
  
  const OnboardingConcernsScreen({
    required this.babies,
    this.initialConcerns = const [],
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

  @override
  void initState() {
    super.initState();
    _concerns = List.from(widget.initialConcerns);
    if (widget.babies.isNotEmpty) {
      _selectedBaby = widget.babies.first;
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

  Future<void> _completeOnboarding() async {
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
      
      // Mark onboarding as complete locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboardingComplete', true);
      
      // Navigate to the main app
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AppContainer()),
          (Route<dynamic> route) => false,
        );
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
            // Progress bar
            LinearProgressIndicator(
              value: 0.9, // 90% progress
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
            ),
            
            // Header
            _buildHeader(),
            
            // Main content
            Expanded(
              child: _concerns.isEmpty
                  ? _buildEmptyState()
                  : _buildConcernsList(),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _completeOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                          : const Text('Complete Setup'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddConcernDialog,
        backgroundColor: AppTheme.darkPurple,
        child: const Icon(FeatherIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(FeatherIcons.alertCircle, color: AppTheme.darkPurple),
              const SizedBox(width: 12),
              const Text(
                'Concerns',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_concerns.where((c) => !c.isResolved).length} active',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Add any health concerns or questions you want to track for your baby.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

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
