import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:vastuscan_ar/models/vastu_result.dart';
import 'package:vastuscan_ar/services/compass_service.dart';
import 'package:vastuscan_ar/services/detection_service.dart';
import 'package:vastuscan_ar/services/vastu_engine.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';
import 'package:vastuscan_ar/widgets/compass_bar.dart';
import 'package:vastuscan_ar/widgets/score_indicator.dart';
import 'package:vastuscan_ar/widgets/manual_entry_sheet.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:vastuscan_ar/screens/remediation_sheet.dart';
import 'package:vastuscan_ar/models/detected_object.dart';
import 'package:vastuscan_ar/services/storage_service.dart';
import 'package:vastuscan_ar/screens/non_compliant_screen.dart';
import 'package:vastuscan_ar/screens/map_view_screen.dart';

/// The main scanning screen with camera feed, compass, detection overlay, and score.
///
/// Layers (bottom to top):
/// 1. Camera feed (or demo gradient background)
/// 2. Detection bounding boxes
/// 3. Compass bar (top)
/// 4. Score indicator (bottom)
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with TickerProviderStateMixin {
  late CompassService _compassService;
  late DetectionService _detectionService;
  late VastuEngine _vastuEngine;
  CameraController? _cameraController;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isInitialized = false;
  bool _isScanLocked = false;
  List<VastuResult> _vastuResults = [];

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();

    _compassService = CompassService();
    _detectionService = DetectionService();
    _vastuEngine = VastuEngine();

    // Scan line animation
    _scanLineController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    // Pulse animation for bounding boxes
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initialize();
  }

  Future<void> _initialize() async {
    await _vastuEngine.loadRules();

    // Initialize Camera
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium, // Medium resolution for faster ML processing frames
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
        );
        await _cameraController!.initialize();
        
        // Start streaming instantly
        _startAutoScanning();
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }

    await _detectionService.initialize(forceDemoMode: false);
    await _compassService.start(forceDemoMode: false);

    _compassService.addListener(_onSensorUpdate);
    _detectionService.addListener(_onSensorUpdate);

    if (mounted) {
      setState(() => _isInitialized = true);
      
      // Notify about manual scanning
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap anywhere on the camera feed to manually identify and scan an object!'),
          duration: Duration(seconds: 4),
          backgroundColor: AppColors.saffron,
        ),
      );
    }
  }

  void _onSensorUpdate() {
    if (!_isInitialized || !mounted) return;

    final objects = _detectionService.detectedObjects;
    final heading = _compassService.currentData.heading;

    _vastuEngine.evaluateAll(objects, heading);
    setState(() {
      _vastuResults = _vastuEngine.session.results;
    });
  }

  @override
  void dispose() {
    _compassService.removeListener(_onSensorUpdate);
    _detectionService.removeListener(_onSensorUpdate);
    _compassService.dispose();
    _detectionService.dispose();
    _vastuEngine.dispose();
    _scanLineController.dispose();
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _showRemediation(VastuResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RemediationSheet(result: result),
    );
  }

  void _startAutoScanning() {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      _cameraController!.startImageStream((CameraImage image) async {
        if (!_detectionService.isProcessing && !_isScanLocked) {
          try {
            final inputImage = _inputImageFromCameraImage(image);
            if (inputImage != null) {
              await _detectionService.processInputImage(inputImage);
            } else {
              // Only print once in a while to not flood logs
              if (DateTime.now().millisecond % 500 < 50) {
                debugPrint('AR_V_SCAN: Frame conversion returned null');
              }
            }
          } catch (e) {
            debugPrint('AR_V_SCAN: Frame processing error: $e');
          }
        }
      });
      debugPrint('AR_V_SCAN: Camera Stream Started');
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    
    // === ROTATION ===
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;
    if (image.planes.isEmpty) return null;

    // === FORMAT HANDLING ===
    InputImageFormat? format = InputImageFormatValue.fromRawValue(image.format.raw);
    
    // Default to NV21 for Android if unknown
    if (Platform.isAndroid && format == null) {
      format = InputImageFormat.nv21;
    }
    if (format == null) return null;

    // === BYTE ASSEMBLY (Robust for Android) ===
    Uint8List bytes;
    int bytesPerRow;

    if (Platform.isAndroid) {
      if (image.planes.length == 1 && (format == InputImageFormat.nv21 || format == InputImageFormat.yv12)) {
        // Single plane: usually already packed NV21/YV12
        bytes = image.planes[0].bytes;
        bytesPerRow = image.planes[0].bytesPerRow;
      } else {
        // Multiple planes (YUV_420_888): Pack and interleave into a tight NV21 buffer
        bytes = _yuv420ToNv21(image);
        bytesPerRow = image.width; // We've stripped the padding
        format = InputImageFormat.nv21;
      }
    } else {
      // iOS / other: use standard concatenation for BGRA8888
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      bytes = allBytes.done().buffer.asUint8List();
      bytesPerRow = image.planes[0].bytesPerRow;
    }

    // Periodic diagnostics (one every 2 seconds roughly)
    if (_detectionService.framesProcessed % 60 == 0) {
      debugPrint('AR_V_SCAN: Frame size: ${image.width}x${image.height}, format: $format, bytes: ${bytes.length}');
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: bytesPerRow,
      ),
    );
  }

  /// Robustly packs YUV_420_888 planes into a single NV21 (Semi-Planar) byte array.
  /// Strips row padding (rowStride > width) and interleaves VU chroma components.
  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final Uint8List nv21 = Uint8List((width * height * 1.5).toInt());
    
    // 1. Pack Y plane (Luminance)
    int idY = 0;
    final yBuffer = yPlane.bytes;
    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      final rowOffset = y * yRowStride;
      for (int x = 0; x < width; x++) {
        nv21[idY++] = yBuffer[rowOffset + x * yPixelStride];
      }
    }
    
    // 2. Interleave V and U planes (Chrominance VU interleaved)
    int idUV = width * height;
    final uvWidth = width ~/ 2;
    final uvHeight = height ~/ 2;
    
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < uvHeight; y++) {
      final rowOffset = y * uvRowStride;
      for (int x = 0; x < uvWidth; x++) {
        // NV21 is V-U interleaved
        // We use the pixel stride to pick the correct byte from the planes
        nv21[idUV++] = vBuffer[rowOffset + x * uvPixelStride];
        nv21[idUV++] = uBuffer[rowOffset + x * uvPixelStride];
      }
    }
    
    return nv21;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Layer 1: Camera feed with live ML processing
          _buildCameraLayer(),

          // Center Reticle with scanning state
          _buildCenterReticle(),

          // Layer 2: Scan line effect
          if (!_isScanLocked) _buildScanLineEffect(),

          // Layer 3: Results
          if (_vastuResults.isNotEmpty) _buildDetectionOverlay(),

          // Layer 4: UI Overlays
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 4),
                // Compass bar (top)
                _buildTopOverlay(),

                const SizedBox(height: 12),

                // AI Debug HUD
                _buildAIDebugHUD(),

                const Spacer(),

                // Score and Control (bottom)
                _buildBottomOverlay(),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: _buildBackButton(),
          ),

          // Loading overlay
          if (!_isInitialized) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopOverlay() {
    return ListenableBuilder(
      listenable: _compassService,
      builder: (context, _) {
        final data = _compassService.currentData;
        return CompassBar(
          heading: data.heading,
          cardinalDirection: data.cardinalDirection,
          directionLabel: data.directionLabel,
          isDemoMode: _compassService.isDemoMode,
        );
      },
    );
  }

  Widget _buildAIDebugHUD() {
    return ListenableBuilder(
      listenable: _detectionService,
      builder: (context, _) {
        final objects = _detectionService.detectedObjects;
        final isProcessing = _detectionService.isProcessing;
        final frameCount = _detectionService.framesProcessed;
        final lastError = _detectionService.lastError;

        // Build a summary of ALL detected objects
        String statusText;
        Color dotColor;
        if (objects.isNotEmpty) {
          final names = objects.map((o) => o.label.toUpperCase()).take(4).join(', ');
          final extra = objects.length > 4 ? ' +${objects.length - 4} more' : '';
          statusText = '🎯 ${objects.length} found: $names$extra';
          dotColor = Colors.green;
        } else if (lastError.isNotEmpty) {
          statusText = '⚠️ Error: ${lastError.substring(0, min(40, lastError.length))}';
          dotColor = Colors.red;
        } else {
          statusText = '🔍 Scanning... (frame #$frameCount)';
          dotColor = AppColors.saffron;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: objects.isNotEmpty
                  ? Colors.green.withOpacity(0.5)
                  : AppColors.saffron.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCenterReticle() {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isScanLocked ? 80 : 120,
        height: _isScanLocked ? 80 : 120,
        decoration: BoxDecoration(
          border: Border.all(
            color: _isScanLocked 
              ? Colors.white.withOpacity(0.3) 
              : AppColors.saffron.withOpacity(0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Corners - Saffron if scanning, White if locked
            _buildReticleCorner(true, true),
            _buildReticleCorner(true, false),
            _buildReticleCorner(false, true),
            _buildReticleCorner(false, false),
            
            // Center dot
            Center(
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: _isScanLocked ? Colors.white : AppColors.saffron,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReticleCorner(bool top, bool left) {
    final color = _isScanLocked ? Colors.white : AppColors.saffron;
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: top ? BorderSide(color: color, width: 2.5) : BorderSide.none,
            bottom: top ? BorderSide.none : BorderSide(color: color, width: 2.5),
            left: left ? BorderSide(color: color, width: 2.5) : BorderSide.none,
            right: left ? BorderSide.none : BorderSide(color: color, width: 2.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraLayer() {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      return SizedBox.expand(
        child: GestureDetector(
          onTap: _showManualEntrySheet,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize?.height ?? 1,
              height: _cameraController!.value.previewSize?.width ?? 1,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      );
    }

    // Demo mode fallback: dark gradient simulating a camera feed
    return GestureDetector(
      onTap: _showManualEntrySheet,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1E3A),
              Color(0xFF0D1020),
              Color(0xFF151830),
              Color(0xFF0A0D1F),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: Opacity(
            opacity: 0.04,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemCount: 64,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (_, i) => Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showManualEntrySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManualEntrySheet(
        currentHeading: _compassService.currentData.heading,
        onSave: (label, category, direction, notes) {
          final obj = DetectedObject.manual(label: label, notes: notes);
          _detectionService.addManualObject(obj);
          _onSensorUpdate(); // Force a re-evaluation
        },
      ),
    );
  }

  Future<void> _saveSession(BuildContext context) async {
    final session = _vastuEngine.session;
    if (session.results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No objects detected to save.')),
      );
      return;
    }

    await StorageService.instance.saveSession(session);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan saved successfully!'),
          backgroundColor: AppColors.compliant,
        ),
      );
    }
  }

  Widget _buildBottomOverlay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Save Button
            ElevatedButton.icon(
              onPressed: () => _saveSession(context),
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save JSON', style: TextStyle(fontFamily: 'Outfit')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardSurface,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            // Scan Lock Toggle
            GestureDetector(
              onTap: () {
                setState(() => _isScanLocked = !_isScanLocked);
                HapticFeedback.mediumImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _isScanLocked 
                    ? AppColors.saffron.withOpacity(0.9) 
                    : AppColors.compassBg,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _isScanLocked ? Colors.white : AppColors.glassBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (_isScanLocked)
                      BoxShadow(
                        color: AppColors.saffron.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isScanLocked ? Icons.lock : Icons.wifi_protected_setup,
                      color: _isScanLocked ? Colors.white : AppColors.saffron,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isScanLocked ? 'SCAN LOCKED' : 'SCANNING...',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _isScanLocked ? Colors.white : AppColors.textPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Map/Issues Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: AppColors.cardSurface,
              onSelected: (val) {
                if (val == 'map') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MapViewScreen(session: _vastuEngine.session)));
                } else if (val == 'issues') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => NonCompliantScreen(session: _vastuEngine.session)));
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'map', child: Row(children: [Icon(Icons.map, color: AppColors.gold, size: 20), SizedBox(width: 8), Text('Map View', style: TextStyle(color: Colors.white))])),
                const PopupMenuItem(value: 'issues', child: Row(children: [Icon(Icons.warning, color: AppColors.nonCompliant, size: 20), SizedBox(width: 8), Text('Issues', style: TextStyle(color: Colors.white))])),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Score indicator
        ListenableBuilder(
          listenable: _vastuEngine,
          builder: (context, _) {
            final session = _vastuEngine.session;
            return ScoreIndicator(
              score: session.score,
              totalItems: session.totalCount,
              compliantItems: session.compliantCount,
              nonCompliantItems: session.nonCompliantCount,
            );
          },
        ),
      ],
    );
  }

  Widget _buildScanLineEffect() {
    return AnimatedBuilder(
      animation: _scanLineAnimation,
      builder: (context, _) {
        return Positioned(
          top: _scanLineAnimation.value * MediaQuery.of(context).size.height,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.saffron.withOpacity(0),
                  AppColors.saffron.withOpacity(0.6),
                  AppColors.saffron.withOpacity(0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetectionOverlay() {
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return Stack(
          children: [
            // CustomPaint for bounding boxes
            CustomPaint(
              size: screenSize,
              painter: _BoundingBoxPainter(
                results: _vastuResults,
                pulseValue: _pulseAnimation.value,
              ),
            ),
            // Interactive label tags and info buttons
            ..._vastuResults.map((result) {
              final box = result.detectedObject.boundingBox;
              final left = box.left * screenSize.width;
              final top = box.top * screenSize.height;
              final boxHeight = box.height * screenSize.height;
              final isCompliant = result.isCompliant;
              final color =
                  isCompliant ? AppColors.compliant : AppColors.nonCompliant;

              return Positioned(
                left: left,
                top: top - 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompliant
                                ? Icons.check_circle
                                : Icons.warning_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            result.detectedObject.label.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(result.detectedObject.confidence * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Info button for non-compliant
                    if (!isCompliant)
                      Padding(
                        padding: EdgeInsets.only(top: boxHeight + 4),
                        child: GestureDetector(
                          onTap: () => _showRemediation(result),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.nonCompliant.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.nonCompliant
                                      .withOpacity(
                                          _pulseAnimation.value * 0.5),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lightbulb_outline,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Fix: ${result.rule.idealDirection}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.compassBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder, width: 1),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: AppColors.deepNavy.withOpacity(0.9),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.saffron),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Initializing Scanner...',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Loading Vastu rules & detection model',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bounding box painter for detected objects.
class _BoundingBoxPainter extends CustomPainter {
  final List<VastuResult> results;
  final double pulseValue;

  _BoundingBoxPainter({required this.results, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (final result in results) {
      final box = result.detectedObject.boundingBox;
      final rect = Rect.fromLTWH(
        box.left * size.width,
        box.top * size.height,
        box.width * size.width,
        box.height * size.height,
      );

      final isCompliant = result.isCompliant;
      final color = isCompliant ? AppColors.compliant : AppColors.nonCompliant;

      // Draw floating indicator arrow above the box
      _drawArrowPointer(canvas, rect, color);

      // Glow fill
      final glowPaint = Paint()
        ..color = color.withOpacity(pulseValue * 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        glowPaint,
      );

      // Border
      final borderPaint = Paint()
        ..color = color.withOpacity(0.7 + pulseValue * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        borderPaint,
      );

      // Corner brackets
      _drawCorners(canvas, rect, color);
    }
  }

  void _drawArrowPointer(Canvas canvas, Rect rect, Color color) {
    final center = rect.centerLeft.dx + rect.width / 2;
    final top = rect.top - 20 - (pulseValue * 10); // Pulse the arrow height
    
    final Path arrowPath = Path();
    arrowPath.moveTo(center - 10, top - 15);
    arrowPath.lineTo(center + 10, top - 15);
    arrowPath.lineTo(center, top); // Tip of the arrow
    arrowPath.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Add a small shadow/glow to the arrow
    canvas.drawShadow(arrowPath.shift(const Offset(0, 2)), Colors.black, 4, true);
    canvas.drawPath(arrowPath, paint);

    // Draw the "label" background directly above the arrow
    final RRect labelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center, top - 25), width: 80, height: 20),
      const Radius.circular(4),
    );
    canvas.drawRRect(labelRect, Paint()..color = color.withOpacity(0.9));
  }

  void _drawCorners(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const len = 16.0;

    // Top-left
    canvas.drawLine(Offset(rect.left, rect.top + len), rect.topLeft, paint);
    canvas.drawLine(rect.topLeft, Offset(rect.left + len, rect.top), paint);

    // Top-right
    canvas.drawLine(
        Offset(rect.right - len, rect.top), rect.topRight, paint);
    canvas.drawLine(
        rect.topRight, Offset(rect.right, rect.top + len), paint);

    // Bottom-left
    canvas.drawLine(
        Offset(rect.left, rect.bottom - len), rect.bottomLeft, paint);
    canvas.drawLine(
        rect.bottomLeft, Offset(rect.left + len, rect.bottom), paint);

    // Bottom-right
    canvas.drawLine(
        Offset(rect.right - len, rect.bottom), rect.bottomRight, paint);
    canvas.drawLine(
        Offset(rect.right, rect.bottom - len), rect.bottomRight, paint);
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) => true;
}
