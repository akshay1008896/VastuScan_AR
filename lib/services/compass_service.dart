import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:vastuscan_ar/models/compass_data.dart';
import 'package:vastuscan_ar/utils/compass_filter.dart';
import 'package:vastuscan_ar/utils/direction_utils.dart';
import 'package:flutter_compass/flutter_compass.dart' as import_compass;

/// Service that provides filtered compass heading data.
///
/// Uses flutter_compass on real devices, falls back to simulated
/// compass data in demo mode (emulator/desktop).
class CompassService extends ChangeNotifier {
  final CompassFilter _filter = CompassFilter(alpha: 0.7);

  CompassData _currentData = CompassData.empty();
  CompassData get currentData => _currentData;

  StreamSubscription? _compassSubscription;
  Timer? _demoTimer;
  bool _isDemoMode = false;
  bool get isDemoMode => _isDemoMode;

  bool _isActive = false;
  bool get isActive => _isActive;

  /// Start listening to compass updates.
  Future<void> start({bool forceDemoMode = false}) async {
    if (_isActive) return;
    _isActive = true;

    if (forceDemoMode || kIsWeb) {
      _startDemoMode();
      return;
    }

    try {
      // Try to import and use flutter_compass
      // On real devices, this will work
      await _startRealCompass();
    } catch (e) {
      // Fallback to demo mode if compass not available
      print('Compass not available, switching to demo mode: $e');
      _startDemoMode();
    }
  }

  Future<void> _startRealCompass() async {
    try {
      import_compass.FlutterCompass.events?.listen((event) {
        if (event.heading != null) {
          _updateHeading(event.heading!);
        }
      }, onError: (e) {
        _startDemoMode();
      });
    } catch (e) {
      _startDemoMode();
    }
  }

  void _startDemoMode() {
    _isDemoMode = true;
    double demoHeading = 0;
    final random = Random();

    _demoTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // Simulate slow rotation with some jitter
      demoHeading += 0.3 + (random.nextDouble() - 0.5) * 2.0;
      if (demoHeading >= 360) demoHeading -= 360;
      if (demoHeading < 0) demoHeading += 360;

      _updateHeading(demoHeading);
    });

    notifyListeners();
  }

  /// Process a raw heading value through the filter.
  void _updateHeading(double rawHeading) {
    final filtered = _filter.filter(rawHeading);
    final cardinal = DirectionUtils.headingToCardinal(filtered);
    final label = DirectionUtils.headingToLabel(filtered);

    _currentData = CompassData(
      heading: filtered,
      rawHeading: rawHeading,
      cardinalDirection: cardinal,
      directionLabel: label,
      accuracy: _isDemoMode ? 2 : 3,
    );

    notifyListeners();
  }

  /// Manually set heading (for testing or external input).
  void setHeading(double heading) {
    _updateHeading(heading);
  }

  /// Stop compass updates.
  void stop() {
    _isActive = false;
    _compassSubscription?.cancel();
    _compassSubscription = null;
    _demoTimer?.cancel();
    _demoTimer = null;
  }

  /// Reset filter and data.
  void reset() {
    _filter.reset();
    _currentData = CompassData.empty();
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
