/// Utility functions for compass direction calculations.
class DirectionUtils {
  DirectionUtils._();

  /// All 8 cardinal/intercardinal directions with their degree ranges.
  static const List<_DirectionEntry> _directions = [
    _DirectionEntry('N', 'North', 337.5, 22.5),
    _DirectionEntry('NE', 'North-East', 22.5, 67.5),
    _DirectionEntry('E', 'East', 67.5, 112.5),
    _DirectionEntry('SE', 'South-East', 112.5, 157.5),
    _DirectionEntry('S', 'South', 157.5, 202.5),
    _DirectionEntry('SW', 'South-West', 202.5, 247.5),
    _DirectionEntry('W', 'West', 247.5, 292.5),
    _DirectionEntry('NW', 'North-West', 292.5, 337.5),
  ];

  /// All 16 compass points for detailed display.
  static const List<_DirectionEntry> _directions16 = [
    _DirectionEntry('N', 'North', 348.75, 11.25),
    _DirectionEntry('NNE', 'North-North-East', 11.25, 33.75),
    _DirectionEntry('NE', 'North-East', 33.75, 56.25),
    _DirectionEntry('ENE', 'East-North-East', 56.25, 78.75),
    _DirectionEntry('E', 'East', 78.75, 101.25),
    _DirectionEntry('ESE', 'East-South-East', 101.25, 123.75),
    _DirectionEntry('SE', 'South-East', 123.75, 146.25),
    _DirectionEntry('SSE', 'South-South-East', 146.25, 168.75),
    _DirectionEntry('S', 'South', 168.75, 191.25),
    _DirectionEntry('SSW', 'South-South-West', 191.25, 213.75),
    _DirectionEntry('SW', 'South-West', 213.75, 236.25),
    _DirectionEntry('WSW', 'West-South-West', 236.25, 258.75),
    _DirectionEntry('W', 'West', 258.75, 281.25),
    _DirectionEntry('WNW', 'West-North-West', 281.25, 303.75),
    _DirectionEntry('NW', 'North-West', 303.75, 326.25),
    _DirectionEntry('NNW', 'North-North-West', 326.25, 348.75),
  ];

  /// Convert a heading (0-360°) to a cardinal direction code (N, NE, E...).
  static String headingToCardinal(double heading) {
    heading = _normalizeHeading(heading);
    for (final dir in _directions) {
      if (dir.containsHeading(heading)) {
        return dir.code;
      }
    }
    return 'N'; // Default fallback
  }

  /// Convert a heading to a full direction label.
  static String headingToLabel(double heading) {
    heading = _normalizeHeading(heading);
    for (final dir in _directions) {
      if (dir.containsHeading(heading)) {
        return dir.label;
      }
    }
    return 'North';
  }

  /// Convert a heading to a 16-point direction code.
  static String headingToCardinal16(double heading) {
    heading = _normalizeHeading(heading);
    for (final dir in _directions16) {
      if (dir.containsHeading(heading)) {
        return dir.code;
      }
    }
    return 'N';
  }

  /// Convert a cardinal code to its label.
  static String cardinalToLabel(String code) {
    final Map<String, String> labels = {
      'N': 'North',
      'NE': 'North-East',
      'E': 'East',
      'SE': 'South-East',
      'S': 'South',
      'SW': 'South-West',
      'W': 'West',
      'NW': 'North-West',
    };
    return labels[code] ?? code;
  }

  /// Get the center heading for a cardinal direction.
  static double cardinalToHeading(String code) {
    const Map<String, double> headings = {
      'N': 0.0,
      'NE': 45.0,
      'E': 90.0,
      'SE': 135.0,
      'S': 180.0,
      'SW': 225.0,
      'W': 270.0,
      'NW': 315.0,
    };
    return headings[code] ?? 0.0;
  }

  /// Normalize heading to 0-360 range.
  static double _normalizeHeading(double heading) {
    heading = heading % 360;
    if (heading < 0) heading += 360;
    return heading;
  }

  /// Get all 8 direction entries (for compass bar rendering).
  static List<Map<String, dynamic>> getAllDirections() {
    return _directions.map((d) => {
      'code': d.code,
      'label': d.label,
      'heading': cardinalToHeading(d.code),
    }).toList();
  }
}

class _DirectionEntry {
  final String code;
  final String label;
  final double min;
  final double max;

  const _DirectionEntry(this.code, this.label, this.min, this.max);

  bool containsHeading(double heading) {
    if (min > max) {
      return heading >= min || heading < max;
    }
    return heading >= min && heading < max;
  }
}
