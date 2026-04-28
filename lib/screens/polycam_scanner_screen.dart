import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';

class PolycamScannerScreen extends StatefulWidget {
  const PolycamScannerScreen({super.key});

  @override
  State<PolycamScannerScreen> createState() => _PolycamScannerScreenState();
}

class _PolycamScannerScreenState extends State<PolycamScannerScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _gridAnimationController;
  late AnimationController _radarAnimationController;
  bool _isScanning = true;
  double _scanProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initCamera();

    _gridAnimationController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _radarAnimationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

    // Mock scan progress
    Future.delayed(const Duration(milliseconds: 500), _simulateScanning);
  }

  Future<void> _simulateScanning() async {
    while (_isScanning && _scanProgress < 1.0) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _scanProgress += 0.005;
        });
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      _cameraController = CameraController(
        cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first),
        ResolutionPreset.max,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error initializing camera for Polycam mode: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _gridAnimationController.dispose();
    _radarAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Feed
          if (_cameraController != null && _cameraController!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 1,
                  height: _cameraController!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),

          // 2. LiDAR Spatial Mesh Overlay
          AnimatedBuilder(
            animation: _gridAnimationController,
            builder: (context, child) {
              return CustomPaint(
                painter: _SpatialMeshPainter(animationValue: _gridAnimationController.value),
                size: Size.infinite,
              );
            },
          ),

          // 3. Scanning Radar Line
          AnimatedBuilder(
            animation: _radarAnimationController,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).size.height * _radarAnimationController.value,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.compliant,
                    boxShadow: [
                      BoxShadow(color: AppColors.compliant.withValues(alpha: 0.8), blurRadius: 12, spreadRadius: 4),
                    ],
                  ),
                ),
              );
            },
          ),

          // 4. UI Overlays
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.compliant),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.blur_on, color: AppColors.compliant, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '${(_scanProgress * 100).toStringAsFixed(0)}% MAPPED',
                              style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48), // Balance
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Text(
                        'Slowly pan your camera around the room to build the 3D model.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontFamily: 'Inter', fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          setState(() => _isScanning = false);
                          // In a real app, this would process the mesh and launch the 3D viewer.
                          // For now, return to the floor plan builder.
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('3D Room Mesh saved!')));
                        },
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 60, height: 60,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.stop_rounded, color: Colors.black, size: 32),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _SpatialMeshPainter extends CustomPainter {
  final double animationValue;

  _SpatialMeshPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.compliant.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..color = AppColors.compliant.withValues(alpha: 0.8);

    // Draw a moving perspective grid to simulate LiDAR spatial mapping
    final double step = 40.0;
    final double offset = animationValue * step;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    for (double y = offset; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw random dots representing point cloud data
    final random = math.Random(42); // fixed seed for stability
    for (int i = 0; i < 50; i++) {
      double px = random.nextDouble() * size.width;
      double py = (random.nextDouble() * size.height + offset * 10) % size.height;
      
      // Only draw dots near the center "scanned" area
      if ((px - size.width/2).abs() < size.width * 0.4) {
        canvas.drawCircle(Offset(px, py), 2.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpatialMeshPainter old) => true;
}
