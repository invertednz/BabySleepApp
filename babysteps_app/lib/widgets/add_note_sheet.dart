import 'package:flutter/material.dart';
import 'package:babysteps_app/models/diary_entry.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:intl/intl.dart';

class AddNoteSheet extends StatefulWidget {
  final DateTime selectedDate;

  const AddNoteSheet({required this.selectedDate, super.key});

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  NoteType _selectedNoteType = NoteType.note; // Default to Note type
  bool _showMeasurements = false;

  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _headController = TextEditingController();
  final _chestController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _headController.dispose();
    _chestController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_formKey.currentState!.validate()) {
      final newEntry = DiaryEntry(
        id: DateTime.now().toIso8601String(),
        type: _selectedNoteType,
        title: _titleController.text,
        content: _contentController.text,
        timestamp: DateTime.now(),
        measurements: _showMeasurements
            ? Measurements(
                weight: double.tryParse(_weightController.text),
                height: double.tryParse(_heightController.text),
                headCircumference: double.tryParse(_headController.text),
                chestCircumference: double.tryParse(_chestController.text),
              )
            : null,
      );
      Navigator.of(context).pop(newEntry);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the maximum height for the sheet (70% of screen height)
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildNoteTypeSelector(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Notes', 
                  alignLabelWithHint: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildMeasurementsToggle(),
              if (_showMeasurements) _buildMeasurementsFields(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveNote,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  backgroundColor: AppTheme.darkPurple,
                ),
                child: const Text('Save Note', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Add New Note', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(DateFormat('MMM d, HH:mm').format(DateTime.now()), style: const TextStyle(color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildNoteTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: NoteType.values.map((type) {
        final isSelected = _selectedNoteType == type;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedNoteType = type;
            // Automatically show measurements if Measurement type is selected
            if (type == NoteType.measurement) {
              _showMeasurements = true;
            }
          }),
          child: Column(
            children: [
              CircleAvatar(
                radius: 20, // Smaller radius
                backgroundColor: isSelected ? AppTheme.primaryPurple : AppTheme.lightPurple,
                child: Icon(
                  getIconForNoteType(type), 
                  color: isSelected ? Colors.white : AppTheme.darkPurple,
                  size: 16, // Smaller icon
                ),
              ),
              const SizedBox(height: 4),
              Text(
                type.name[0].toUpperCase() + type.name.substring(1), 
                style: TextStyle(
                  fontSize: 11, 
                  color: isSelected ? AppTheme.primaryPurple : AppTheme.textSecondary
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMeasurementsToggle() {
    return SwitchListTile(
      title: const Text('Add Measurements'),
      value: _showMeasurements,
      onChanged: (value) => setState(() => _showMeasurements = value),
      activeColor: AppTheme.darkPurple,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildMeasurementsFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController, 
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ), 
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _heightController, 
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ), 
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _headController, 
                  decoration: const InputDecoration(
                    labelText: 'Head (cm)',
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ), 
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _chestController, 
                  decoration: const InputDecoration(
                    labelText: 'Chest (cm)',
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ), 
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
