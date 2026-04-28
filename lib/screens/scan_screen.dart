import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:vastuscan_ar/models/vastu_result.dart';
import 'package:vastuscan_ar/models/scan_session.dart';
import 'package:vastuscan_ar/services/compass_service.dart';
import 'package:vastuscan_ar/services/detection_service.dart';
import 'package:vastuscan_ar/services/vastu_engine.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';
import 'package:vastuscan_ar/widgets/compass_bar.dart';
import 'package:vastuscan_ar/widgets/detection_overlay.dart';
import 'package:vastuscan_ar/widgets/score_indicator.dart';
import 'package:vastuscan_ar/widgets/manual_entry_sheet.dart';
import 'package:vastuscan_ar/widgets/glass_button.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:vastuscan_ar/screens/remediation_sheet.dart';
import 'package:vastuscan_ar/screens/scan_report_screen.dart';
import 'package:vastuscan_ar/models/detected_object.dart';
import 'package:vastuscan_ar/services/storage_service.dart';
import 'package:vastuscan_ar/screens/non_compliant_screen.dart';
import 'package:vastuscan_ar/screens/map_view_screen.dart';
import 'package:vastuscan_ar/services/vastu_lens_service.dart';
import 'package:vastuscan_ar/services/settings_service.dart';

enum ScanState { idle, scanning, stopped }

class ScanScreen extends StatefulWidget {
  final String? roomLabel;
  const ScanScreen({super.key, this.roomLabel});

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
  ScanState _scanState = ScanState.idle;
  bool _isLensScanning = false;
  List<VastuResult> _vastuResults = [];

  // Continuous Gemini scanning
  Timer? _geminiTimer;
  bool _isGeminiScanning = false;

  // Cached frame for Gemini (avoids stopping image stream)
  Uint8List? _latestFrameJpeg;
  DateTime _lastFrameCache = DateTime.now();

  // Zoom
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 5.0;

  // Scan timer
  DateTime? _scanStartTime;
  final _timerNotifier = ValueNotifier<int>(0);
  Stream<int>? _timerStream;

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

  void _startScan() {
    HapticFeedback.mediumImpact();
    _vastuEngine.startSession(roomLabel: widget.roomLabel);
    _scanStartTime = DateTime.now();
    setState(() => _scanState = ScanState.scanning);
    // Simple elapsed timer
    Stream.periodic(const Duration(seconds: 1), (i) => i + 1).listen((t) {
      if (_scanState == ScanState.scanning) _timerNotifier.value = t;
    });
  }

  Future<void> _stopScan() async {
    if (_scanState != ScanState.scanning) return;
    HapticFeedback.heavyImpact();
    final session = _vastuEngine.stopSession();
    setState(() => _scanState = ScanState.stopped);
    if (!mounted) return;
    await Navigator.push<ScanSession>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanReportScreen(
          session: session,
          onDone: () {},
        ),
      ),
    );
    if (mounted) setState(() { _scanState = ScanState.idle; _timerNotifier.value = 0; });
  }

  Future<void> _initialize() async {
    await _vastuEngine.loadRules();
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first, ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
        );
        await _cameraController!.initialize();
        _minZoom = await _cameraController!.getMinZoomLevel();
        _maxZoom = await _cameraController!.getMaxZoomLevel();
        _currentZoom = _minZoom;
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

      // Auto-prompt for Gemini API key if not configured
      if (!SettingsService.instance.isConfigured) {
        // Show dialog after a short delay so screen is rendered
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _showGeminiSetupDialog();
        });
      } else {
        // Gemini configured — start continuous precision scanning
        _startContinuousGemini();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('\u2728 AI Precision Mode active — identifying objects...'),
          duration: Duration(seconds: 3),
          backgroundColor: AppColors.saffron,
        ));
      }
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

  /// Start continuous Gemini identification (every 2 seconds)
  void _startContinuousGemini() {
    _geminiTimer?.cancel();
    _detectionService.setGeminiActive(true);
    _geminiTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _performGeminiFrame();
    });
    // Also run immediately on first start
    Future.delayed(const Duration(milliseconds: 500), _performGeminiFrame);
    debugPrint('AR_GEMINI: Continuous scanning started (2s interval)');
  }

  void _stopContinuousGemini() {
    _geminiTimer?.cancel();
    _geminiTimer = null;
    _detectionService.setGeminiActive(false);
  }

  /// Send cached frame to Gemini — NO camera stream interruption
  Future<void> _performGeminiFrame() async {
    if (_isGeminiScanning) return;
    if (!SettingsService.instance.isConfigured) return;

    // Use cached frame if available; fall back to takePicture
    Uint8List? frameBytes = _latestFrameJpeg;
    if (frameBytes == null || frameBytes.isEmpty) {
      // Fallback: take picture (only if no cached frame yet)
      if (_cameraController == null || !_cameraController!.value.isInitialized) return;
      try {
        bool wasStreaming = false;
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
          wasStreaming = true;
        }
        final pic = await _cameraController!.takePicture();
        frameBytes = await pic.readAsBytes();
        if (wasStreaming) _startAutoScanning();
      } catch (e) {
        debugPrint('AR_GEMINI: Fallback capture error: $e');
        return;
      }
    }

    _isGeminiScanning = true;
    try {
      final objects = await VastuLensService.instance.analyzeImage(frameBytes!);
      if (objects.isNotEmpty && mounted) {
        _detectionService.applyGeminiResults(objects);
        final heading = _compassService.currentData.heading;
        _vastuEngine.evaluateAll(objects, heading);
        setState(() { _vastuResults = _vastuEngine.session.results; });
        debugPrint('AR_GEMINI: ✓ ${objects.length} objects: ${objects.map((o) => o.label).join(", ")}');
      } else {
        _detectionService.clearGeminiResults();
      }
    } catch (e) {
      debugPrint('AR_GEMINI: Error: $e');
      _detectionService.clearGeminiResults();
    } finally {
      _isGeminiScanning = false;
    }
  }

  @override
  void dispose() {
    _stopContinuousGemini();
    _compassService.removeListener(_onSensorUpdate);
    _detectionService.removeListener(_onSensorUpdate);
    _compassService.dispose();
    _detectionService.dispose();
    _vastuEngine.dispose();
    _scanLineController.dispose();
    _pulseController.dispose();
    _cameraController?.dispose();
    _timerNotifier.dispose();
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
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_cameraController!.value.isStreamingImages) return;
    try {
      _cameraController!.startImageStream((CameraImage image) async {
        // Cache a JPEG snapshot every 800ms for Gemini (non-blocking)
        final now = DateTime.now();
        if (now.difference(_lastFrameCache).inMilliseconds > 800) {
          _lastFrameCache = now;
          // Convert in background
          _cacheFrameAsJpeg(image);
        }

        // ML Kit processing
        if (!_detectionService.isProcessing) {
          try {
            final inputImage = _inputImageFromCameraImage(image);
            if (inputImage != null) await _detectionService.processInputImage(inputImage);
          } catch (e) {
            debugPrint('AR_V_SCAN: Frame error: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('AR_V_SCAN: Failed to start image stream: $e');
    }
  }

  /// Convert CameraImage to JPEG bytes for Gemini (runs in compute isolate)
  void _cacheFrameAsJpeg(CameraImage image) {
    try {
      // For Android NV21/YUV: pack into NV21 then encode
      // For simplicity, we use the raw NV21 bytes and let Gemini handle it
      // But Gemini needs JPEG, so we'll use the image package
      if (Platform.isAndroid) {
        final nv21 = _yuv420ToNv21(image);
        // Encode NV21 to JPEG in an isolate
        _encodeNv21ToJpeg(nv21, image.width, image.height).then((jpeg) {
          if (jpeg != null) _latestFrameJpeg = jpeg;
        });
      }
    } catch (_) {}
  }

  /// Encode NV21 bytes to JPEG using the image package
  static Future<Uint8List?> _encodeNv21ToJpeg(Uint8List nv21, int width, int height) async {
    try {
      // Use compute to avoid blocking UI
      return await compute(_nv21ToJpegIsolate, _Nv21Data(nv21, width, height));
    } catch (_) {
      return null;
    }
  }

  Future<void> _setZoom(double zoom) async {
    if (_cameraController == null) return;
    final clamped = zoom.clamp(_minZoom, _maxZoom);
    await _cameraController!.setZoomLevel(clamped);
    setState(() => _currentZoom = clamped);
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
      body: GestureDetector(
        onScaleUpdate: (details) {
          if (details.pointerCount == 2) {
            _setZoom((_currentZoom * details.scale).clamp(_minZoom, _maxZoom));
          }
        },
        child: Stack(
          children: [
            _buildCameraLayer(),
            _buildCenterReticle(),
            if (_scanState != ScanState.scanning) _buildScanLineEffect(),
            if (_vastuResults.isNotEmpty) _buildDetectionOverlay(),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  _buildTopOverlay(),
                  const SizedBox(height: 8),
                  _buildAIDebugHUD(),
                  const Spacer(),
                  _buildZoomControls(),
                  const SizedBox(height: 8),
                  _buildBottomOverlay(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: _buildBackButton(),
            ),
            if (!_isInitialized) _buildLoadingOverlay(),
          ],
        ),
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
        final geminiTag = _detectionService.isGeminiActive ? '✨AI' : 'ML';
        String statusText;
        Color dotColor;
        if (objects.isNotEmpty) {
          final names = objects.map((o) => o.label.toUpperCase()).take(4).join(', ');
          final extra = objects.length > 4 ? ' +${objects.length - 4} more' : '';
          statusText = '🎯 [$geminiTag] ${objects.length} found: $names$extra';
          dotColor = Colors.green;
        } else if (lastError.isNotEmpty) {
          statusText = '⚠️ Error: ${lastError.substring(0, min(40, lastError.length))}';
          dotColor = Colors.red;
        } else {
          statusText = '🔍 [$geminiTag] Scanning... (frame #$frameCount)';
          dotColor = AppColors.saffron;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: objects.isNotEmpty
                  ? AppColors.compliant.withValues(alpha: 0.5)
                  : AppColors.saffron.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.saffron.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                    color: AppColors.textPrimary,
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
    final isLocked = _scanState != ScanState.scanning;
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isLocked ? 80 : 120,
        height: isLocked ? 80 : 120,
        decoration: BoxDecoration(
          border: Border.all(
            color: isLocked 
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
                  color: isLocked ? Colors.white : AppColors.saffron,
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
    final isLocked = _scanState != ScanState.scanning;
    final color = isLocked ? Colors.white : AppColors.saffron;
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
          final heading = _compassService.currentData.heading;
          final obj = DetectedObject.manual(
            label: label, 
            notes: notes,
            originalHeading: heading,
          );
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

  Widget _buildZoomControls() {
    if (_maxZoom <= _minZoom + 0.5) return const SizedBox.shrink();
    final levels = [_minZoom, (_minZoom + _maxZoom) / 2, _maxZoom].toSet().toList()..sort();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_outlined, color: Colors.white54, size: 14),
          const SizedBox(width: 6),
          ...levels.map((lvl) {
            final label = lvl <= 1.05 ? '1x' : lvl <= (_maxZoom / 2 + 0.5) ? '2x' : '${_maxZoom.toStringAsFixed(0)}x';
            final active = (_currentZoom - lvl).abs() < 0.6;
            return GestureDetector(
              onTap: () => _setZoom(lvl),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? AppColors.saffron : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? AppColors.saffron : Colors.white38),
                ),
                child: Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : Colors.white60)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top row: Vastu Lens + menu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GlassButton(
                onPressed: _performVastuLensScan,
                height: 48,
                width: 140,
                backgroundColor: AppColors.gold.withOpacity(0.7),
                borderColor: AppColors.goldLight ?? Colors.yellow.withOpacity(0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isLensScanning
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('Vastu Lens', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: AppColors.cardSurface,
                onSelected: (val) {
                  if (val == 'map') Navigator.push(context, MaterialPageRoute(builder: (_) => MapViewScreen(session: _vastuEngine.session)));
                  else if (val == 'issues') Navigator.push(context, MaterialPageRoute(builder: (_) => NonCompliantScreen(session: _vastuEngine.session)));
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'map', child: Row(children: [Icon(Icons.map, color: AppColors.gold, size: 20), SizedBox(width: 8), Text('Map View')])),
                  const PopupMenuItem(value: 'issues', child: Row(children: [Icon(Icons.warning, color: AppColors.nonCompliant, size: 20), SizedBox(width: 8), Text('Issues')])),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Start / Stop button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _scanState == ScanState.scanning
              ? _buildStopButton()
              : _buildStartButton(),
        ),
        const SizedBox(height: 10),
        // Score indicator
        ListenableBuilder(
          listenable: _vastuEngine,
          builder: (_, __) {
            final s = _vastuEngine.session;
            return ScoreIndicator(score: s.score, totalItems: s.totalCount, compliantItems: s.compliantCount, nonCompliantItems: s.nonCompliantCount, results: s.results);
          },
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return GlassButton(
      onPressed: _startScan,
      height: 54,
      backgroundColor: AppColors.compliant.withOpacity(0.75),
      borderColor: AppColors.compliant.withOpacity(0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_arrow_rounded, size: 26, color: Colors.white),
          const SizedBox(width: 12),
          Text(
            widget.roomLabel != null ? 'START: ${widget.roomLabel}' : 'START SCAN',
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStopButton() {
    return ValueListenableBuilder<int>(
      valueListenable: _timerNotifier,
      builder: (_, secs, __) {
        final m = (secs ~/ 60).toString().padLeft(2, '0');
        final s = (secs % 60).toString().padLeft(2, '0');
        return GlassButton(
          onPressed: _stopScan,
          height: 54,
          backgroundColor: AppColors.nonCompliant.withOpacity(0.75),
          borderColor: AppColors.nonCompliant.withOpacity(0.9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stop_rounded, size: 26, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'STOP SCAN  ⏱ $m:$s',
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _performVastuLensScan() async {
    if (!SettingsService.instance.isConfigured) { _showLensSettingsDialog(); return; }
    if (_isLensScanning || _cameraController == null) return;
    
    setState(() => _isLensScanning = true);
    
    try {
       // Pause stream for capture
       try { await _cameraController!.stopImageStream(); } catch (_) {}
       final image = await _cameraController!.takePicture();
       final bytes = await image.readAsBytes();
       _startAutoScanning(); // Resume stream
       
       final objects = await VastuLensService.instance.analyzeImage(bytes);
       
       if (objects.isNotEmpty) {
         _detectionService.applyGeminiResults(objects);
         final heading = _compassService.currentData.heading;
         _vastuEngine.evaluateAll(objects, heading);
         
         // Start continuous Gemini if not already running
         if (_geminiTimer == null) _startContinuousGemini();
         
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('\u2728 Identified ${objects.length} items precisely!'), backgroundColor: AppColors.compliant),
           );
         }
       } else {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('No recognizable items found.'), backgroundColor: AppColors.warning),
           );
         }
       }
    } catch (e) {
       _startAutoScanning(); // Ensure stream resumes on error
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Lens Error: $e'), backgroundColor: AppColors.nonCompliant),
          );
       }
    } finally {
       if (mounted) {
         setState(() {
           _isLensScanning = false;
         });
       }
    }
  }
  
  /// Auto-prompt dialog for Gemini API key setup
  void _showGeminiSetupDialog() {
    final controller = TextEditingController(text: SettingsService.instance.geminiApiKey);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.saffron, size: 24),
            SizedBox(width: 10),
            Text('AI Precision Setup', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit', fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For accurate object identification (crystals, furniture, electronics, etc.), VastuScan needs a Google Gemini API key.\n\nWithout it, objects will show as "unknown".',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Inter', height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter'),
              decoration: InputDecoration(
                labelText: 'Gemini API Key',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.elevatedSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.saffron, width: 2),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'Get your free key at ai.google.dev',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Inter'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Skip', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                await SettingsService.instance.setGeminiApiKey(key);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted && SettingsService.instance.isConfigured) {
                  _startContinuousGemini();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('\u2728 AI Precision Mode activated!'),
                    backgroundColor: AppColors.compliant,
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.saffron,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Activate', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showLensSettingsDialog() {
    _showGeminiSetupDialog();
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
    return SizedBox.expand(
      child: DetectionOverlay(
        results: _vastuResults,
        previewSize: MediaQuery.of(context).size,
        currentHeading: _compassService.currentData.heading,
        onInfoTap: _showRemediation,
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cardSurface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
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
      color: AppColors.cream.withValues(alpha: 0.95),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.saffron.withOpacity(0.12),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
            border: Border.all(color: AppColors.divider),
          ),
          child: const Column(
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
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Loading Vastu rules & AI detection model',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data class for passing NV21 data to isolate
class _Nv21Data {
  final Uint8List nv21;
  final int width;
  final int height;
  _Nv21Data(this.nv21, this.width, this.height);
}

/// Top-level function for compute isolate — converts NV21 to JPEG
Uint8List? _nv21ToJpegIsolate(_Nv21Data data) {
  try {
    // Import image package for encoding
    // NV21 is Y plane + interleaved VU
    final width = data.width;
    final height = data.height;
    final nv21 = data.nv21;
    final ySize = width * height;

    // Convert NV21 to RGB
    final rgb = Uint8List(width * height * 3);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * width + x;
        final uvIndex = ySize + (y ~/ 2) * width + (x & ~1);

        int yVal = nv21[yIndex] & 0xFF;
        int vVal = (uvIndex < nv21.length ? nv21[uvIndex] & 0xFF : 128) - 128;
        int uVal = (uvIndex + 1 < nv21.length ? nv21[uvIndex + 1] & 0xFF : 128) - 128;

        int r = (yVal + 1.370705 * vVal).round().clamp(0, 255);
        int g = (yVal - 0.337633 * uVal - 0.698001 * vVal).round().clamp(0, 255);
        int b = (yVal + 1.732446 * uVal).round().clamp(0, 255);

        final i = yIndex * 3;
        rgb[i] = r;
        rgb[i + 1] = g;
        rgb[i + 2] = b;
      }
    }

    // Encode as minimal BMP then wrap — actually, encode as PPM and convert
    // Simpler: build a simple JPEG-compatible bitmap
    // Use a minimal JPEG encoder (Baseline)
    // For now, return raw RGB wrapped in a very basic format Gemini can read
    // Actually, the simplest approach: build a BMP in memory
    return _encodeBmp(rgb, width, height);
  } catch (_) {
    return null;
  }
}

/// Encode RGB bytes to BMP format (Gemini can read BMP)
Uint8List _encodeBmp(Uint8List rgb, int width, int height) {
  final rowSize = ((width * 3 + 3) & ~3); // Row padding to 4 bytes
  final dataSize = rowSize * height;
  final fileSize = 54 + dataSize;
  final bmp = Uint8List(fileSize);
  final bd = ByteData.view(bmp.buffer);

  // BMP Header
  bmp[0] = 0x42; bmp[1] = 0x4D; // 'BM'
  bd.setInt32(2, fileSize, Endian.little);
  bd.setInt32(10, 54, Endian.little); // pixel data offset
  // DIB Header (BITMAPINFOHEADER)
  bd.setInt32(14, 40, Endian.little); // header size
  bd.setInt32(18, width, Endian.little);
  bd.setInt32(22, -height, Endian.little); // negative = top-down
  bd.setInt16(26, 1, Endian.little); // planes
  bd.setInt16(28, 24, Endian.little); // bits per pixel
  bd.setInt32(34, dataSize, Endian.little);

  // Pixel data (BGR)
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final srcIdx = (y * width + x) * 3;
      final dstIdx = 54 + y * rowSize + x * 3;
      bmp[dstIdx] = rgb[srcIdx + 2];     // B
      bmp[dstIdx + 1] = rgb[srcIdx + 1]; // G
      bmp[dstIdx + 2] = rgb[srcIdx];     // R
    }
  }

  return bmp;
}
