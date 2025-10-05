import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/rendering.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:babysteps_app/models/baby.dart';
import 'package:babysteps_app/widgets/app_header.dart';
import 'package:babysteps_app/providers/milestone_provider.dart';
import 'package:babysteps_app/models/milestone.dart';

class _MilestoneMomentsTab extends StatefulWidget {
  final BabyProvider babyProvider;
  final Baby? baby;

  const _MilestoneMomentsTab({required this.babyProvider, required this.baby});

  @override
  State<_MilestoneMomentsTab> createState() => _MilestoneMomentsTabState();
}

class _MilestoneMomentsTabState extends State<_MilestoneMomentsTab> {
  final ImagePicker _picker = ImagePicker();

  late List<_MilestoneMoment> _previousMoments;
  late List<_MilestoneOption> _milestoneOptions;

  bool _isWizardActive = false;
  _WizardStep _currentStep = _WizardStep.selectMilestone;

  _MilestoneOption? _selectedMilestone;
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoAsset;
  bool _isPickingPhoto = false;
  final TextEditingController _storyController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();
  final TextEditingController _hashtagsController = TextEditingController();
  final TextEditingController _customMilestoneController = TextEditingController();
  final TextEditingController _customAnniversaryHighlightController = TextEditingController();
  final TextEditingController _anniversaryDelightsController = TextEditingController();
  final Set<String> _selectedAnniversaryMilestones = <String>{};
  final GlobalKey _previewBoundaryKey = GlobalKey();
  Uint8List? _previewImageBytes;
  String? _lastPreviewSignature;
  bool _isRenderingPreviewImage = false;
  bool _pendingPreviewCapture = false;

  DateTime _lastOpenedAt = DateTime.now().subtract(const Duration(days: 2));

  final List<String> _samplePhotoAssets = const [
    'assets/images/boy.jpg',
    'assets/images/girl.jpg',
  ];

  List<_MilestoneOption> get _standardMilestoneOptions =>
      _milestoneOptions.where((option) => !option.isAnniversary).toList();

  @override
  void initState() {
    super.initState();
    _milestoneOptions = _mockMilestoneOptions();
    _previousMoments = _mockPreviousMoments();
    if (_previousMoments.isEmpty) {
      _startWizard();
    }
  }

  @override
  void didUpdateWidget(covariant _MilestoneMomentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.baby != widget.baby && widget.baby != null) {
      setState(() {
        _milestoneOptions = _mockMilestoneOptions();
        _previousMoments = _mockPreviousMoments();
        if (_previousMoments.isEmpty) {
          _startWizard();
        }
      });
    }
  }

  @override
  void dispose() {
    _storyController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _contextController.dispose();
    _hashtagsController.dispose();
    _customMilestoneController.dispose();
    _customAnniversaryHighlightController.dispose();
    _anniversaryDelightsController.dispose();
    super.dispose();
  }

  void _exitWizard() {
    setState(() {
      _storyController.clear();
      _titleController.clear();
      _locationController.clear();
      _contextController.clear();
      _hashtagsController.clear();
      _customMilestoneController.clear();
      _customAnniversaryHighlightController.clear();
      _anniversaryDelightsController.clear();
      _selectedAnniversaryMilestones.clear();
      _lastOpenedAt = DateTime.now();
    });
  }

  void _saveMoment() {
    final milestone = _selectedMilestone;
    if (milestone == null) {
      return;
    }
    final story = _storyController.text.trim();

    final newMoment = _MilestoneMoment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : milestone.title,
      description: story,
      capturedAt: DateTime.now(),
      shareability: milestone.shareability,
      priority: milestone.priority,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : milestone.location,
      photoBytes: _selectedPhotoBytes,
      photoAssetPath: _selectedPhotoAsset,
      stickers: _resolvedHashtags(milestone.stickers),
      shareContext: _contextController.text.trim().isNotEmpty ? _contextController.text.trim() : milestone.shareContext,
      highlights: milestone.isAnniversary ? _selectedAnniversaryMilestones.toList(growable: false) : const [],
      delights: milestone.isAnniversary ? _currentDelights() : const [],
    );

    setState(() {
      _previousMoments = [newMoment, ..._previousMoments];
      _exitWizard();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved “${milestone.title}” to milestone moments!')),
    );
  }

  List<_MilestoneOption> _generateAnniversaryOptions(DateTime now) {
    // Get baby's birthdate if available
    final baby = widget.baby;
    if (baby == null || baby.birthdate == null) {
      return [];
    }

    final birthdate = baby.birthdate!;
    final ageInDays = now.difference(birthdate).inDays;

    final schedule = <Duration, String>{
      const Duration(days: 7): '1 Week Old',
      const Duration(days: 14): '2 Weeks Old',
      const Duration(days: 21): '3 Weeks Old',
      const Duration(days: 30): '1 Month Old',
      const Duration(days: 60): '2 Months Old',
      const Duration(days: 90): '3 Months Old',
      const Duration(days: 120): '4 Months Old',
      const Duration(days: 150): '5 Months Old',
      const Duration(days: 180): '6 Months Old',
      const Duration(days: 365): '1 Year Old',
      const Duration(days: 548): '18 Months Old',
      const Duration(days: 730): '2 Years Old',
      const Duration(days: 1095): '3 Years Old',
      const Duration(days: 1460): '4 Years Old',
      const Duration(days: 1825): '5 Years Old',
    };

    // Find the most recent anniversary that has passed
    Duration? mostRecentDuration;
    String? mostRecentLabel;
    
    for (final entry in schedule.entries) {
      if (ageInDays >= entry.key.inDays) {
        if (mostRecentDuration == null || entry.key.inDays > mostRecentDuration.inDays) {
          mostRecentDuration = entry.key;
          mostRecentLabel = entry.value;
        }
      }
    }

    // Return only the most recent anniversary
    if (mostRecentDuration == null || mostRecentLabel == null) {
      return [];
    }

    final annDate = birthdate.add(mostRecentDuration);
    return [
      _MilestoneOption(
        id: 'ann-${mostRecentLabel.toLowerCase().replaceAll(' ', '-')}',
        title: mostRecentLabel,
        summary: 'Celebrate ${mostRecentLabel.toLowerCase()} with a collage of highlights.',
        shareability: 5,
        priority: 5,
        lastUpdated: annDate,
        location: 'Custom celebration spot',
        shareContext: 'Family & friends celebration',
        stickers: const ['#AnniversaryMoment', '#MilestoneMemories'],
        isAnniversary: true,
        anniversaryDate: annDate,
        associatedMilestones: const [
          'Favorite giggle',
          'Biggest smile',
          'Sweetest snuggle',
          'Proud parent moment',
          'Funniest story'
        ],
      ),
    ];
  }

  Widget _buildCustomMilestoneComposer(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create custom milestone',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customMilestoneController,
                decoration: const InputDecoration(
                  hintText: 'e.g. First trip to the zoo',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addCustomMilestone(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _addCustomMilestone,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA67EB7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Custom milestones appear below. They stay saved for this session.',
          style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
        ),
      ],
    );
  }

  void _addCustomMilestone() {
    final text = _customMilestoneController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a milestone name before adding.')),
      );
      return;
    }
    final now = DateTime.now();
    final customOption = _MilestoneOption(
      id: 'custom-${now.millisecondsSinceEpoch}',
      title: text,
      summary: 'Captured memory created by you.',
      shareability: 4,
      priority: 4,
      lastUpdated: now,
      location: 'Custom location',
      shareContext: 'Custom milestone',
      stickers: const ['#CustomMoment'],
      storyPrompts: const [],
    );

    setState(() {
      _milestoneOptions = [customOption, ..._milestoneOptions];
      _customMilestoneController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added “${customOption.title}” to milestones.')),
    );
  }

  void _addCustomAnniversaryHighlight() {
    final text = _customAnniversaryHighlightController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a highlight before adding.')),
      );
      return;
    }
    if (_selectedAnniversaryMilestones.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can select up to 5 milestones for an anniversary.')),
      );
      return;
    }
    setState(() {
      _selectedAnniversaryMilestones.add(text);
      _customAnniversaryHighlightController.clear();
    });
  }

  List<String> _currentDelights() {
    return _anniversaryDelightsController.text
        .split(RegExp(r'[\n;]'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.baby == null) {
      return const _NoBabySelectedMessage();
    }

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isWizardActive ? _buildWizard() : _buildPreviousMomentsList(),
        ),
        if (_isWizardActive)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _goToPreviousStep,
                    icon: const Icon(FeatherIcons.arrowLeft, size: 16),
                    label: const Text('Back'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canProceed ? _advanceWizard : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(_primaryButtonLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviousMomentsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderRow(),
        const SizedBox(height: 20),
        if (_previousMoments.isEmpty)
          _buildEmptyState()
        else ...[
          for (final moment in _previousMoments) ...[
            _MomentCard(
              moment: moment,
              onTap: () => _openMomentPreview(moment),
              onDelete: () => _promptDeleteMoment(moment),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildHeaderRow() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          'Moments',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFA67EB7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onPressed: _startWizard,
          icon: const Icon(FeatherIcons.plusCircle, size: 16),
          label: const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(FeatherIcons.camera, color: Color(0xFF7C3AED)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No milestone moments yet',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Celebrate the latest milestone with a story, photo, and shareable keepsake.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _startWizard,
            child: const Text('Start milestone moment wizard'),
          ),
        ],
      ),
    );
  }

  Widget _buildWizard() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _buildWizardProgress(),
        const SizedBox(height: 16),
        _buildWizardContent(),
      ],
    );
  }

  Widget _buildWizardProgress() {
    final steps = _WizardStep.values;
    return Row(
      children: [
        for (final step in steps) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 6,
              margin: EdgeInsets.only(right: step == steps.last ? 0 : 6),
              decoration: BoxDecoration(
                gradient: _wizardStepIndex(step) <= _wizardStepIndex(_currentStep)
                    ? const LinearGradient(
                        colors: [Color(0xFFE6D7F2), Color(0xFFC8A2C8)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: _wizardStepIndex(step) <= _wizardStepIndex(_currentStep)
                    ? null
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool get _canProceed {
    switch (_currentStep) {
      case _WizardStep.selectMilestone:
        final selected = _selectedMilestone;
        if (selected == null) {
          return false;
        }
        if (selected.isAnniversary) {
          return _selectedAnniversaryMilestones.isNotEmpty;
        }
        return true;
      case _WizardStep.selectPhoto:
        return _selectedPhotoBytes != null || _selectedPhotoAsset != null;
      case _WizardStep.selectStory:
        return _storyController.text.trim().isNotEmpty;
      case _WizardStep.preview:
        return true;
    }
  }
  Widget _buildSelectMilestone() {
    final theme = Theme.of(context);
    final sorted = [..._milestoneOptions]
      ..sort((a, b) {
        // Anniversary options surface first by date, then recency.
        if (a.isAnniversary != b.isAnniversary) {
          return a.isAnniversary ? -1 : 1;
        }
        if (a.isAnniversary && b.isAnniversary) {
          return b.anniversaryDate!.compareTo(a.anniversaryDate!);
        }

        final aRecent = a.lastNotedAfter(_lastOpenedAt);
        final bRecent = b.lastNotedAfter(_lastOpenedAt);
        if (aRecent != bRecent) {
          return aRecent ? -1 : 1;
        }
        return b.shareability.compareTo(a.shareability);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1 · Choose a milestone',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'We surface the most shareable wins since your last visit, then favourites overall.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 16),
        _buildCustomMilestoneComposer(theme),
        const SizedBox(height: 16),
        if (sorted.any((option) => option.isAnniversary)) ...[
          Text(
            'Special anniversaries',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...sorted
              .where((option) => option.isAnniversary)
              .map(
                (option) => _AnniversaryCard(
                  option: option,
                  isSelected: option == _selectedMilestone,
                  selectedMilestones: _selectedAnniversaryMilestones,
                  onOpenMilestoneSelector: _showMilestoneSelector,
                  onTap: () {
                    setState(() {
                      _selectedMilestone = option;
                      _applyDefaultsForOption(option);
                    });
                    _showMilestoneSelector();
                  },
                ),
              )
              .toList(),
          const SizedBox(height: 16),
          Text(
            'Other milestones',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
        ],
        ...sorted
            .where((option) => !option.isAnniversary)
            .map((option) {
          final isSelected = option == _selectedMilestone;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMilestone = option;
                _selectedAnniversaryMilestones.clear();
                _storyController.clear();
                _applyDefaultsForOption(option);
              });
            },
            child: _MilestoneOptionCard(
              option: option,
              isSelected: isSelected,
              lastOpenedAt: _lastOpenedAt,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSelectPhoto() {
    final milestone = _selectedMilestone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2 · Choose a photo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (milestone != null)
          Text(
            milestone.title,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _samplePhotoAssets.map((assetPath) {
            final isSelected = _selectedPhotoAsset == assetPath && _selectedPhotoBytes == null;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPhotoAsset = assetPath;
                  _selectedPhotoBytes = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 140,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? const Color(0xFFA67EB7) : const Color(0xFFE5E7EB), width: 2),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: const Color(0xFFA67EB7).withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 12),
                      ),
                  ],
                  image: DecorationImage(image: AssetImage(assetPath), fit: BoxFit.cover),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        if (_selectedPhotoBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(
              _selectedPhotoBytes!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else if (_selectedPhotoAsset != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              _selectedPhotoAsset!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _isPickingPhoto ? null : _pickPhotoFromDevice,
          icon: _isPickingPhoto
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(FeatherIcons.upload),
          label: const Text('Upload from device'),
        ),
      ],
    );
  }

  Widget _buildSelectStory() {
    final milestone = _selectedMilestone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 3 · Add your story',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          milestone != null
              ? milestone.isAnniversary
                  ? 'Create a keepsake for ${milestone.title}. Select up to 5 milestone highlights and add delights to feature.'
                  : 'Tell the story of “${milestone.title}” in your own words.'
              : 'Tell the story in your own words.',
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Card title',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFA67EB7), width: 2),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _locationController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFA67EB7), width: 2),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _contextController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Subtitle / context',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFA67EB7), width: 2),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hashtagsController,
          decoration: const InputDecoration(
            labelText: 'Hashtags',
            hintText: '#ProudMoment #StorytimeMagic',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFA67EB7), width: 2),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _storyController,
          maxLines: 6,
          minLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Custom message',
            hintText: 'Detail the story behind this. Consider noting their favourite activities, people, and foods.',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFA67EB7), width: 2),
            ),
            hintStyle: TextStyle(color: Color(0xFF9FA8DA)),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    final milestone = _selectedMilestone;
    if (milestone == null) {
      return const SizedBox.shrink();
    }
    final story = _storyController.text.trim();
    final title = _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : milestone.title;
    final location = _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : milestone.location;
    final shareContext = (_contextController.text.trim().isNotEmpty ? _contextController.text.trim() : milestone.shareContext) ?? '';
    final hashtags = _resolvedHashtags(milestone.stickers);
    final isAnniversary = milestone.isAnniversary;
    final milestoneHighlights = isAnniversary
        ? (_selectedAnniversaryMilestones.isNotEmpty
            ? _selectedAnniversaryMilestones.toList()
            : milestone.associatedMilestones)
        : const <String>[];
    final delights = isAnniversary ? _currentDelights() : const <String>[];
    final Widget previewCard = isAnniversary
        ? _AnniversaryPreviewCard(
            babyName: widget.baby?.name ?? 'Moment',
            momentTitle: title,
            story: story,
            location: location,
            shareContext: shareContext,
            ageLabel: widget.baby != null ? _ageLabel(widget.baby!) : '—',
            photoBytes: _selectedPhotoBytes,
            assetPath: _selectedPhotoAsset,
            stickers: hashtags,
            milestoneHighlights: milestoneHighlights,
            delights: delights,
          )
        : _StandardMomentPreviewCard(
            babyName: widget.baby?.name ?? 'Moment',
            momentTitle: title,
            story: story,
            location: location,
            shareContext: shareContext,
            ageLabel: widget.baby != null ? _ageLabel(widget.baby!) : '—',
            photoBytes: _selectedPhotoBytes,
            assetPath: _selectedPhotoAsset,
            stickers: hashtags,
          );

    final String signature = _buildPreviewSignature(
      isAnniversary: isAnniversary,
      title: title,
      story: story,
      location: location,
      shareContext: shareContext,
      hashtags: hashtags,
      highlights: milestoneHighlights,
      delights: delights,
      photoBytes: _selectedPhotoBytes,
      photoAsset: _selectedPhotoAsset,
    );

    if (_lastPreviewSignature != signature) {
      _lastPreviewSignature = signature;
      _pendingPreviewCapture = true;
      if (!_isRenderingPreviewImage) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _capturePreviewImage());
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 4 · Preview & share',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Here’s the keepsake card we’ll save and share.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 420,
          child: Center(
            child: _previewImageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Image.memory(
                        _previewImageBytes!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Container(
                    width: 260,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _isRenderingPreviewImage
                        ? const CircularProgressIndicator()
                        : const Text('Rendering preview...'),
                  ),
          ),
        ),
        SizedBox.shrink(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: RepaintBoundary(
              key: _previewBoundaryKey,
              child: SizedBox(
                width: 1080,
                height: 1920,
                child: previewCard,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: const Color(0xFFA67EB7),
                  side: const BorderSide(color: Color(0xFFA67EB7), width: 1.4),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download coming soon.')),
                  );
                },
                icon: const Icon(FeatherIcons.download, size: 16),
                label: const Text('Download image'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFA67EB7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share flow coming soon.')),
                  );
                },
                icon: const Icon(FeatherIcons.share2, size: 16),
                label: const Text('Share now'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String get _primaryButtonLabel {
    switch (_currentStep) {
      case _WizardStep.selectMilestone:
        return 'Next: Pick photo';
      case _WizardStep.selectPhoto:
        return 'Next: Story text';
      case _WizardStep.selectStory:
        return 'Preview card';
      case _WizardStep.preview:
        return 'Save milestone moment';
    }
  }

  String _ageLabel(Baby baby) {
    final now = DateTime.now();
    final years = now.difference(baby.birthdate).inDays ~/ 365;
    final months = (now.difference(baby.birthdate).inDays % 365) ~/ 30;
    if (years > 0) {
      return '${years}y ${months}m';
    }
    return '${months} mo';
  }

  List<_MilestoneMoment> _mockPreviousMoments() {
    if (widget.baby == null) {
      return const [];
    }
    final babyName = widget.baby!.name.split(' ').first;
    final now = DateTime.now();
    return [
      _MilestoneMoment(
        id: '1',
        title: 'Two-word talker',
        description: 'While flipping through the moon book, $babyName whispered “mama please” and we cheered.',
        capturedAt: now.subtract(const Duration(days: 5)),
        shareability: 5,
        priority: 5,
        location: 'Moonlight Nursery',
        shareContext: 'Storytime magic · Cozy chair corner',
        photoAssetPath: 'assets/images/girl.jpg',
        stickers: const ['#ProudMoment', '#StorytimeMagic'],
      ),
      _MilestoneMoment(
        id: '2',
        title: 'Independent stander',
        description: '$babyName balanced for ten whole seconds all by themselves!',
        capturedAt: now.subtract(const Duration(days: 12)),
        shareability: 4,
        priority: 5,
        location: 'Living room play mat',
        shareContext: 'Captured by Dad',
        photoAssetPath: 'assets/images/boy.jpg',
        stickers: const ['#BigKidEnergy'],
      ),
    ];
  }

  List<_MilestoneOption> _mockMilestoneOptions() {
    final now = DateTime.now();
    return [
      ..._generateAnniversaryOptions(now),
      _MilestoneOption(
        id: 'a',
        title: 'First word: “Mama”',
        summary: 'Clear two-word requests bubbling up during bedtime routines.',
        shareability: 5,
        priority: 5,
        lastUpdated: now.subtract(const Duration(days: 1)),
        location: 'Moonlight Nursery',
        shareContext: 'Bedtime story · Cozy chair corner',
        stickers: const ['#ProudMoment', '#MamaSaidIt', '#StorytimeMagic'],
      ),
      _MilestoneOption(
        id: 'b',
        title: 'Independent stander',
        summary: 'Balance and core strength shining during living-room practice laps.',
        shareability: 4,
        priority: 5,
        lastUpdated: now.subtract(const Duration(days: 6)),
        location: 'Living room play mat',
        shareContext: 'Captured by Dad',
        stickers: const ['#BalanceBoss', '#BigKidEnergy'],
      ),
      _MilestoneOption(
        id: 'c',
        title: 'Finger food feeder',
        summary: 'Pincher grip perfected with blueberry tastings and messy smiles.',
        shareability: 4,
        priority: 4,
        lastUpdated: now.subtract(const Duration(days: 2)),
        location: 'Kitchen highchair',
        shareContext: 'Snack time · Sunshine window seat',
        stickers: const ['#SnackAttack', '#LittleFoodie'],
      ),
    ];
  }

  void _openMomentPreview(_MilestoneMoment moment) {
    final imageWidget = moment.photoBytes != null
        ? Image.memory(moment.photoBytes!, fit: BoxFit.cover)
        : (moment.photoAssetPath != null
            ? Image.asset(moment.photoAssetPath!, fit: BoxFit.cover)
            : null);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: SizedBox(
                    height: 360,
                    child: imageWidget ??
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFE6D7F2), Color(0xFFC8A2C8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(FeatherIcons.image, color: Colors.white, size: 48),
                                SizedBox(height: 12),
                                Text(
                                  'No photo available',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        moment.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('MMM d, yyyy').format(moment.capturedAt),
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        moment.description,
                        style: const TextStyle(height: 1.5, color: Color(0xFF4B5563)),
                      ),
                      const SizedBox(height: 12),
                      if (moment.shareContext != null)
                        Text(
                          moment.shareContext!,
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                        ),
                      if (moment.stickers.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: moment.stickers
                              .map(
                                (sticker) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    sticker,
                                    style: const TextStyle(color: Color(0xFF4C1D95), fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (moment.highlights.isNotEmpty) ...[
                        const Text(
                          'Highlights',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: moment.highlights
                              .map(
                                (highlight) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    highlight,
                                    style: const TextStyle(color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(FeatherIcons.x),
                          label: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _resolvedHashtags(List<String> fallback) {
    final raw = _hashtagsController.text;
    final tokens = raw
        .split(RegExp(r'[\s,]+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .map((token) => token.startsWith('#') ? token : '#$token')
        .toList();
    final deduped = <String>[];
    final seen = <String>{};
    for (final tag in tokens) {
      if (seen.add(tag.toLowerCase())) {
        deduped.add(tag);
      }
    }
    return deduped.isNotEmpty ? deduped : fallback;
  }

  void _applyDefaultsForOption(_MilestoneOption option) {
    _titleController.text = option.title;
    _locationController.text = option.location;
    _contextController.text = option.shareContext;
    _hashtagsController.text = option.stickers.isEmpty ? '' : option.stickers.join(' ');
    if (option.isAnniversary) {
      // For anniversaries, start with no highlights selected.
      _selectedAnniversaryMilestones.clear();
      _customAnniversaryHighlightController.clear();
    } else {
      _selectedAnniversaryMilestones.clear();
    }
  }

  void _startWizard() {
    setState(() {
      _isWizardActive = true;
      _currentStep = _WizardStep.selectMilestone;
      _selectedMilestone = null;
      _selectedPhotoBytes = null;
      _selectedPhotoAsset = null;
      _storyController.clear();
      _titleController.clear();
      _locationController.clear();
      _contextController.clear();
      _hashtagsController.clear();
      _selectedAnniversaryMilestones.clear();
    });
  }

  void _goToPreviousStep() {
    if (_currentStep == _WizardStep.selectMilestone) {
      _exitWizard();
      return;
    }
    setState(() {
      final index = _WizardStep.values.indexOf(_currentStep);
      if (index > 0) {
        _currentStep = _WizardStep.values[index - 1];
      }
    });
  }

  void _advanceWizard() {
    if (_currentStep == _WizardStep.preview) {
      _saveMoment();
      return;
    }
    setState(() {
      final index = _WizardStep.values.indexOf(_currentStep);
      if (index < _WizardStep.values.length - 1) {
        _currentStep = _WizardStep.values[index + 1];
        if (_currentStep == _WizardStep.selectStory) {
          _hashtagsController.clear();
        }
      }
    });
  }

  int _wizardStepIndex(_WizardStep step) {
    return _WizardStep.values.indexOf(step);
  }

  Widget _buildWizardContent() {
    switch (_currentStep) {
      case _WizardStep.selectMilestone:
        return _buildSelectMilestone();
      case _WizardStep.selectPhoto:
        return _buildSelectPhoto();
      case _WizardStep.selectStory:
        return _buildSelectStory();
      case _WizardStep.preview:
        return _buildPreviewCard();
    }
  }

  Future<void> _pickPhotoFromDevice() async {
    if (_isPickingPhoto) return;
    setState(() {
      _isPickingPhoto = true;
    });

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedPhotoBytes = bytes;
          _selectedPhotoAsset = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  Future<void> _showMilestoneSelector() async {
    if (widget.baby == null) return;

    // Ensure milestone catalog is loaded (for short_name/shareability)
    final milestoneProvider = Provider.of<MilestoneProvider>(context, listen: false);
    if (milestoneProvider.milestones.isEmpty) {
      try { await milestoneProvider.loadMilestones(); } catch (_) {}
    }

    // Map milestone meta by title and ID for flexible lookups
    final Map<String, Milestone> metaByTitle = {
      for (final m in milestoneProvider.milestones) m.title: m,
    };
    final Map<String, Milestone> metaById = {
      for (final m in milestoneProvider.milestones) m.id: m,
    };

    // Fetch assessments including discounted to capture onboarding ticks
    List<Map<String, dynamic>> milestoneAssessments = const <Map<String, dynamic>>[];
    try {
      milestoneAssessments = await widget.babyProvider.getMilestoneAssessments(includeDiscounted: true);
    } catch (_) {}

    // Map achieved_at by title if provided by the view
    final achievedAtByTitle = <String, DateTime?>{};
    final achievedAtById = <String, DateTime?>{};
    final Map<String, Map<String, dynamic>> assessmentById = {};
    for (final a in milestoneAssessments) {
      final t = (a['title'] as String?) ?? '';
      if (t.isEmpty) continue;
      final at = a['achieved_at'] is String ? DateTime.tryParse(a['achieved_at'] as String) : null;
      achievedAtByTitle[t] = at;

      final milestoneId = (a['milestone_id'] as String?) ?? '';
      if (milestoneId.isNotEmpty) {
        achievedAtById[milestoneId] = at;
        assessmentById[milestoneId] = a;
      }
    }

    // Build from baby's completed milestones (legacy JSON on babies)
    final completedTitles = List<String>.from(widget.baby!.completedMilestones);
    final completedRows = completedTitles.map((token) {
      final meta = metaById[token] ?? metaByTitle[token];
      final assessment = assessmentById[token];
      final titleFromAssessment = (assessment?[ 'title' ] as String?)?.trim();
      final fallbackTitle = titleFromAssessment?.isNotEmpty == true ? titleFromAssessment! : token;
      final title = meta?.title ?? fallbackTitle;
      final shortName = (meta?.shortName.isNotEmpty ?? false)
          ? meta!.shortName
          : ((assessment?['short_name'] as String?)?.trim().isNotEmpty == true
              ? (assessment?['short_name'] as String).trim()
              : title);
      final achievedAt = achievedAtById[meta?.id ?? token] ?? achievedAtByTitle[title];
      final shareability = meta?.shareability ?? (assessment?['shareability'] as int? ?? 0);
      return <String, dynamic>{
        'id': meta?.id ?? token,
        'title': title,
        'short_name': shortName,
        'shareability': shareability,
        'achieved_at': achievedAt?.toIso8601String(),
      };
    }).toList();

    // If none found via legacy field, fall back to assessments with status achieved
    if (completedRows.isEmpty && milestoneAssessments.isNotEmpty) {
      for (final a in milestoneAssessments) {
        final status = (a['status'] as String?)?.toLowerCase();
        final achievedAtStr = a['achieved_at'] as String?;
        final achievedAt = achievedAtStr != null ? DateTime.tryParse(achievedAtStr) : null;
        final looksAchieved = achievedAt != null ||
            (status != null && (
              status.contains('achiev') || status.contains('complete') || status.contains('done')
            ));
        if (!looksAchieved) continue;

        final title = (a['title'] as String?) ?? '';
        if (title.isEmpty) continue;
        final milestoneId = (a['milestone_id'] as String?) ?? '';
        final meta = milestoneId.isNotEmpty ? (metaById[milestoneId] ?? metaByTitle[title]) : metaByTitle[title];
        final shortName = (meta?.shortName.isNotEmpty ?? false)
            ? meta!.shortName
            : ((a['short_name'] as String?)?.trim().isNotEmpty == true
                ? (a['short_name'] as String).trim()
                : title);
        completedRows.add({
          'id': meta?.id ?? (milestoneId.isNotEmpty ? milestoneId : title),
          'title': meta?.title ?? title,
          'short_name': shortName,
          'shareability': meta?.shareability ?? (a['shareability'] as int? ?? 0),
          'achieved_at': achievedAt?.toIso8601String() ?? achievedAtStr,
        });
      }
    }

    // Determine which highlights were used in previous anniversary moments (we store short_name strings)
    final usedMilestoneIds = _previousMoments
        .where((moment) => moment.highlights.isNotEmpty)
        .expand((moment) => moment.highlights)
        .toSet();

    // Sort: unused first, then by shareability desc, then achieved_at desc
    completedRows.sort((a, b) {
      final aShortName = a['short_name'] as String? ?? a['title'] as String? ?? '';
      final bShortName = b['short_name'] as String? ?? b['title'] as String? ?? '';

      final aUsed = usedMilestoneIds.contains(aShortName);
      final bUsed = usedMilestoneIds.contains(bShortName);

      if (aUsed != bUsed) {
        return aUsed ? 1 : -1; // Unused first
      }

      final aShareability = a['shareability'] as int? ?? 0;
      final bShareability = b['shareability'] as int? ?? 0;
      final shareabilityCompare = bShareability.compareTo(aShareability);
      if (shareabilityCompare != 0) {
        return shareabilityCompare;
      }

      final aDate = a['achieved_at'] is String ? DateTime.tryParse(a['achieved_at'] as String) : null;
      final bDate = b['achieved_at'] is String ? DateTime.tryParse(b['achieved_at'] as String) : null;
      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
      if (aDate != null) return -1;
      if (bDate != null) return 1;
      return 0;
    });

    if (!mounted) return;

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => _MilestoneSelectorDialog(
        completedMilestones: completedRows,
        selectedMilestones: Set.from(_selectedAnniversaryMilestones),
        usedMilestoneIds: usedMilestoneIds,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedAnniversaryMilestones
          ..clear()
          ..addAll(result);
      });
    }
  }

  Future<void> _promptDeleteMoment(_MilestoneMoment moment) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete milestone moment?'),
            content: Text('This will remove “${moment.title}” from your milestone moments list.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted || !confirmed) return;

    setState(() {
      _previousMoments = _previousMoments.where((m) => m.id != moment.id).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted “${moment.title}”.')),
    );
  }

  String _buildPreviewSignature({
    required bool isAnniversary,
    required String title,
    required String story,
    required String location,
    required String shareContext,
    required List<String> hashtags,
    required List<String> highlights,
    required List<String> delights,
    required Uint8List? photoBytes,
    required String? photoAsset,
  }) {
    return [
      isAnniversary.toString(),
      title,
      story,
      location,
      shareContext,
      hashtags.join('|'),
      highlights.join('|'),
      delights.join('|'),
      photoBytes?.lengthInBytes.toString() ?? '0',
      photoAsset ?? '',
    ].join('::');
  }

  Future<void> _capturePreviewImage() async {
    if (!mounted) return;
    if (_isRenderingPreviewImage) {
      _pendingPreviewCapture = true;
      return;
    }

    final boundary = _previewBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      _pendingPreviewCapture = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _capturePreviewImage());
      return;
    }

    setState(() {
      _isRenderingPreviewImage = true;
    });

    try {
      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (!mounted) return;
      setState(() {
        _previewImageBytes = bytes;
      });
    } catch (e) {
      debugPrint('Error generating preview image: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isRenderingPreviewImage = false;
      });

      if (_pendingPreviewCapture) {
        _pendingPreviewCapture = false;
        WidgetsBinding.instance.addPostFrameCallback((_) => _capturePreviewImage());
      }
    }
  }
}

class _MilestoneMoment {
  final String id;
  final String title;
  final String description;
  final DateTime capturedAt;
  final int shareability;
  final int priority;
  final String location;
  final String? shareContext;
  final Uint8List? photoBytes;
  final String? photoAssetPath;
  final List<String> stickers;
  final List<String> highlights;
  final List<String> delights;

  const _MilestoneMoment({
    required this.id,
    required this.title,
    required this.description,
    required this.capturedAt,
    required this.shareability,
    required this.priority,
    required this.location,
    this.shareContext,
    this.photoBytes,
    this.photoAssetPath,
    this.stickers = const [],
    this.highlights = const [],
    this.delights = const [],
  });
}

class _MilestoneOption {
  final String id;
  final String title;
  final String summary;
  final int shareability;
  final int priority;
  final DateTime lastUpdated;
  final String location;
  final String shareContext;
  final List<String> stickers;
  final List<String> storyPrompts;
  final bool isAnniversary;
  final DateTime? anniversaryDate;
  final List<String> associatedMilestones;

  const _MilestoneOption({
    required this.id,
    required this.title,
    required this.summary,
    required this.shareability,
    required this.priority,
    required this.lastUpdated,
    required this.location,
    required this.shareContext,
    this.stickers = const [],
    this.storyPrompts = const [],
    this.isAnniversary = false,
    this.anniversaryDate,
    this.associatedMilestones = const [],
  });

  bool lastNotedAfter(DateTime threshold) => lastUpdated.isAfter(threshold);
}

class _AnniversaryCard extends StatelessWidget {
  final _MilestoneOption option;
  final bool isSelected;
  final Set<String> selectedMilestones;
  final VoidCallback onOpenMilestoneSelector;
  final VoidCallback? onTap;

  const _AnniversaryCard({
    required this.option,
    required this.isSelected,
    required this.selectedMilestones,
    required this.onOpenMilestoneSelector,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFA67EB7) : const Color(0xFFE5E7EB)),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFFA67EB7).withOpacity(0.16),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        option.summary,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onOpenMilestoneSelector,
                icon: const Icon(FeatherIcons.edit3, size: 16),
                label: Text(selectedMilestones.isEmpty
                    ? 'Choose milestones to highlight'
                    : 'Edit milestones (${selectedMilestones.length})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFA67EB7),
                  side: const BorderSide(color: Color(0xFFA67EB7)),
                ),
              ),
              if (selectedMilestones.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedMilestones.map((milestone) {
                    return Chip(
                      label: Text(milestone),
                      backgroundColor: const Color(0xFFE6D7F2),
                      labelStyle: const TextStyle(
                        color: Color(0xFF4C1D95),
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MilestoneSelectorDialog extends StatefulWidget {
  final List<Map<String, dynamic>> completedMilestones;
  final Set<String> selectedMilestones;
  final Set<String> usedMilestoneIds;

  const _MilestoneSelectorDialog({
    required this.completedMilestones,
    required this.selectedMilestones,
    required this.usedMilestoneIds,
  });

  @override
  State<_MilestoneSelectorDialog> createState() => _MilestoneSelectorDialogState();
}

class _MilestoneSelectorDialogState extends State<_MilestoneSelectorDialog> {
  late Set<String> _selected;
  final TextEditingController _customController = TextEditingController();
  int _displayCount = 20;
  late List<Map<String, dynamic>> _entries;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedMilestones);
    _entries = List<Map<String, dynamic>>.from(widget.completedMilestones);
  }

  void _loadMore() {
    setState(() {
      _displayCount += 20;
    });
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _addCustomMilestone() {
    final text = _customController.text.trim();
    if (text.isEmpty) return;
    
    if (_selected.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can select up to 5 milestones')),
      );
      return;
    }
    
    final existingIndex = _entries.indexWhere((entry) {
      final entryLabel = (entry['short_name'] as String?) ?? (entry['title'] as String?) ?? '';
      return entryLabel.toLowerCase() == text.toLowerCase();
    });

    setState(() {
      if (existingIndex == -1) {
        _entries.insert(0, {
          'title': text,
          'short_name': text,
          'shareability': 0,
          'achieved_at': DateTime.now().toIso8601String(),
          'is_custom': true,
        });
      }

      _selected.add(text);
      _customController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Choose Milestones',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(FeatherIcons.x),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select up to 5 milestones to highlight (${_selected.length}/5)',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            // Custom milestone input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Add custom milestone',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addCustomMilestone(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _selected.length >= 5 ? null : _addCustomMilestone,
                  icon: const Icon(FeatherIcons.plus),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFA67EB7),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Expanded(
              child: _entries.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No completed milestones found.\nComplete some milestones first to add them to your anniversary!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _displayCount < _entries.length
                          ? _displayCount + 1
                          : _entries.length,
                      itemBuilder: (context, index) {
                        // Show "Load More" button
                        if (index == _displayCount && _displayCount < _entries.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: OutlinedButton(
                                onPressed: _loadMore,
                                child: Text(
                                  'Load More (${_entries.length - _displayCount} remaining)',
                                ),
                              ),
                            ),
                          );
                        }

                        final milestone = _entries[index];
                        final shortName = milestone['short_name'] as String? ?? milestone['title'] as String? ?? '';
                        final isSelected = _selected.contains(shortName);
                        final wasUsed = widget.usedMilestoneIds.contains(shortName);
                        final shareability = milestone['shareability'] as int? ?? 0;
                        
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            if (value == true) {
                              if (_selected.length >= 5) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('You can select up to 5 milestones')),
                                );
                                return;
                              }
                              setState(() {
                                _selected.add(shortName);
                              });
                            } else {
                              setState(() {
                                _selected.remove(shortName);
                              });
                            }
                          },
                          title: Text(
                            shortName,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              if (wasUsed)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(right: 8, top: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Previously used',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Score: $shareability',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF4C1D95)),
                                ),
                              ),
                            ],
                          ),
                          activeColor: const Color(0xFFA67EB7),
                          dense: true,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_selected),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFA67EB7),
                  ),
                  child: const Text('Confirm Selection'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneOptionCard extends StatelessWidget {
  final _MilestoneOption option;
  final bool isSelected;
  final DateTime lastOpenedAt;

  const _MilestoneOptionCard({
    required this.option,
    required this.isSelected,
    required this.lastOpenedAt,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isSelected ? const Color(0xFFA67EB7) : const Color(0xFFE5E7EB)),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFFA67EB7).withOpacity(0.16),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      option.summary,
                      style: const TextStyle(color: Color(0xFF6B7280), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ScorePill(label: 'Shareability', value: option.shareability),
                  const SizedBox(height: 8),
                  _ScorePill(label: 'Priority', value: option.priority, color: const Color(0xFFE6C370)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                option.lastUpdated.isAfter(lastOpenedAt)
                    ? FeatherIcons.arrowUpRight
                    : FeatherIcons.clock,
                size: 14,
                color: const Color(0xFFA67EB7),
              ),
              const SizedBox(width: 6),
              Text(
                option.lastUpdated.isAfter(lastOpenedAt)
                    ? 'Updated since last visit'
                    : 'Last celebrated ${DateFormat('MMM d').format(option.lastUpdated)}',
                style: const TextStyle(color: Color(0xFFA67EB7), fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _WizardStep { selectMilestone, selectPhoto, selectStory, preview }

class _ScorePill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ScorePill({required this.label, required this.value, this.color = const Color(0xFF7C3AED)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label · $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  final _MilestoneMoment moment;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _MomentCard({required this.moment, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  DateFormat('MMM d, yyyy').format(moment.capturedAt),
                  style: const TextStyle(color: Color(0xFF4C1D95), fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                moment.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                moment.description,
                style: const TextStyle(color: Color(0xFF4B5563), height: 1.5),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (moment.photoAssetPath != null || moment.photoBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: moment.photoBytes != null
                            ? Image.memory(moment.photoBytes!, fit: BoxFit.cover)
                            : Image.asset(moment.photoAssetPath!, fit: BoxFit.cover),
                      ),
                    ),
                  if (moment.photoAssetPath != null || moment.photoBytes != null)
                    const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: moment.stickers
                              .map(
                                (sticker) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    sticker,
                                    style: const TextStyle(
                                      color: Color(0xFF4B5563),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        if (moment.delights.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: moment.delights
                                .map(
                                  (delight) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF1F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      delight,
                                      style: const TextStyle(
                                        color: Color(0xFF9D174D),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (moment.highlights.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: moment.highlights
                                .map(
                                  (highlight) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6D7F2),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      highlight,
                                      style: const TextStyle(
                                        color: Color(0xFF4C1D95),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sharing “${moment.title}” soon!')),
                      );
                    },
                    icon: const Icon(FeatherIcons.share2, size: 16),
                    label: const Text('Share'),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      icon: const Icon(FeatherIcons.trash, size: 16),
                      label: const Text('Delete'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnniversaryPreviewCard extends StatelessWidget {
  final String babyName;
  final String momentTitle;
  final String story;
  final String location;
  final String shareContext;
  final String ageLabel;
  final Uint8List? photoBytes;
  final String? assetPath;
  final List<String> stickers;
  final List<String> delights;
  final List<String> milestoneHighlights;

  const _AnniversaryPreviewCard({
    required this.babyName,
    required this.momentTitle,
    required this.story,
    required this.location,
    required this.shareContext,
    required this.ageLabel,
    this.photoBytes,
    this.assetPath,
    this.stickers = const [],
    this.delights = const [],
    this.milestoneHighlights = const [],
  });

  @override
  Widget build(BuildContext context) {
    final trimmedLocation = location.trim();
    final trimmedShareContext = shareContext.trim();
    final subtitle = trimmedLocation.isNotEmpty && trimmedShareContext.isNotEmpty
        ? '$trimmedLocation · $trimmedShareContext'
        : (trimmedLocation.isNotEmpty
            ? trimmedLocation
            : (trimmedShareContext.isNotEmpty ? trimmedShareContext : ''));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(54),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF6F4FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.18),
            blurRadius: 48,
            offset: const Offset(0, 32),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top banner
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Anniversary keepsake',
                      style: TextStyle(
                        letterSpacing: 3,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      babyName,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        color: Color(0xFF1F1D36),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.28),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Age today',
                      style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 1.8,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ageLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Celebrated in stars',
                      style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 1.6,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          // Feature stack
          ClipRRect(
            borderRadius: BorderRadius.circular(44),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFDFBFF),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 640,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 7,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(0),
                            child: photoBytes != null
                                ? Image.memory(photoBytes!, fit: BoxFit.cover)
                                : (assetPath != null
                                    ? Image.asset(assetPath!, fit: BoxFit.cover)
                                    : Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Color(0xFFE6D7F2), Color(0xFFC8A2C8)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                      )),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFEEE7FF), Color(0xFFFCE7F3)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Delights',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F1D36),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Expanded(
                                  child: delights.isNotEmpty
                                      ? ListView(
                                          physics: const BouncingScrollPhysics(),
                                          children: delights
                                              .map(
                                                (delight) => Container(
                                                  margin: const EdgeInsets.only(bottom: 16),
                                                  padding: const EdgeInsets.all(18),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(24),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFF7C3AED).withOpacity(0.08),
                                                        blurRadius: 20,
                                                        offset: const Offset(0, 12),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    delight,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF1F1D36),
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(color: const Color(0xFFE0E7FF)),
                                          ),
                                          child: const Text(
                                            'Add delights above to spotlight favourite snacks, activities, and rituals.',
                                            style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Memories strip
                  Container(
                    color: const Color(0xFFF9F7FF),
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Memories',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (milestoneHighlights.isNotEmpty)
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: milestoneHighlights
                                .map(
                                  (highlight) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: const BoxDecoration(
                                      border: Border(left: BorderSide(color: Color(0xFF7C3AED), width: 3)),
                                    ),
                                    child: Text(
                                      highlight,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F1D36),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          )
                        else
                          const Text(
                            'Milestone memories will appear here once you select highlights.',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                      ],
                    ),
                  ),
                  // Story card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          momentTitle,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1D36),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          story.isNotEmpty
                              ? story
                              : 'From curious wobbles to confident twirls, this year has been pure magic.',
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.7,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        if (stickers.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: stickers
                                .map(
                                  (sticker) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      sticker,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4C1D95),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StandardMomentPreviewCard extends StatelessWidget {
  const _StandardMomentPreviewCard({
    required this.babyName,
    required this.momentTitle,
    required this.story,
    required this.location,
    required this.shareContext,
    required this.ageLabel,
    this.photoBytes,
    this.assetPath,
    this.stickers = const [],
  });

  final String babyName;
  final String momentTitle;
  final String story;
  final String location;
  final String shareContext;
  final String ageLabel;
  final Uint8List? photoBytes;
  final String? assetPath;
  final List<String> stickers;

  @override
  Widget build(BuildContext context) {
    final subtitle = [shareContext, location].where((s) => s.trim().isNotEmpty).join(' · ');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF7F5FE)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(48, 48, 48, 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFFF5F3FF), Color(0xFFFEE2E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        momentTitle,
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFB794F4)],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.28),
                        blurRadius: 20,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Share moment',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9A8D), Color(0xFF7C3AED)],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.35),
                        blurRadius: 26,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      ageLabel,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(44),
              border: Border.all(color: Colors.white.withOpacity(0.85), width: 12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.18),
                  blurRadius: 36,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                SizedBox(
                  height: 620,
                  width: double.infinity,
                  child: photoBytes != null
                      ? Image.memory(photoBytes!, fit: BoxFit.cover)
                      : (assetPath != null
                          ? Image.asset(assetPath!, fit: BoxFit.cover)
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFE0E7FF), Color(0xFFFEE2E2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            )),
                ),
                Positioned(
                  left: 32,
                  bottom: 32,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1F1D36).withOpacity(0.12),
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9A8D), Color(0xFFF472B6)],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                          ),
                          child: const Icon(Icons.celebration, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 18),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              momentTitle,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1F1D36)),
                            ),
                            if (subtitle.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  subtitle,
                                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 22),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.isNotEmpty
                      ? story
                      : 'Capture a few sentences to remember the joy of this milestone forever.',
                  style: const TextStyle(color: Color(0xFF4B5563), fontSize: 18, height: 1.6),
                ),
                if (stickers.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: stickers
                        .map(
                          (sticker) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              sticker,
                              style: const TextStyle(color: Color(0xFF4C1D95), fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressScreen extends StatelessWidget {
  final bool showBottomNav;
  const ProgressScreen({this.showBottomNav = false, super.key});

  static const _ok = Color(0xFF46B17B);
  static const _warn = Color(0xFFE6C370);
  static const _bad = Color(0xFFE66A6A);

  @override
  Widget build(BuildContext context) {
    return Consumer<BabyProvider>(
      builder: (context, babyProvider, _) {
        final Baby? baby = babyProvider.selectedBaby;
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  const AppHeader(),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                        ),
                        child: TabBar(
                          labelColor: Colors.white,
                          unselectedLabelColor: const Color(0xFF6B7280),
                          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          dividerColor: Colors.transparent,
                          indicator: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            gradient: LinearGradient(
                              colors: [Color(0xFFE6D7F2), Color(0xFFC8A2C8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          tabs: const [
                            Tab(text: 'General'),
                            Tab(text: 'Vocabulary'),
                            Tab(text: 'Moments'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ProgressTab(
                          babyProvider: babyProvider,
                          baby: baby,
                        ),
                        _VocabularyTab(
                          babyProvider: babyProvider,
                          babyId: baby?.id,
                        ),
                        _MilestoneMomentsTab(
                          babyProvider: babyProvider,
                          baby: baby,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressTab extends StatelessWidget {
  final BabyProvider babyProvider;
  final Baby? baby;

  const _ProgressTab({required this.babyProvider, required this.baby});

  @override
  Widget build(BuildContext context) {
    if (baby == null) {
      return const _NoBabySelectedMessage();
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: babyProvider.getDomainTrackingScores(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load progress right now. Please try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }
        final domainScores = snapshot.data ?? const <Map<String, dynamic>>[];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeroWithPins(
              context,
              baby: baby,
              domainScores: domainScores,
            ),
            const SizedBox(height: 14),
            _ProgressList(domainScores: domainScores),
          ],
        );
      },
    );
  }
}

class _VocabularyTab extends StatefulWidget {
  final BabyProvider babyProvider;
  final String? babyId;

  const _VocabularyTab({required this.babyProvider, required this.babyId});

  @override
  State<_VocabularyTab> createState() => _VocabularyTabState();
}

class _VocabularyTabState extends State<_VocabularyTab> {
  final TextEditingController _wordController = TextEditingController();
  late ConfettiController _confettiController;
  bool _isSubmitting = false;
  bool _isLoadingList = false;
  List<Map<String, dynamic>> _entries = const <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadEntries();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _VocabularyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.babyId != widget.babyId) {
      _loadEntries();
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final babyId = widget.babyId;
    if (babyId == null || babyId.isEmpty) {
      if (!mounted) {
        _entries = const <Map<String, dynamic>>[];
        _isLoadingList = false;
        return;
      }
      setState(() {
        _entries = const <Map<String, dynamic>>[];
        _isLoadingList = false;
      });
      return;
    }
    if (mounted) {
      setState(() {
        _isLoadingList = true;
      });
    }
    try {
      final items = await widget.babyProvider.getBabyVocabulary(babyId: babyId);
      if (!mounted) return;
      setState(() {
        _entries = items;
      });
    } catch (_) {
      // Error already handled via provider error state.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingList = false;
        });
      }
    }
  }

  Future<void> _addWord() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a word before adding.')),
      );
      return;
    }
    if (widget.babyId == null || widget.babyId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a baby to add vocabulary.')),
      );
      return;
    }
    if (_entries.any((entry) =>
        (entry['word'] as String).toLowerCase() == word.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$word" is already recorded.')),
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      await widget.babyProvider.addBabyVocabularyWord(
        word,
        babyId: widget.babyId!,
      );
      if (!mounted) return;
      _wordController.clear();
      FocusScope.of(context).unfocus();
      _confettiController.play();
      await _loadEntries();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to add word right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteEntry(String entryId) async {
    if (widget.babyId == null || widget.babyId!.isEmpty) return;
    setState(() {
      _isSubmitting = true;
    });
    try {
      await widget.babyProvider.deleteBabyVocabularyEntry(
        entryId,
        babyId: widget.babyId!,
      );
      if (!mounted) return;
      await _loadEntries();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to remove that word right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.babyId == null || widget.babyId!.isEmpty) {
      return const _NoBabySelectedMessage();
    }
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _wordController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'New word',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _addWord,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Words learnt',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingList)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_entries.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No vocabulary logged yet.\nStart adding the words your baby says!'
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  final word = entry['word'] as String? ?? '';
                  final recordedRaw = entry['recorded_at'];
                  DateTime? recordedAt;
                  if (recordedRaw is String) {
                    recordedAt = DateTime.tryParse(recordedRaw);
                  } else if (recordedRaw is DateTime) {
                    recordedAt = recordedRaw;
                  }
                  final formattedDate = recordedAt != null
                      ? DateFormat('MMM d, yyyy').format(recordedAt)
                      : 'Date unknown';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                word,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Recorded $formattedDate',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _isSubmitting ? null : () => _deleteEntry(entry['id'] as String),
                          icon: const Icon(Icons.delete_outline, color: Color(0xFF9CA3AF)),
                          tooltip: 'Remove',
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
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 3.14 / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.3,
            shouldLoop: false,
            colors: const [
              Color(0xFFA67EB7),
              Color(0xFFE6D7F2),
              Color(0xFFC8A2C8),
              Color(0xFF7C3AED),
              Color(0xFFFF9A8D),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoBabySelectedMessage extends StatelessWidget {
  const _NoBabySelectedMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Select a baby to view progress and vocabulary.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

Widget _buildHeroWithPins(BuildContext context, {Baby? baby, required List<Map<String, dynamic>> domainScores}) {
  final imgPath = _heroImageForGender(baby?.gender);
  final scores = _DomainScoreHelper(domainScores);
  final name = baby?.name ?? 'Your baby';
  final ageLabel = _formatAgeMonths(baby?.birthdate);
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE9ECEF)),
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      height: 320,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final w = constraints.maxWidth;
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  imgPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF1F3F5),
                      alignment: Alignment.center,
                      child: const Icon(FeatherIcons.image, color: Color(0xFF9CA3AF), size: 40),
                    );
                  },
                ),
              ),
              Positioned(
                left: 16,
                top: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          if (ageLabel.isNotEmpty)
                            Text(
                              ageLabel,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _ProgressPin(
                top: h * 0.12,
                right: w * 0.04,
                label: 'Brain',
                percentile: scores.formattedPercentile('Cognitive'),
                color: scores.colorFor('Cognitive'),
              ),
              _ProgressPin(
                top: h * 0.28,
                right: w * 0.04,
                label: 'Social',
                percentile: scores.formattedPercentile('Social'),
                color: scores.colorFor('Social'),
              ),
              _ProgressPin(
                top: h * 0.44,
                right: w * 0.04,
                label: 'Speech',
                percentile: scores.formattedPercentile('Communication'),
                color: scores.colorFor('Communication'),
              ),
              _ProgressPin(
                top: h * 0.60,
                right: w * 0.04,
                label: 'Gross Motor',
                percentile: scores.formattedPercentile('Motor'),
                color: scores.colorFor('Motor'),
              ),
              _ProgressPin(
                top: h * 0.76,
                right: w * 0.04,
                label: 'Fine Motor',
                percentile: scores.formattedPercentile('Fine Motor'),
                color: scores.colorFor('Fine Motor'),
              ),
            ],
          );
        },
      ),
    ),
  );
}

// Helpers -------------------------------------------------------------

class _DomainScoreHelper {
  final Map<String, Map<String, dynamic>> _byDomain;
  _DomainScoreHelper(List<Map<String, dynamic>> rows)
      : _byDomain = {
          for (final r in rows)
            (r['domain'] as String): r,
        };

  // Default fallback values to match mockup when no data
  static const Map<String, double> _fallback = {
    'Cognitive': 72,
    'Social': 71,
    'Communication': 45,
    'Motor': 66,
    'Fine Motor': 22,
  };

  double _value(String domain) {
    final row = _byDomain[domain];
    if (row == null || row['avg_percentile'] == null) {
      return _fallback[domain]!.toDouble();
    }
    final v = (row['avg_percentile'] as num).toDouble();
    if (v < 1.0) return 1.0;
    if (v > 99.0) return 99.0;
    return v;
  }

  String formattedPercentile(String domain) => '${_value(domain).round()}%ile';

  String subtitle(String domain) {
    final n = _value(domain).round();
    final suffix = _ordinalSuffix(n);
    return '$n$suffix percentile';
  }

  double percent(String domain) => (_value(domain) / 100.0);

  Color colorFor(String domain) {
    final v = _value(domain);
    if (v < 33) return const Color(0xFFE66A6A); // bad
    if (v < 66) return const Color(0xFFE6C370); // warn
    return const Color(0xFF46B17B); // ok
  }

  _BadgeKind badgeKind(String domain) {
    final v = _value(domain);
    if (v < 33) return _BadgeKind.bad;
    if (v < 66) return _BadgeKind.warn;
    return _BadgeKind.ok;
  }

  String badgeText(String domain) {
    final kind = badgeKind(domain);
    if (kind == _BadgeKind.ok) return 'ON TRACK';
    if (kind == _BadgeKind.warn) return 'WATCH';
    return 'BEHIND';
  }
}

String _heroImageForGender(String? gender) {
  final g = (gender ?? '').toLowerCase();
  if (g.contains('f') || g.contains('girl') || g.contains('woman')) {
    return 'assets/girl.jpg';
  }
  return 'assets/boy.jpg';
}

String _formatAgeMonths(DateTime? birthdate) {
  if (birthdate == null) return '';
  final now = DateTime.now();
  int months = (now.year - birthdate.year) * 12 + (now.month - birthdate.month);
  if (now.day < birthdate.day) months = months - 1;
  if (months < 0) months = 0;
  return '${months} mo';
}

String _ordinalSuffix(int n) {
  final mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 13) return 'th';
  switch (n % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}


class _ProgressPin extends StatelessWidget {
  final double top;
  final double right;
  final String label;
  final String percentile;
  final Color color;

  const _ProgressPin({
    required this.top,
    required this.right,
    required this.label,
    required this.percentile,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Invisible anchor for potential icon if needed
          const SizedBox.shrink(),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(width: 4),
                Text('· $percentile', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressList extends StatelessWidget {
  final List<Map<String, dynamic>> domainScores;
  const _ProgressList({required this.domainScores});

  @override
  Widget build(BuildContext context) {
    final scores = _DomainScoreHelper(domainScores);
    // Order: Brain, Social & Emotional, Speech & Language, Gross Motor, Fine Motor
    final items = [
      _ProgressItem(
        title: 'Brain Development',
        sub: scores.subtitle('Cognitive'),
        percent: scores.percent('Cognitive'),
        color: scores.colorFor('Cognitive'),
        badgeText: scores.badgeText('Cognitive'),
        badgeKind: scores.badgeKind('Cognitive'),
      ),
      _ProgressItem(
        title: 'Social & Emotional',
        sub: scores.subtitle('Social'),
        percent: scores.percent('Social'),
        color: scores.colorFor('Social'),
        badgeText: scores.badgeText('Social'),
        badgeKind: scores.badgeKind('Social'),
      ),
      _ProgressItem(
        title: 'Speech & Language',
        sub: scores.subtitle('Communication'),
        percent: scores.percent('Communication'),
        color: scores.colorFor('Communication'),
        badgeText: scores.badgeText('Communication'),
        badgeKind: scores.badgeKind('Communication'),
      ),
      _ProgressItem(
        title: 'Gross Motor',
        sub: scores.subtitle('Motor'),
        percent: scores.percent('Motor'),
        color: scores.colorFor('Motor'),
        badgeText: scores.badgeText('Motor'),
        badgeKind: scores.badgeKind('Motor'),
      ),
      _ProgressItem(
        title: 'Fine Motor',
        sub: scores.subtitle('Fine Motor'),
        percent: scores.percent('Fine Motor'),
        color: scores.colorFor('Fine Motor'),
        badgeText: scores.badgeText('Fine Motor'),
        badgeKind: scores.badgeKind('Fine Motor'),
      ),
    ];
    return Column(children: items);
  }
}

enum _BadgeKind { ok, warn, bad }

class _ProgressItem extends StatelessWidget {
  final String title;
  final String sub;
  final double percent; // 0..1
  final Color color;
  final String badgeText;
  final _BadgeKind badgeKind;

  const _ProgressItem({
    required this.title,
    required this.sub,
    required this.percent,
    required this.color,
    required this.badgeText,
    required this.badgeKind,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    if (badgeKind == _BadgeKind.ok) {
      badgeColor = const Color(0xFF46B17B);
    } else if (badgeKind == _BadgeKind.warn) {
      badgeColor = const Color(0xFFE6C370);
    } else {
      badgeColor = const Color(0xFFE66A6A);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(sub, style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 12)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(height: 6, color: const Color(0xFFF1F3F5)),
                          Container(
                            height: 6,
                            width: constraints.maxWidth * percent,
                            decoration: BoxDecoration(color: color),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
