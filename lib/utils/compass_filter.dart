import 'dart:math';

/// Low-pass (Exponential Moving Average) filter for compass heading.
///
/// Uses sin/cos decomposition to handle the 360°→0° wraparound correctly.
class CompassFilter {
  /// Smoothing factor (0.0 = very smooth/slow, 1.0 = no smoothing).
  final double alpha;

  double _smoothedSin = 0.0;
  double _smoothedCos = 1.0; // Start pointing North
  bool _isInitialized = false;

  CompassFilter({this.alpha = 0.15});

  /// Apply the low-pass filter to a raw heading value.
  /// Returns the smoothed heading in degrees (0–360).
  double filter(double rawHeading) {
    final radians = rawHeading * pi / 180.0;
    final rawSin = sin(radians);
    final rawCos = cos(radians);

    if (!_isInitialized) {
      _smoothedSin = rawSin;
      _smoothedCos = rawCos;
      _isInitialized = true;
    } else {
      _smoothedSin = alpha * rawSin + (1 - alpha) * _smoothedSin;
      _smoothedCos = alpha * rawCos + (1 - alpha) * _smoothedCos;
    }

    // Convert back to degrees
    var smoothedDegrees = atan2(_smoothedSin, _smoothedCos) * 180.0 / pi;
    if (smoothedDegrees < 0) {
      smoothedDegrees += 360.0;
    }

    return smoothedDegrees;
  }

  /// Reset the filter state.
  void reset() {
    _smoothedSin = 0.0;
    _smoothedCos = 1.0;
    _isInitialized = false;
  }
}
