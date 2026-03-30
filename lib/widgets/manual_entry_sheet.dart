import 'package:flutter/material.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';

class ManualEntrySheet extends StatefulWidget {
  final double currentHeading;
  final Function(String label, String category, String direction, String notes) onSave;

  const ManualEntrySheet({
    super.key,
    required this.currentHeading,
    required this.onSave,
  });

  @override
  State<ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<ManualEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'Furniture';
  final List<String> _categories = [
    'Furniture', 'Electronic', 'Water', 'Decor', 'Kitchen', 'Religious', 'Other'
  ];

  late String _selectedDirection;
  final List<String> _directions = [
    'North', 'NorthEast', 'East', 'SouthEast',
    'South', 'SouthWest', 'West', 'NorthWest'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDirection = _guessDirection(widget.currentHeading);
  }

  String _guessDirection(double heading) {
    if (heading < 0) heading += 360;
    if (heading >= 337.5 || heading < 22.5) return 'North';
    if (heading >= 22.5 && heading < 67.5) return 'NorthEast';
    if (heading >= 67.5 && heading < 112.5) return 'East';
    if (heading >= 112.5 && heading < 157.5) return 'SouthEast';
    if (heading >= 157.5 && heading < 202.5) return 'South';
    if (heading >= 202.5 && heading < 247.5) return 'SouthWest';
    if (heading >= 247.5 && heading < 292.5) return 'West';
    return 'NorthWest';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Manual Object Entry',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Object Name', Icons.label),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                decoration: _inputDecoration('Category', Icons.category),
                dropdownColor: AppColors.cardSurface,
                style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedDirection,
                items: _directions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDirection = val);
                },
                decoration: _inputDecoration('Direction', Icons.explore),
                dropdownColor: AppColors.cardSurface,
                style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Notes (Optional)', Icons.notes),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSave(
                      _nameController.text.trim(),
                      _selectedCategory,
                      _selectedDirection,
                      _notesController.text.trim(),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saffron,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Object', style: TextStyle(fontFamily: 'Outfit', fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.cardSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.saffron),
      ),
    );
  }
}
