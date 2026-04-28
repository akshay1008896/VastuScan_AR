import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vastuscan_ar/models/scan_session.dart';
import 'package:vastuscan_ar/models/vastu_result.dart';
import 'package:vastuscan_ar/screens/remediation_sheet.dart';
import 'package:vastuscan_ar/services/storage_service.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';

class ScanReportScreen extends StatefulWidget {
  final ScanSession session;
  final VoidCallback? onDone;

  const ScanReportScreen({super.key, required this.session, this.onDone});

  @override
  State<ScanReportScreen> createState() => _ScanReportScreenState();
}

class _ScanReportScreenState extends State<ScanReportScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _scoreCtrl;
  late Animation<double> _fade;
  late Animation<double> _scoreAnim;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scoreCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _scoreAnim = Tween<double>(begin: 0, end: widget.session.score / 100)
        .animate(CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () => _scoreCtrl.forward());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  Color get _scoreColor {
    final s = widget.session.score;
    if (s >= 75) return AppColors.compliant;
    if (s >= 50) return AppColors.warning;
    return AppColors.nonCompliant;
  }

  String get _scoreLabel {
    final s = widget.session.score;
    if (s >= 75) return 'Excellent Vastu Alignment';
    if (s >= 50) return 'Good — Minor Fixes Needed';
    return 'Needs Vastu Attention';
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final compliant = session.results.where((r) => r.isCompliant).toList();
    final nonCompliant = session.results.where((r) => !r.isCompliant).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.cream,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
                onPressed: () { widget.onDone?.call(); Navigator.of(context).pop(session); },
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.roomLabel != null ? '${session.roomLabel} Report' : 'Scan Report',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  if (session.durationFormatted != '--')
                    Text('Duration: ${session.durationFormatted}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
            SliverToBoxAdapter(child: _buildScoreCard(session)),
            SliverToBoxAdapter(child: _buildStatsRow(session)),
            if (session.results.isNotEmpty) SliverToBoxAdapter(child: _buildMiniMap(session)),
            if (nonCompliant.isNotEmpty) ...[
              _sectionHeader('❌ Non-Compliant Items', AppColors.nonCompliant),
              SliverList(delegate: SliverChildBuilderDelegate((_, i) => _resultTile(nonCompliant[i], false), childCount: nonCompliant.length)),
            ],
            if (compliant.isNotEmpty) ...[
              _sectionHeader('✅ Compliant Items', AppColors.compliant),
              SliverList(delegate: SliverChildBuilderDelegate((_, i) => _resultTile(compliant[i], true), childCount: compliant.length)),
            ],
            SliverToBoxAdapter(child: _buildActions(session)),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(ScanSession session) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _scoreColor.withOpacity(0.15), blurRadius: 24, spreadRadius: 2)],
        border: Border.all(color: _scoreColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _scoreAnim,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140, height: 140,
                  child: CircularProgressIndicator(
                    value: _scoreAnim.value,
                    strokeWidth: 11,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${(_scoreAnim.value * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 38, fontWeight: FontWeight.w800, color: _scoreColor)),
                  const Text('Vastu Score', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(color: _scoreColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(_scoreLabel, style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: _scoreColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ScanSession session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _statBox('Scanned', '${session.totalCount}', Icons.radar, AppColors.gold),
          const SizedBox(width: 10),
          _statBox('Compliant', '${session.compliantCount}', Icons.check_circle, AppColors.compliant),
          const SizedBox(width: 10),
          _statBox('Issues', '${session.nonCompliantCount}', Icons.warning_rounded, AppColors.nonCompliant),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: AppColors.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMap(ScanSession session) {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: CustomPaint(painter: _MapPainter(session.results), child: const SizedBox.expand()),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        child: Row(
          children: [
            Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _resultTile(VastuResult result, bool ok) {
    final c = ok ? AppColors.compliant : AppColors.nonCompliant;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(0.18)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: c.withOpacity(0.12),
          child: Icon(ok ? Icons.check_circle : Icons.warning_rounded, color: c, size: 20),
        ),
        title: Text(result.detectedObject.label.toUpperCase(),
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        subtitle: Text(result.summary,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: !ok
            ? IconButton(
                icon: const Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 20),
                onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => RemediationSheet(result: result)))
            : null,
      ),
    );
  }

  Widget _buildActions(ScanSession session) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _saved ? null : () async {
                HapticFeedback.mediumImpact();
                await StorageService.instance.saveSession(session);
                setState(() => _saved = true);
              },
              icon: Icon(_saved ? Icons.check : Icons.save_rounded, size: 18),
              label: Text(_saved ? 'Saved!' : 'Save Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _saved ? AppColors.compliant : AppColors.saffron,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: () { widget.onDone?.call(); Navigator.of(context).pop(session); },
              icon: const Icon(Icons.home_rounded, size: 18),
              label: const Text('Done'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.saffron,
                side: const BorderSide(color: AppColors.saffron, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final List<VastuResult> results;
  _MapPainter(this.results);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = AppColors.warmSand.withOpacity(0.35));
    final gp = Paint()..color = AppColors.divider..strokeWidth = 0.5;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(size.width * i / 3, 0), Offset(size.width * i / 3, size.height), gp);
      canvas.drawLine(Offset(0, size.height * i / 3), Offset(size.width, size.height * i / 3), gp);
    }
    for (final result in results) {
      final obj = result.detectedObject;
      final color = result.isCompliant ? AppColors.compliant : AppColors.nonCompliant;
      final box = obj.boundingBox;
      double w = box.width.clamp(0.06, 0.4) * size.width;
      double h = box.height.clamp(0.06, 0.4) * size.height;
      double l = box.left.clamp(0.0, 0.9) * size.width;
      double t = box.top.clamp(0.0, 0.85) * size.height;
      if (w < 30) w = 40;
      if (h < 20) h = 24;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), const Radius.circular(5)),
          Paint()..color = color.withOpacity(0.18));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), const Radius.circular(5)),
          Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5);
      final tp = TextPainter(
        text: TextSpan(text: obj.label, style: const TextStyle(fontSize: 8, fontFamily: 'Outfit', color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w);
      tp.paint(canvas, Offset(l + 2, t + h / 2 - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
