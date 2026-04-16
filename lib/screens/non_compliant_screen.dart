import 'package:flutter/material.dart';
import 'package:vastuscan_ar/models/scan_session.dart';
import 'package:vastuscan_ar/models/vastu_result.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';

class NonCompliantScreen extends StatefulWidget {
  final ScanSession session;

  const NonCompliantScreen({super.key, required this.session});

  @override
  State<NonCompliantScreen> createState() => _NonCompliantScreenState();
}

class _NonCompliantScreenState extends State<NonCompliantScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    // Filter out only non-compliant items
    final nonCompliantItems = widget.session.results.where((r) => !r.isCompliant).toList();

    // Directions for filtering
    final Set<String> directions = nonCompliantItems.map((r) => r.currentDirectionLabel).toSet();
    final List<String> filterOptions = ['All', ...directions];

    final displayedItems = _selectedFilter == 'All'
        ? nonCompliantItems
        : nonCompliantItems.where((r) => r.currentDirectionLabel == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Non-Compliant Items', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.saffron),
      ),
      body: Column(
        children: [
          _buildFilterChips(filterOptions),
          Expanded(
            child: displayedItems.isEmpty
                ? const Center(
                    child: Text(
                      'No non-compliant items found.',
                      style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter'),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedItems.length,
                    itemBuilder: (context, index) {
                      return _buildItemCard(displayedItems[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(List<String> options) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: options.map((option) {
          final isSelected = _selectedFilter == option;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = option);
                }
              },
              backgroundColor: AppColors.cardSurface,
              selectedColor: AppColors.saffron,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontFamily: 'Inter',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemCard(VastuResult result) {
    final title = result.detectedObject.isManual 
      ? '${result.detectedObject.label} (Manual)' 
      : result.detectedObject.label;
      
    // Capitalize first letter
    final displayTitle = title[0].toUpperCase() + title.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.nonCompliant.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.nonCompliant.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    displayTitle,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.nonCompliant.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Needs Check', style: TextStyle(color: AppColors.nonCompliant, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.explore, 'Direction', result.currentDirectionLabel),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.warning_amber_rounded, 'Issue', result.summary),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.healing, 'Remedy', result.rule.practicalTips),
            if (result.detectedObject.notes != null && result.detectedObject.notes!.isNotEmpty) ...[
               const SizedBox(height: 8),
               _buildDetailRow(Icons.note, 'Notes', result.detectedObject.notes!),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}
