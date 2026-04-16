import 'package:flutter/material.dart';
import 'package:vastuscan_ar/models/scan_session.dart';
import 'package:vastuscan_ar/models/vastu_result.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';

class MapViewScreen extends StatelessWidget {
  final ScanSession session;

  const MapViewScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmSand,
      appBar: AppBar(
        title: Text('${session.name} Map', style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.saffron),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(AppColors.compliant, 'Compliant'),
                _buildLegendItem(AppColors.nonCompliant, 'Non-Compliant'),
                _buildLegendItem(Colors.orangeAccent, 'Unknown'),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.saffron.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CustomPaint(
                      painter: RoomMapPainter(session.results),
                      child: Container(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Top-down approximation of detected elements.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontFamily: 'Inter', color: AppColors.textPrimary, fontSize: 12)),
      ],
    );
  }
}

class RoomMapPainter extends CustomPainter {
  final List<VastuResult> results;

  RoomMapPainter(this.results);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.warmSand.withOpacity(0.5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final compassPaint = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Draw grid
    for(int i = 1; i < 4; i++) {
      canvas.drawLine(Offset(size.width * (i/4), 0), Offset(size.width * (i/4), size.height), compassPaint);
      canvas.drawLine(Offset(0, size.height * (i/4)), Offset(size.width, size.height * (i/4)), compassPaint);
    }

    // Draw objects
    for (var result in results) {
      final obj = result.detectedObject;
      final isManual = obj.isManual;
      
      Color statusColor;
      if (isManual) {
        statusColor = result.isCompliant ? AppColors.compliant : Colors.orangeAccent;
      } else {
        statusColor = result.isCompliant ? AppColors.compliant : AppColors.nonCompliant;
      }

      final boxPaint = Paint()
        ..color = statusColor.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      final borderPaint = Paint()
        ..color = statusColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      // Ensure boxes don't overflow the canvas heavily
      double w = (obj.boundingBox.width.clamp(0.0, 1.0)) * size.width;
      double h = (obj.boundingBox.height.clamp(0.0, 1.0)) * size.height;
      double l = (obj.boundingBox.left.clamp(0.0, 1.0)) * size.width;
      double t = (obj.boundingBox.top.clamp(0.0, 1.0)) * size.height;

      // Adjust for objects that are very small (like manual entry)
      if (w < 40) w = 60;
      if (h < 40) h = 60;
      if (l + w > size.width) l = size.width - w;
      if (t + h > size.height) t = size.height - h;

      final rect = Rect.fromLTWH(l, t, w, h);
      
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), boxPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);

      final textSpan = TextSpan(
        text: '\${obj.label}\n\${result.currentDirectionLabel}',
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontFamily: 'Outfit', fontWeight: FontWeight.bold),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(minWidth: 0, maxWidth: w);
      
      // Center text in rect
      final xCenter = l + (w / 2) - (textPainter.width / 2);
      final yCenter = t + (h / 2) - (textPainter.height / 2);
      
      textPainter.paint(canvas, Offset(xCenter, yCenter));
    }
  }

  @override
  bool shouldRepaint(covariant RoomMapPainter oldDelegate) => true;
}
