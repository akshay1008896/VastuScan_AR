import 'package:flutter/material.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';

class VastuInfoScreen extends StatelessWidget {
  const VastuInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmSand,
      appBar: AppBar(
        title: const Text('Vastu Guide', style: TextStyle(fontFamily: 'Outfit', color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.saffron),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 12),
            child: Text(
              'Directional Guidelines',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          _buildDirectionCard('NorthEast (Ishan)', AppColors.elementWater, Icons.water_drop, 'Water Element', 'Ideal for Pooja room, meditation, and lightweight items. Keep clean and clutter-free.'),
          _buildDirectionCard('SouthEast (Agni)', AppColors.saffron, Icons.local_fire_department, 'Fire Element', 'Ideal for Kitchens, electrical appliances, and heaters. Avoid placing water bodies here.'),
          _buildDirectionCard('SouthWest (Nairutya)', AppColors.elementEarth, Icons.landscape, 'Earth Element', 'Ideal for Master Bedroom, heavy furniture, and wardrobes. Signifies stability.'),
          _buildDirectionCard('NorthWest (Vayavya)', AppColors.elementAir, Icons.air, 'Air Element', 'Ideal for Guest rooms, pets, and movable items. Facilitates movement and communication.'),
          _buildDirectionCard('Center (Brahmasthan)', AppColors.gold, Icons.center_focus_strong, 'Space Element', 'The core of the house. Must be kept entirely empty and free from any heavy objects or pillars.'),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 12),
            child: Text(
              'Common Objects',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          _buildObjectCard('Bed', 'South or West wall with head facing South or East.', Icons.bed),
          _buildObjectCard('Stove / Oven', 'SouthEast direction, facing East while cooking.', Icons.microwave),
          _buildObjectCard('Mirrors', 'North or East walls. Avoid facing the bed.', Icons.square),
          _buildObjectCard('TV / Electronics', 'SouthEast or NorthWest. Avoid NorthEast.', Icons.tv),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.saffron.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.saffron.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.saffron, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Introduction to Vastu',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.gold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Vastu Shastra is the ancient Indian science of architecture and spatial arrangement. It balances the five elements (Earth, Water, Fire, Air, Space) to promote health, wealth, and prosperity.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionCard(String title, Color color, IconData icon, String subtitle, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Icon(icon, color: color, size: 36),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  Text(desc, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectCard(String name, String placement, IconData icon) {
    return Card(
      color: AppColors.cardSurface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary, size: 28),
        title: Text(name, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        subtitle: Text('Best Placement: $placement', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.compliant)),
      ),
    );
  }
}
