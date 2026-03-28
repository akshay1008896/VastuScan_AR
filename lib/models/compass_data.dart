/// Compass data model with filtered heading and cardinal direction.
class CompassData {
  /// Heading in degrees (0-360), where 0 = North.
  final double heading;

  /// Raw (unfiltered) heading from sensor.
  final double rawHeading;

  /// Cardinal direction string (N, NE, E, SE, S, SW, W, NW).
  final String cardinalDirection;

  /// Full direction label (e.g., "North-East").
  final String directionLabel;

  /// Accuracy level (0=unreliable, 1=low, 2=medium, 3=high).
  final int accuracy;

  const CompassData({
    required this.heading,
    required this.rawHeading,
    required this.cardinalDirection,
    required this.directionLabel,
    this.accuracy = 3,
  });

  factory CompassData.empty() {
    return const CompassData(
      heading: 0,
      rawHeading: 0,
      cardinalDirection: 'N',
      directionLabel: 'North',
      accuracy: 0,
    );
  }

  CompassData copyWith({
    double? heading,
    double? rawHeading,
    String? cardinalDirection,
    String? directionLabel,
    int? accuracy,
  }) {
    return CompassData(
      heading: heading ?? this.heading,
      rawHeading: rawHeading ?? this.rawHeading,
      cardinalDirection: cardinalDirection ?? this.cardinalDirection,
      directionLabel: directionLabel ?? this.directionLabel,
      accuracy: accuracy ?? this.accuracy,
    );
  }

  @override
  String toString() =>
      'CompassData(heading: ${heading.toStringAsFixed(1)}°, direction: $directionLabel)';
}
