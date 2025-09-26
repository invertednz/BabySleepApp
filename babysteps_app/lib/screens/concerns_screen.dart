import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/models/concern.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:provider/provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/widgets/app_header.dart';

class ConcernsScreen extends StatefulWidget {
  const ConcernsScreen({super.key});

  @override
  State<ConcernsScreen> createState() => _ConcernsScreenState();
}

class _ConcernsScreenState extends State<ConcernsScreen> {
  final TextEditingController _customController = TextEditingController();
  List<Concern> _concerns = [];
  final Set<String> _selectedConcerns = {};
  Baby? _selectedBaby;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Defer loading to first frame to ensure provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadForSelectedBaby());
  }

  Future<void> _toggleConcern(String concernId) async {
    // Treat tap as "resolve" action and remove from UI immediately
    if (_selectedBaby == null) return;
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final index = _concerns.indexWhere((c) => c.id == concernId);
    if (index == -1) return;
    final item = _concerns[index];
    if (item.isResolved) return; // already resolved; nothing to do
    setState(() {
      _concerns.removeAt(index);
      // Intentionally keep _selectedConcerns unchanged so suggestions don't re-surface immediately
    });
    try {
      await babyProvider.updateConcern(
        concernId: concernId,
        isResolved: true,
        resolvedAt: DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating concern: $e')),
      );
    }
  }

  Future<void> _deleteConcern(String concernId) async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final idx = _concerns.indexWhere((c) => c.id == concernId);
    if (idx == -1) return;
    setState(() {
      _concerns.removeAt(idx);
    });
    try {
      await babyProvider.deleteConcern(concernId: concernId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting concern: $e')),
      );
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _loadForSelectedBaby() async {
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    final baby = babyProvider.selectedBaby;
    setState(() {
      _loading = true;
      _selectedBaby = baby;
    });
    if (baby == null) {
      setState(() {
        _concerns = [];
        _selectedConcerns.clear();
        _loading = false;
      });
      return;
    }
    final concerns = await babyProvider.getConcerns();
    if (!mounted) return;
    setState(() {
      // Only keep unresolved concerns in the list and selection state
      final unresolved = concerns.where((c) => !c.isResolved).toList();
      _concerns = unresolved;
      _selectedConcerns
        ..clear()
        ..addAll(unresolved.map((c) => c.text));
      _loading = false;
    });
  }

  // Suggested concerns based on baby age (copied from onboarding)
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

  Future<void> _addConcernWithText(String text) async {
    if (_selectedBaby == null) return;
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    try {
      await babyProvider.createConcern(
        babyId: _selectedBaby!.id,
        text: text,
        isResolved: false,
        createdAt: DateTime.now(),
      );
      await _loadForSelectedBaby();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving concern: $e')),
      );
    }
  }

  Future<void> _removeConcernByText(String text) async {
    if (_selectedBaby == null) return;
    final babyProvider = Provider.of<BabyProvider>(context, listen: false);
    try {
      // Find concern by text in current list
      final match = _concerns.firstWhere((c) => c.text == text, orElse: () => Concern(id: '', text: '', isResolved: false, createdAt: DateTime.now()));
      if (match.id.isNotEmpty) {
        await babyProvider.deleteConcern(concernId: match.id);
        await _loadForSelectedBaby();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting concern: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContentList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => const AppHeader();
  Widget _buildContentList() {
    final baby = _selectedBaby;
    if (baby == null) {
      return const Center(child: Text('No baby selected'));
    }
    final suggestions = _suggestedConcernsForAge(baby);
    // Potential concerns = suggestions minus those already selected
    final potential = suggestions.where((s) => !_selectedConcerns.contains(s)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current Concerns Section
        Text('Current concerns for ${baby.name}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_concerns.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Text('No current concerns. Add from the suggestions below.'),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            // Match compact style of potential concerns
            childAspectRatio: 6.0,
            children: _concerns.map((concern) {
              return Dismissible(
                key: Key(concern.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(FeatherIcons.trash2, color: Colors.white),
                ),
                onDismissed: (_) => _deleteConcern(concern.id),
                child: GestureDetector(
                  onTap: () => _toggleConcern(concern.id),
                  child: Card(
                    elevation: 1,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      // Brand color border for current concerns
                      side: const BorderSide(color: AppTheme.primaryPurple, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Center(
                        child: Text(
                          concern.text,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.2,
                            color: concern.isResolved ? Colors.grey : AppTheme.textPrimary,
                            decoration: concern.isResolved ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 20),
        // Potential Concerns Section
        const Text('Potential concerns', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          // Make cards half the previous height by doubling the aspect ratio
          childAspectRatio: 6.0,
          children: potential.map((label) {
            return GestureDetector(
              onTap: () async {
                setState(() => _selectedConcerns.add(label));
                await _addConcernWithText(label);
              },
              child: Card(
                elevation: 1,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text('Add your own', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 6.0,
          children: [
            GestureDetector(
              onTap: () async {
                final controller = TextEditingController();
                final text = await showDialog<String>(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      title: const Text('Add custom concern'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(hintText: 'Enter a custom concern'),
                        autofocus: true,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                          child: const Text('Add'),
                        ),
                      ],
                    );
                  },
                );
                if (text != null && text.isNotEmpty && !_selectedConcerns.contains(text)) {
                  setState(() => _selectedConcerns.add(text));
                  await _addConcernWithText(text);
                }
              },
              child: Card(
                elevation: 1,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: Text(
                      '+ Custom concern',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
