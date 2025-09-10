import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/models/concern.dart';

class ConcernsScreen extends StatefulWidget {
  const ConcernsScreen({super.key});

  @override
  State<ConcernsScreen> createState() => _ConcernsScreenState();
}

class _ConcernsScreenState extends State<ConcernsScreen> {
  final List<Concern> _concerns = [];
  final TextEditingController _concernController = TextEditingController();

  @override
  void dispose() {
    _concernController.dispose();
    super.dispose();
  }

  void _addConcern() {
    if (_concernController.text.trim().isEmpty) return;
    
    setState(() {
      _concerns.add(
        Concern(
          id: DateTime.now().toString(),
          text: _concernController.text.trim(),
          isResolved: false,
          createdAt: DateTime.now(),
        ),
      );
      _concernController.clear();
    });
  }

  void _toggleConcern(String concernId) {
    final index = _concerns.indexWhere((concern) => concern.id == concernId);
    if (index != -1) {
      final concern = _concerns[index];
      final newIsResolved = !concern.isResolved;
      
      setState(() {
        _concerns[index] = concern.copyWith(
          isResolved: newIsResolved,
          // Store the resolved timestamp when marking as resolved
          resolvedAt: newIsResolved ? DateTime.now() : null,
        );
      });
    }
  }

  void _deleteConcern(String concernId) {
    final index = _concerns.indexWhere((concern) => concern.id == concernId);
    if (index != -1) {
      setState(() {
        _concerns.removeAt(index);
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _concerns.isEmpty
                  ? _buildEmptyState()
                  : _buildConcernsList(),
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
      child: Row(
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
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
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
          Icon(
            FeatherIcons.clipboard,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No concerns yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add concerns to keep track of things\nyou want to discuss with your doctor',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddConcernDialog,
            icon: const Icon(FeatherIcons.plus, size: 16),
            label: const Text('Add Concern'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcernsList() {
    // Sort concerns: unresolved first, then by creation date (newest first)
    final sortedConcerns = [..._concerns]
      ..sort((a, b) {
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
