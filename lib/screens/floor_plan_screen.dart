import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vastuscan_ar/models/floor_plan.dart';
import 'package:vastuscan_ar/models/scan_session.dart';
import 'package:vastuscan_ar/screens/scan_screen.dart';
import 'package:vastuscan_ar/screens/floor_plan_builder_screen.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';
import 'package:vastuscan_ar/widgets/glass_button.dart';

class FloorPlanScreen extends StatefulWidget {
  const FloorPlanScreen({super.key});
  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> with TickerProviderStateMixin {
  FloorPlan? _plan;
  bool _showCompassOverlay = true;
  bool _show3D = false;
  bool _showTemplatePicker = true;
  
  // 3D Camera State
  double _camPitch = 0.6; // ~34 degrees looking down
  double _camYaw = 0.785; // 45 degrees
  double _camZoom = 1.0;
  Offset _camPan = Offset.zero;

  // Drawing State
  bool _isDrawingMode = false;
  Offset? _drawStart;
  Offset? _drawEnd;

  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  void _selectPreset(FloorPlanPreset preset) {
    FloorPlan plan;
    switch (preset) {
      case FloorPlanPreset.bhk1: plan = FloorPlan.preset1BHK(); break;
      case FloorPlanPreset.bhk2: plan = FloorPlan.preset2BHK(); break;
      case FloorPlanPreset.bhk3: plan = FloorPlan.preset3BHK(); break;
      case FloorPlanPreset.villa: plan = FloorPlan.presetVilla(); break;
      case FloorPlanPreset.office: plan = FloorPlan.presetOffice(); break;
      case FloorPlanPreset.custom: plan = FloorPlan.preset1BHK(); break;
    }
    setState(() { _plan = plan; _showTemplatePicker = false; });
    _fadeCtrl.forward(from: 0);
    _savePlan();
  }

  Future<void> _savePlan() async {
    if (_plan == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('floor_plan_active', jsonEncode(_plan!.toJson()));
  }

  Future<void> _onRoomTap(Room room) async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push<ScanSession>(context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ScanScreen(roomLabel: room.name),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        room.vastuScore = result.score;
        room.isScanned = true;
        room.scanCount = room.scanCount + 1;
        room.lastScanId = result.id;
      });
      await _savePlan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('Floor Plan', style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          if (_plan != null) ...[
            if (!_show3D) IconButton(icon: Icon(_isDrawingMode ? Icons.edit : Icons.edit_outlined, color: _isDrawingMode ? AppColors.compliant : AppColors.saffron), tooltip: 'Draw Room', onPressed: () => setState(() => _isDrawingMode = !_isDrawingMode)),
            IconButton(icon: Icon(_show3D ? Icons.view_in_ar : Icons.grid_view, color: AppColors.saffron), tooltip: '3D View', onPressed: () => setState(() { _show3D = !_show3D; _isDrawingMode = false; })),
            IconButton(icon: Icon(_showCompassOverlay ? Icons.grid_on : Icons.grid_off, color: AppColors.gold), tooltip: 'Vastu Grid', onPressed: () => setState(() => _showCompassOverlay = !_showCompassOverlay)),
            IconButton(icon: const Icon(Icons.door_front_door_outlined, color: AppColors.saffron), tooltip: 'Add Door/Window', onPressed: _showAddElementDialog),
            IconButton(icon: const Icon(Icons.dashboard_customize, color: AppColors.saffron), tooltip: 'Change Layout', onPressed: () => setState(() => _showTemplatePicker = true)),
          ],
        ],
      ),
      body: _showTemplatePicker ? _buildTemplatePicker() : Column(
        children: [
          _buildTopControls(),
          Expanded(child: _show3D ? _build3DCanvas() : _buildPlanCanvas()),
          _buildLegend(),
        ],
      ),
    );
  }

  // ─── Template Picker ─────────────────────────────────────────
  Widget _buildTemplatePicker() {
    final templates = [
      ('1 BHK', '🏠', 'Compact home', FloorPlanPreset.bhk1, AppColors.pastelPeach),
      ('2 BHK', '🏡', 'Standard home', FloorPlanPreset.bhk2, AppColors.pastelMint),
      ('3 BHK', '🏘️', 'Spacious home', FloorPlanPreset.bhk3, AppColors.pastelLavender),
      ('Villa', '🏛️', 'Luxury villa', FloorPlanPreset.villa, AppColors.pastelPink),
      ('Office', '🏢', 'Office space', FloorPlanPreset.office, AppColors.pastelYellow),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose a Layout', style: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Select a template or create a custom floor plan', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ...templates.map((t) => _templateCard(t.$1, t.$2, t.$3, t.$4, t.$5)),
          const SizedBox(height: 12),
          // Custom builder button
          GlassButton(
            onPressed: () async {
              final customPlan = await Navigator.push<FloorPlan>(context, MaterialPageRoute(builder: (_) => const FloorPlanBuilderScreen()));
              if (customPlan != null) { setState(() { _plan = customPlan; _showTemplatePicker = false; }); await _savePlan(); }
            },
            height: 56,
            backgroundColor: AppColors.saffron.withValues(alpha: 0.12),
            borderColor: AppColors.saffron,
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_home_work_rounded, color: AppColors.saffronDark),
              SizedBox(width: 10),
              Text('CREATE CUSTOM LAYOUT', style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.saffronDark, letterSpacing: 1)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _templateCard(String title, String emoji, String subtitle, FloorPlanPreset preset, Color bg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectPreset(preset),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bg.withValues(alpha: 0.6)),
            ),
            child: Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontFamily: 'Outfit', fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
              ]),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
            ]),
          ),
        ),
      ),
    );
  }

  // ─── Top Controls ──────────────────────────────────────────
  Widget _buildTopControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Text(_plan?.name ?? '', style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const Spacer(),
        Text('Score: ${_plan?.overallScore.toStringAsFixed(0) ?? 0}%', style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.saffron)),
      ]),
    );
  }

  // ─── 2D Plan Canvas ────────────────────────────────────────
  Widget _buildPlanCanvas() {
    if (_plan == null) return const Center(child: CircularProgressIndicator(color: AppColors.saffron));
    return FadeTransition(
      opacity: _fade,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider, width: 2),
            boxShadow: [BoxShadow(color: AppColors.saffron.withValues(alpha: 0.08), blurRadius: 16, spreadRadius: 2)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: LayoutBuilder(builder: (ctx, constraints) {
              return GestureDetector(
                onPanStart: _isDrawingMode ? (details) => setState(() { _drawStart = details.localPosition; _drawEnd = details.localPosition; }) : null,
                onPanUpdate: _isDrawingMode ? (details) => setState(() => _drawEnd = details.localPosition) : null,
                onPanEnd: _isDrawingMode ? (_) => _showDrawRoomDialog(constraints) : null,
                child: Stack(children: [
                  if (_showCompassOverlay) CustomPaint(size: Size(constraints.maxWidth, constraints.maxHeight), painter: _VastuGridPainter()),
                  ..._plan!.rooms.map((room) => _buildRoomWidget(room, constraints)),
                  ..._plan!.elements.map((el) => _buildElementWidget(el, constraints)),
                  if (_isDrawingMode && _drawStart != null && _drawEnd != null)
                    Positioned(
                      left: math.min(_drawStart!.dx, _drawEnd!.dx),
                      top: math.min(_drawStart!.dy, _drawEnd!.dy),
                      width: (_drawEnd!.dx - _drawStart!.dx).abs(),
                      height: (_drawEnd!.dy - _drawStart!.dy).abs(),
                      child: Container(decoration: BoxDecoration(color: AppColors.saffron.withValues(alpha: 0.3), border: Border.all(color: AppColors.saffron, width: 2, style: BorderStyle.solid))),
                    ),
                ]),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomWidget(Room room, BoxConstraints c) {
    final w = c.maxWidth; final h = c.maxHeight;
    final left = room.left * w; final top = room.top * h;
    final width = room.width * w; final height = room.height * h;
    Color roomColor = !room.isScanned ? AppColors.saffron.withValues(alpha: 0.12) : room.vastuScore >= 70 ? AppColors.compliant.withValues(alpha: 0.18) : room.vastuScore >= 45 ? AppColors.warning.withValues(alpha: 0.18) : AppColors.nonCompliant.withValues(alpha: 0.18);
    Color borderColor = !room.isScanned ? AppColors.border : room.vastuScore >= 70 ? AppColors.compliant : room.vastuScore >= 45 ? AppColors.warning : AppColors.nonCompliant;

    return Positioned(left: left, top: top, width: width, height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => _onRoomTap(room),
            onPanUpdate: (details) {
              setState(() {
                room.left = (room.left + details.delta.dx / w).clamp(0.0, 1.0 - room.width);
                room.top = (room.top + details.delta.dy / h).clamp(0.0, 1.0 - room.height);
              });
            },
            onPanEnd: (_) => _savePlan(),
            child: Container(
              width: width, height: height,
              decoration: BoxDecoration(color: roomColor, border: Border.all(color: borderColor, width: 1.5)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(room.type.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 2),
                Text(room.name, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (room.isScanned) ...[
                  const SizedBox(height: 2),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: borderColor.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(8)),
                    child: Text('${room.vastuScore.toStringAsFixed(0)}%', style: const TextStyle(fontFamily: 'Outfit', fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))),
                ] else Text('Tap to Scan', style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: AppColors.textMuted.withValues(alpha: 0.8))),
              ]),
            ),
          ),
          // Delete button (top-right)
          if (_isDrawingMode) // Only show delete button when in drawing/edit mode to prevent accidental taps
            Positioned(
              right: -8, top: -8,
              child: GestureDetector(
                onTap: () {
                  setState(() => _plan!.rooms.remove(room));
                  _savePlan();
                },
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(color: AppColors.nonCompliant, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          // Resize handle (bottom-right)
          Positioned(
            right: -6, bottom: -6,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  room.width = (room.width + details.delta.dx / w).clamp(0.1, 1.0 - room.left);
                  room.height = (room.height + details.delta.dy / h).clamp(0.1, 1.0 - room.top);
                });
              },
              onPanEnd: (_) => _savePlan(),
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(color: AppColors.saffron, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.open_in_full, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Door/Window Elements ──────────────────────────────────
  Widget _buildElementWidget(PlanElement el, BoxConstraints c) {
    final w = c.maxWidth; final h = c.maxHeight;
    final x = el.x * w; final y = el.y * h;
    final isCompliant = el.isVastuCompliant;
    final color = isCompliant ? AppColors.compliant : AppColors.nonCompliant;
    return Positioned(
      left: (x - 14).clamp(0, w - 28), top: (y - 14).clamp(0, h - 28),
      child: GestureDetector(
        onTap: () => _showElementInfo(el),
        child: Container(width: 28, height: 28,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
          child: Center(child: Text(el.emoji, style: const TextStyle(fontSize: 14))),
        ),
      ),
    );
  }

  void _showElementInfo(PlanElement el) {
    final ok = el.isVastuCompliant;
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.cardSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [Text(el.emoji, style: const TextStyle(fontSize: 24)), const SizedBox(width: 8), Text(el.label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 16))]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Direction: ${el.direction}', style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (ok ? AppColors.compliant : AppColors.nonCompliant).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Text(ok ? '✅ Vastu Compliant' : '⚠️ Not Ideal — ${el.type == ElementType.door ? "Door should face N, NE or E" : "Windows best on N, E, NE walls"}.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: ok ? AppColors.compliant : AppColors.nonCompliant))),
      ]),
      actions: [
        TextButton(onPressed: () { setState(() => _plan!.elements.remove(el)); _savePlan(); Navigator.pop(context); }, child: const Text('Remove', style: TextStyle(color: AppColors.nonCompliant))),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
      ],
    ));
  }

  void _showAddElementDialog() {
    ElementType selectedType = ElementType.door;
    String selectedDir = 'N';
    String label = 'Main Door';
    final dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) => AlertDialog(
      backgroundColor: AppColors.cardSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Door / Window', style: TextStyle(fontFamily: 'Outfit', fontSize: 18)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        SegmentedButton<ElementType>(segments: const [ButtonSegment(value: ElementType.door, label: Text('🚪 Door')), ButtonSegment(value: ElementType.window, label: Text('🪟 Window'))], selected: {selectedType},
          onSelectionChanged: (v) => setDlgState(() { selectedType = v.first; label = v.first == ElementType.door ? 'Door' : 'Window'; })),
        const SizedBox(height: 16),
        TextField(decoration: InputDecoration(labelText: 'Label', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v) => label = v, controller: TextEditingController(text: label)),
        const SizedBox(height: 16),
        const Text('Wall Direction', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: dirs.map((d) => ChoiceChip(label: Text(d), selected: selectedDir == d, onSelected: (_) => setDlgState(() => selectedDir = d))).toList()),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () {
          final wall = {'N': WallSide.north, 'S': WallSide.south, 'E': WallSide.east, 'W': WallSide.west, 'NE': WallSide.north, 'NW': WallSide.north, 'SE': WallSide.south, 'SW': WallSide.south}[selectedDir] ?? WallSide.north;
          double x = 0.5, y = 0.5;
          if (selectedDir.contains('N')) y = 0.0;
          if (selectedDir.contains('S')) y = 1.0;
          if (selectedDir.contains('E')) x = 1.0;
          if (selectedDir.contains('W')) x = 0.0;
          setState(() => _plan!.elements.add(PlanElement(id: DateTime.now().millisecondsSinceEpoch.toString(), type: selectedType, label: label, x: x, y: y, wall: wall, direction: selectedDir)));
          _savePlan(); Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffron, foregroundColor: Colors.white), child: const Text('Add')),
      ],
    )));
  }

  void _showDrawRoomDialog(BoxConstraints c) {
    if (_drawStart == null || _drawEnd == null) return;
    
    // Calculate normalized bounds
    final l = math.min(_drawStart!.dx, _drawEnd!.dx) / c.maxWidth;
    final t = math.min(_drawStart!.dy, _drawEnd!.dy) / c.maxHeight;
    final w = (_drawEnd!.dx - _drawStart!.dx).abs() / c.maxWidth;
    final h = (_drawEnd!.dy - _drawStart!.dy).abs() / c.maxHeight;

    if (w < 0.05 || h < 0.05) {
      // Too small, ignore
      setState(() { _drawStart = null; _drawEnd = null; });
      return;
    }

    RoomType selectedType = RoomType.custom;
    String label = 'Custom Room';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) => AlertDialog(
      backgroundColor: AppColors.cardSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Create Room', style: TextStyle(fontFamily: 'Outfit', fontSize: 18)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<RoomType>(
          value: selectedType,
          dropdownColor: AppColors.cardSurface,
          decoration: InputDecoration(labelText: 'Room Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: RoomType.values.map((rt) => DropdownMenuItem(value: rt, child: Text('${rt.emoji} ${rt.displayName}'))).toList(),
          onChanged: (rt) {
            if (rt != null) {
              setDlgState(() { selectedType = rt; label = rt.displayName; });
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(decoration: InputDecoration(labelText: 'Room Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v) => label = v, controller: TextEditingController(text: label)),
      ]),
      actions: [
        TextButton(onPressed: () {
          setState(() { _drawStart = null; _drawEnd = null; });
          Navigator.pop(ctx);
        }, child: const Text('Cancel')),
        ElevatedButton(onPressed: () {
          setState(() {
            _plan!.rooms.add(Room(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: label, type: selectedType,
              left: l, top: t, width: w, height: h,
            ));
            _drawStart = null; _drawEnd = null;
          });
          _savePlan();
          Navigator.pop(ctx);
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffron, foregroundColor: Colors.white), child: const Text('Create')),
      ],
    )));
  }

  // ─── 3D Interactive View ───────────────────────────────────
  Widget _build3DCanvas() {
    if (_plan == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: GestureDetector(
            onScaleUpdate: (details) {
              setState(() {
                if (details.pointerCount == 2) {
                  _camZoom = (_camZoom * details.scale).clamp(0.5, 3.0);
                  _camPan += details.focalPointDelta;
                } else if (details.pointerCount == 1) {
                  // Rotate: pan horizontally -> yaw, pan vertically -> pitch
                  _camYaw += details.focalPointDelta.dx * 0.01;
                  _camPitch += details.focalPointDelta.dy * 0.01;
                  _camPitch = _camPitch.clamp(0.1, math.pi / 2.2); // Limit pitch from looking up or too flat
                }
              });
            },
            child: CustomPaint(
              painter: _Interactive3DPainter(
                plan: _plan!,
                showGrid: _showCompassOverlay,
                pitch: _camPitch,
                yaw: _camYaw,
                zoom: _camZoom,
                pan: _camPan,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), color: AppColors.cardSurface,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _legendItem(AppColors.border, 'Not Scanned'), _legendItem(AppColors.compliant, '≥70%'), _legendItem(AppColors.warning, '45–70%'), _legendItem(AppColors.nonCompliant, '<45%'),
      ]),
    );
  }

  Widget _legendItem(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.textMuted)),
  ]);
}

// ─── Vastu Grid Painter ──────────────────────────────────────
class _VastuGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.saffron.withValues(alpha: 0.07)..strokeWidth = 1;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(size.width * i / 3, 0), Offset(size.width * i / 3, size.height), paint);
      canvas.drawLine(Offset(0, size.height * i / 3), Offset(size.width, size.height * i / 3), paint);
    }
    final dirs = [('N', Offset(size.width / 2, 8)), ('S', Offset(size.width / 2, size.height - 18)), ('E', Offset(size.width - 18, size.height / 2)), ('W', Offset(8, size.height / 2)), ('NE', Offset(size.width - 20, 10)), ('NW', Offset(6, 10)), ('SE', Offset(size.width - 20, size.height - 18)), ('SW', Offset(6, size.height - 18))];
    for (final d in dirs) {
      final tp = TextPainter(text: TextSpan(text: d.$1, style: TextStyle(fontSize: 9, fontFamily: 'Outfit', fontWeight: FontWeight.w700, color: d.$1 == 'NE' ? AppColors.gold.withValues(alpha: 0.5) : AppColors.saffron.withValues(alpha: 0.35))), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(d.$2.dx - tp.width / 2, d.$2.dy - tp.height / 2));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Interactive 3D Painter ──────────────────────────────────
class _Interactive3DPainter extends CustomPainter {
  final FloorPlan plan;
  final bool showGrid;
  final double pitch;
  final double yaw;
  final double zoom;
  final Offset pan;

  _Interactive3DPainter({
    required this.plan,
    required this.showGrid,
    required this.pitch,
    required this.yaw,
    required this.zoom,
    required this.pan,
  });

  Offset _to3D(double x, double y, double z, Size size) {
    // 1. Yaw rotation (around Z axis)
    double rx = x * math.cos(yaw) - y * math.sin(yaw);
    double ry = x * math.sin(yaw) + y * math.cos(yaw);
    
    // 2. Pitch rotation (around X axis)
    double px = rx;
    double py = ry * math.cos(pitch) - z * math.sin(pitch);
    
    return Offset(
      size.width / 2 + px * zoom + pan.dx,
      size.height / 2 + py * zoom + pan.dy,
    );
  }

  double _getDepth(double x, double y, double z) {
    double ry = x * math.sin(yaw) + y * math.cos(yaw);
    return ry * math.sin(pitch) + z * math.cos(pitch);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) * 0.45;
    final wallH = scale * 0.15;

    // To prevent back rooms from drawing over front rooms, we sort them by depth
    // Depth is the transformed Z-coordinate (smaller Z means further away)
    final sortedRooms = List<Room>.from(plan.rooms)..sort((a, b) {
      double cxA = (a.left - 0.5 + a.width / 2) * scale;
      double cyA = (a.top - 0.5 + a.height / 2) * scale;
      double cxB = (b.left - 0.5 + b.width / 2) * scale;
      double cyB = (b.top - 0.5 + b.height / 2) * scale;
      return _getDepth(cxA, cyA, 0).compareTo(_getDepth(cxB, cyB, 0));
    });

    for (final room in sortedRooms) {
      final l = (room.left - 0.5) * scale; final t = (room.top - 0.5) * scale;
      final r = l + room.width * scale; final b = t + room.height * scale;

      // Colors from reference image
      const Color floorColor = Color(0xFFE5DED5);
      const Color wallColorDark = Color(0xFF1F2633);
      const Color wallColorLight = Color(0xFF2A3441);
      const Color wallTopColor = Color(0xFF151A22);

      Color vastuColor = room.isScanned ? (room.vastuScore >= 70 ? AppColors.compliant : room.vastuScore >= 45 ? AppColors.warning : AppColors.nonCompliant) : AppColors.border;

      // Floor
      final floor = Path()..moveTo(_to3D(l, t, 0, size).dx, _to3D(l, t, 0, size).dy)
                          ..lineTo(_to3D(r, t, 0, size).dx, _to3D(r, t, 0, size).dy)
                          ..lineTo(_to3D(r, b, 0, size).dx, _to3D(r, b, 0, size).dy)
                          ..lineTo(_to3D(l, b, 0, size).dx, _to3D(l, b, 0, size).dy)..close();
      canvas.drawPath(floor, Paint()..color = floorColor);
      
      // Vastu compliance subtle floor tint
      if (room.isScanned) {
        canvas.drawPath(floor, Paint()..color = vastuColor.withValues(alpha: 0.1));
      }

      // Helper function to draw a wall with gradient and top rim
      void drawWall(Path path, Offset start, Offset end) {
        final gradient = LinearGradient(
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
          colors: [wallColorDark, wallColorLight],
        ).createShader(path.getBounds());
        
        canvas.drawPath(path, Paint()..shader = gradient);
        canvas.drawPath(path, Paint()..color = wallTopColor..style = PaintingStyle.stroke..strokeWidth = 1.0);
      }

      // We determine which walls to draw based on the camera angle (yaw)
      // Top Wall (North)
      if (math.sin(yaw) < 0) {
        final tw = Path()..moveTo(_to3D(l, t, 0, size).dx, _to3D(l, t, 0, size).dy)
                         ..lineTo(_to3D(r, t, 0, size).dx, _to3D(r, t, 0, size).dy)
                         ..lineTo(_to3D(r, t, wallH, size).dx, _to3D(r, t, wallH, size).dy)
                         ..lineTo(_to3D(l, t, wallH, size).dx, _to3D(l, t, wallH, size).dy)..close();
        drawWall(tw, _to3D(l, t, 0, size), _to3D(l, t, wallH, size));
      }
      
      // Bottom Wall (South)
      if (math.sin(yaw) >= 0) {
        final bw = Path()..moveTo(_to3D(l, b, 0, size).dx, _to3D(l, b, 0, size).dy)
                         ..lineTo(_to3D(r, b, 0, size).dx, _to3D(r, b, 0, size).dy)
                         ..lineTo(_to3D(r, b, wallH, size).dx, _to3D(r, b, wallH, size).dy)
                         ..lineTo(_to3D(l, b, wallH, size).dx, _to3D(l, b, wallH, size).dy)..close();
        drawWall(bw, _to3D(l, b, 0, size), _to3D(l, b, wallH, size));
      }

      // Left Wall (West)
      if (math.cos(yaw) >= 0) {
        final lw = Path()..moveTo(_to3D(l, t, 0, size).dx, _to3D(l, t, 0, size).dy)
                         ..lineTo(_to3D(l, b, 0, size).dx, _to3D(l, b, 0, size).dy)
                         ..lineTo(_to3D(l, b, wallH, size).dx, _to3D(l, b, wallH, size).dy)
                         ..lineTo(_to3D(l, t, wallH, size).dx, _to3D(l, t, wallH, size).dy)..close();
        drawWall(lw, _to3D(l, b, 0, size), _to3D(l, b, wallH, size));
      }

      // Right Wall (East)
      if (math.cos(yaw) < 0) {
        final rw = Path()..moveTo(_to3D(r, t, 0, size).dx, _to3D(r, t, 0, size).dy)
                         ..lineTo(_to3D(r, b, 0, size).dx, _to3D(r, b, 0, size).dy)
                         ..lineTo(_to3D(r, b, wallH, size).dx, _to3D(r, b, wallH, size).dy)
                         ..lineTo(_to3D(r, t, wallH, size).dx, _to3D(r, t, wallH, size).dy)..close();
        drawWall(rw, _to3D(r, b, 0, size), _to3D(r, b, wallH, size));
      }

      // Draw thick top caps for the walls based on yaw
      final capThickness = 4.0;
      Paint capPaint = Paint()..color = wallTopColor..style = PaintingStyle.stroke..strokeWidth = capThickness..strokeJoin = StrokeJoin.bevel;
      
      Path topCap = Path();
      if (math.sin(yaw) < 0) topCap..moveTo(_to3D(l, t, wallH, size).dx, _to3D(l, t, wallH, size).dy)..lineTo(_to3D(r, t, wallH, size).dx, _to3D(r, t, wallH, size).dy);
      if (math.sin(yaw) >= 0) topCap..moveTo(_to3D(l, b, wallH, size).dx, _to3D(l, b, wallH, size).dy)..lineTo(_to3D(r, b, wallH, size).dx, _to3D(r, b, wallH, size).dy);
      if (math.cos(yaw) >= 0) topCap..moveTo(_to3D(l, t, wallH, size).dx, _to3D(l, t, wallH, size).dy)..lineTo(_to3D(l, b, wallH, size).dx, _to3D(l, b, wallH, size).dy);
      if (math.cos(yaw) < 0) topCap..moveTo(_to3D(r, t, wallH, size).dx, _to3D(r, t, wallH, size).dy)..lineTo(_to3D(r, b, wallH, size).dx, _to3D(r, b, wallH, size).dy);
      canvas.drawPath(topCap, capPaint);

      // Label & Vastu dot
      final center = _to3D((l + r) / 2, (t + b) / 2, 0, size);
      
      // Floating indicator dot for Vastu Compliance
      if (room.isScanned) {
         canvas.drawCircle(Offset(center.dx, center.dy - 16), 4, Paint()..color = vastuColor..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2));
      }

      final tp = TextPainter(text: TextSpan(text: '${room.type.emoji}\n${room.name}', style: const TextStyle(fontSize: 10, fontFamily: 'Outfit', fontWeight: FontWeight.w800, color: Color(0xFF1F2633), height: 1.2)), textDirection: TextDirection.ltr, textAlign: TextAlign.center)..layout(maxWidth: 80);
      tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _Interactive3DPainter old) => true;
}
