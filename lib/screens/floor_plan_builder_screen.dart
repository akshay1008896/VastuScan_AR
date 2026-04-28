import 'package:flutter/material.dart';
import 'package:vastuscan_ar/models/floor_plan.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';
import 'package:vastuscan_ar/widgets/glass_button.dart';

class FloorPlanBuilderScreen extends StatefulWidget {
  const FloorPlanBuilderScreen({super.key});

  @override
  State<FloorPlanBuilderScreen> createState() => _FloorPlanBuilderScreenState();
}

class _FloorPlanBuilderScreenState extends State<FloorPlanBuilderScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'My Custom Layout');
  
  // Default values
  final Map<RoomType, int> _roomCounts = {
    RoomType.livingRoom: 1,
    RoomType.kitchen: 1,
    RoomType.bedroom: 1,
    RoomType.bathroom: 1,
    RoomType.balcony: 0,
  };

  void _updateCount(RoomType type, int delta) {
    setState(() {
      final current = _roomCounts[type] ?? 0;
      final next = current + delta;
      if (next >= 0 && next <= 10) {
        _roomCounts[type] = next;
      }
    });
  }

  void _generateAndReturn() {
    if (_roomCounts.values.every((c) => c == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one room.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final customPlan = FloorPlan.generateCustom(
      name: _nameController.text.trim().isEmpty ? 'Custom Layout' : _nameController.text.trim(),
      roomCounts: _roomCounts,
    );
    
    Navigator.pop(context, customPlan);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Custom Layout Builder', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.saffron),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Name your layout',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.saffron),
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'Inter'),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Add Rooms',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                _buildRoomCounter(RoomType.livingRoom, 'Living Room'),
                _buildRoomCounter(RoomType.masterBedroom, 'Master Bedroom'),
                _buildRoomCounter(RoomType.bedroom, 'Standard Bedroom'),
                _buildRoomCounter(RoomType.diningRoom, 'Dining Room'),
                _buildRoomCounter(RoomType.kitchen, 'Kitchen'),
                _buildRoomCounter(RoomType.bathroom, 'Bathroom'),
                _buildRoomCounter(RoomType.poojaRoom, 'Pooja Room'),
                _buildRoomCounter(RoomType.balcony, 'Balcony'),
                _buildRoomCounter(RoomType.study, 'Study Room'),
                _buildRoomCounter(RoomType.garage, 'Garage'),
                _buildRoomCounter(RoomType.garden, 'Garden'),
                _buildRoomCounter(RoomType.staircase, 'Staircase'),
                _buildRoomCounter(RoomType.store, 'Store Room'),
                
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                
                const Text(
                  'Office Rooms (Optional)',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                _buildRoomCounter(RoomType.reception, 'Reception'),
                _buildRoomCounter(RoomType.openWork, 'Open Work Area'),
                _buildRoomCounter(RoomType.cabin, 'Cabin'),
                _buildRoomCounter(RoomType.conference, 'Conference Room'),
                _buildRoomCounter(RoomType.breakRoom, 'Break Room'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: GlassButton(
              onPressed: _generateAndReturn,
              backgroundColor: AppColors.saffron.withOpacity(0.9),
              borderColor: AppColors.saffronLight,
              child: const Text(
                'GENERATE LAYOUT',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCounter(RoomType type, String label) {
    final count = _roomCounts[type] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: count > 0 ? () => _updateCount(type, -1) : null,
                icon: Icon(Icons.remove_circle_outline, color: count > 0 ? AppColors.saffron : AppColors.textMuted.withOpacity(0.5)),
              ),
              SizedBox(
                width: 30,
                child: Text(
                  count.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: count < 10 ? () => _updateCount(type, 1) : null,
                icon: Icon(Icons.add_circle_outline, color: count < 10 ? AppColors.compliant : AppColors.textMuted.withOpacity(0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
