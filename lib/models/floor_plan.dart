import 'package:uuid/uuid.dart';

const Uuid _fpUuid = Uuid();

enum RoomType {
  livingRoom,
  bedroom,
  kitchen,
  bathroom,
  study,
  masterBedroom,
  reception,
  conference,
  openWork,
  cabin,
  breakRoom,
  balcony,
  // New room types
  diningRoom,
  poojaRoom,
  garage,
  garden,
  staircase,
  store,
  custom,
}

enum FloorPlanPreset { bhk1, bhk2, bhk3, villa, office, custom }

extension RoomTypeExt on RoomType {
  String get displayName {
    switch (this) {
      case RoomType.livingRoom: return 'Living Room';
      case RoomType.bedroom: return 'Bedroom';
      case RoomType.kitchen: return 'Kitchen';
      case RoomType.bathroom: return 'Bathroom';
      case RoomType.study: return 'Study';
      case RoomType.masterBedroom: return 'Master Bedroom';
      case RoomType.reception: return 'Reception';
      case RoomType.conference: return 'Conference';
      case RoomType.openWork: return 'Work Area';
      case RoomType.cabin: return 'Cabin';
      case RoomType.breakRoom: return 'Break Room';
      case RoomType.balcony: return 'Balcony';
      case RoomType.diningRoom: return 'Dining Room';
      case RoomType.poojaRoom: return 'Pooja Room';
      case RoomType.garage: return 'Garage';
      case RoomType.garden: return 'Garden';
      case RoomType.staircase: return 'Staircase';
      case RoomType.store: return 'Store Room';
      case RoomType.custom: return 'Room';
    }
  }

  String get emoji {
    switch (this) {
      case RoomType.livingRoom: return '🛋️';
      case RoomType.bedroom: return '🛏️';
      case RoomType.kitchen: return '🍳';
      case RoomType.bathroom: return '🚿';
      case RoomType.study: return '📚';
      case RoomType.masterBedroom: return '🛏️';
      case RoomType.reception: return '🏢';
      case RoomType.conference: return '📋';
      case RoomType.openWork: return '💻';
      case RoomType.cabin: return '🪑';
      case RoomType.breakRoom: return '☕';
      case RoomType.balcony: return '🌿';
      case RoomType.diningRoom: return '🍽️';
      case RoomType.poojaRoom: return '🪔';
      case RoomType.garage: return '🚗';
      case RoomType.garden: return '🌳';
      case RoomType.staircase: return '🪜';
      case RoomType.store: return '📦';
      case RoomType.custom: return '🏠';
    }
  }

  /// Vastu ideal zone for this room type
  String get idealZone {
    switch (this) {
      case RoomType.livingRoom: return 'NE or N';
      case RoomType.bedroom: return 'SW';
      case RoomType.masterBedroom: return 'SW';
      case RoomType.kitchen: return 'SE';
      case RoomType.bathroom: return 'NW or W';
      case RoomType.study: return 'NE or N';
      case RoomType.reception: return 'NE or N';
      case RoomType.conference: return 'NW';
      case RoomType.openWork: return 'E or N';
      case RoomType.cabin: return 'SW';
      case RoomType.breakRoom: return 'NW';
      case RoomType.balcony: return 'N or E';
      case RoomType.diningRoom: return 'W';
      case RoomType.poojaRoom: return 'NE';
      case RoomType.garage: return 'NW';
      case RoomType.garden: return 'N or E';
      case RoomType.staircase: return 'SW';
      case RoomType.store: return 'NW';
      case RoomType.custom: return 'Center';
    }
  }
}

/// A single room in a floor plan.
class Room {
  final String id;
  String name;
  final RoomType type;

  // Normalized coordinates (0.0–1.0 relative to plan canvas)
  double left;
  double top;
  double width;
  double height;

  // 3D rendering
  double wallHeight;

  double vastuScore;
  bool isScanned;
  int scanCount;
  String? lastScanId;

  Room({
    required this.id,
    required this.name,
    required this.type,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.wallHeight = 0.15,
    this.vastuScore = 0,
    this.isScanned = false,
    this.scanCount = 0,
    this.lastScanId,
  });

  Room copyWith({
    String? name,
    double? vastuScore,
    bool? isScanned,
    int? scanCount,
    String? lastScanId,
  }) {
    return Room(
      id: id,
      name: name ?? this.name,
      type: type,
      left: left,
      top: top,
      width: width,
      height: height,
      wallHeight: wallHeight,
      vastuScore: vastuScore ?? this.vastuScore,
      isScanned: isScanned ?? this.isScanned,
      scanCount: scanCount ?? this.scanCount,
      lastScanId: lastScanId ?? this.lastScanId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'left': left,
        'top': top,
        'width': width,
        'height': height,
        'wallHeight': wallHeight,
        'vastuScore': vastuScore,
        'isScanned': isScanned,
        'scanCount': scanCount,
        'lastScanId': lastScanId,
      };

  factory Room.fromJson(Map<String, dynamic> j) => Room(
        id: j['id'] as String,
        name: j['name'] as String,
        type: RoomType.values.firstWhere((e) => e.name == j['type'],
            orElse: () => RoomType.custom),
        left: (j['left'] as num).toDouble(),
        top: (j['top'] as num).toDouble(),
        width: (j['width'] as num).toDouble(),
        height: (j['height'] as num).toDouble(),
        wallHeight: (j['wallHeight'] as num?)?.toDouble() ?? 0.15,
        vastuScore: (j['vastuScore'] as num?)?.toDouble() ?? 0,
        isScanned: j['isScanned'] as bool? ?? false,
        scanCount: j['scanCount'] as int? ?? 0,
        lastScanId: j['lastScanId'] as String?,
      );
}

/// A floor plan containing multiple rooms.
class FloorPlan {
  final String id;
  String name;
  final FloorPlanPreset preset;
  final List<Room> rooms;
  final List<PlanElement> elements;
  final DateTime createdAt;

  FloorPlan({
    required this.id,
    required this.name,
    required this.preset,
    required this.rooms,
    List<PlanElement>? elements,
    required this.createdAt,
  }) : elements = elements ?? [];

  double get overallScore {
    final scanned = rooms.where((r) => r.isScanned).toList();
    if (scanned.isEmpty) return 0;
    return scanned.map((r) => r.vastuScore).reduce((a, b) => a + b) /
        scanned.length;
  }

  // ─── Presets ────────────────────────────────────────────────

  static FloorPlan preset1BHK() => FloorPlan(
        id: _fpUuid.v4(), name: '1 BHK Home', preset: FloorPlanPreset.bhk1,
        createdAt: DateTime.now(),
        rooms: [
          Room(id: _fpUuid.v4(), name: 'Living Room', type: RoomType.livingRoom, left: 0.0, top: 0.0, width: 0.6, height: 0.48),
          Room(id: _fpUuid.v4(), name: 'Kitchen', type: RoomType.kitchen, left: 0.6, top: 0.0, width: 0.4, height: 0.38),
          Room(id: _fpUuid.v4(), name: 'Bedroom', type: RoomType.bedroom, left: 0.0, top: 0.48, width: 0.6, height: 0.52),
          Room(id: _fpUuid.v4(), name: 'Bathroom', type: RoomType.bathroom, left: 0.6, top: 0.38, width: 0.4, height: 0.32),
          Room(id: _fpUuid.v4(), name: 'Balcony', type: RoomType.balcony, left: 0.6, top: 0.70, width: 0.4, height: 0.30),
        ],
        elements: [
          PlanElement(id: _fpUuid.v4(), type: ElementType.door, label: 'Main Door', x: 0.0, y: 0.24, wall: WallSide.west, direction: 'W'),
        ],
      );

  static FloorPlan preset2BHK() => FloorPlan(
        id: _fpUuid.v4(), name: '2 BHK Home', preset: FloorPlanPreset.bhk2,
        createdAt: DateTime.now(),
        rooms: [
          Room(id: _fpUuid.v4(), name: 'Living Room', type: RoomType.livingRoom, left: 0.0, top: 0.0, width: 0.55, height: 0.42),
          Room(id: _fpUuid.v4(), name: 'Kitchen', type: RoomType.kitchen, left: 0.55, top: 0.0, width: 0.45, height: 0.42),
          Room(id: _fpUuid.v4(), name: 'Master Bedroom', type: RoomType.masterBedroom, left: 0.0, top: 0.42, width: 0.55, height: 0.58),
          Room(id: _fpUuid.v4(), name: 'Bedroom 2', type: RoomType.bedroom, left: 0.55, top: 0.42, width: 0.45, height: 0.36),
          Room(id: _fpUuid.v4(), name: 'Bathroom', type: RoomType.bathroom, left: 0.55, top: 0.78, width: 0.45, height: 0.22),
        ],
        elements: [
          PlanElement(id: _fpUuid.v4(), type: ElementType.door, label: 'Main Door', x: 0.0, y: 0.21, wall: WallSide.west, direction: 'W'),
        ],
      );

  static FloorPlan preset3BHK() => FloorPlan(
        id: _fpUuid.v4(), name: '3 BHK Home', preset: FloorPlanPreset.bhk3,
        createdAt: DateTime.now(),
        rooms: [
          Room(id: _fpUuid.v4(), name: 'Living Room', type: RoomType.livingRoom, left: 0.0, top: 0.0, width: 0.45, height: 0.35),
          Room(id: _fpUuid.v4(), name: 'Dining Room', type: RoomType.diningRoom, left: 0.45, top: 0.0, width: 0.30, height: 0.35),
          Room(id: _fpUuid.v4(), name: 'Kitchen', type: RoomType.kitchen, left: 0.75, top: 0.0, width: 0.25, height: 0.35),
          Room(id: _fpUuid.v4(), name: 'Master Bedroom', type: RoomType.masterBedroom, left: 0.0, top: 0.35, width: 0.50, height: 0.35),
          Room(id: _fpUuid.v4(), name: 'Bedroom 2', type: RoomType.bedroom, left: 0.50, top: 0.35, width: 0.50, height: 0.35),
          Room(id: _fpUuid.v4(), name: 'Bedroom 3', type: RoomType.bedroom, left: 0.0, top: 0.70, width: 0.35, height: 0.30),
          Room(id: _fpUuid.v4(), name: 'Pooja Room', type: RoomType.poojaRoom, left: 0.35, top: 0.70, width: 0.20, height: 0.30),
          Room(id: _fpUuid.v4(), name: 'Bathroom 1', type: RoomType.bathroom, left: 0.55, top: 0.70, width: 0.20, height: 0.30),
          Room(id: _fpUuid.v4(), name: 'Bathroom 2', type: RoomType.bathroom, left: 0.75, top: 0.70, width: 0.25, height: 0.30),
        ],
        elements: [
          PlanElement(id: _fpUuid.v4(), type: ElementType.door, label: 'Main Door', x: 0.0, y: 0.17, wall: WallSide.west, direction: 'W'),
          PlanElement(id: _fpUuid.v4(), type: ElementType.window, label: 'Window', x: 0.5, y: 0.0, wall: WallSide.north, direction: 'N'),
        ],
      );

  static FloorPlan presetVilla() => FloorPlan(
        id: _fpUuid.v4(), name: 'Villa', preset: FloorPlanPreset.villa,
        createdAt: DateTime.now(),
        rooms: [
          Room(id: _fpUuid.v4(), name: 'Living Room', type: RoomType.livingRoom, left: 0.0, top: 0.0, width: 0.40, height: 0.30),
          Room(id: _fpUuid.v4(), name: 'Dining Room', type: RoomType.diningRoom, left: 0.40, top: 0.0, width: 0.30, height: 0.30),
          Room(id: _fpUuid.v4(), name: 'Kitchen', type: RoomType.kitchen, left: 0.70, top: 0.0, width: 0.30, height: 0.30),
          Room(id: _fpUuid.v4(), name: 'Master Bedroom', type: RoomType.masterBedroom, left: 0.0, top: 0.30, width: 0.35, height: 0.30),
          Room(id: _fpUuid.v4(), name: 'Bedroom 2', type: RoomType.bedroom, left: 0.35, top: 0.30, width: 0.30, height: 0.30),
          Room(id: _fpUuid.v4(), name: 'Bedroom 3', type: RoomType.bedroom, left: 0.65, top: 0.30, width: 0.35, height: 0.30),
          Room(id: _fpUuid.v4(), name: 'Pooja Room', type: RoomType.poojaRoom, left: 0.0, top: 0.60, width: 0.20, height: 0.20),
          Room(id: _fpUuid.v4(), name: 'Study', type: RoomType.study, left: 0.20, top: 0.60, width: 0.25, height: 0.20),
          Room(id: _fpUuid.v4(), name: 'Bathroom 1', type: RoomType.bathroom, left: 0.45, top: 0.60, width: 0.20, height: 0.20),
          Room(id: _fpUuid.v4(), name: 'Bathroom 2', type: RoomType.bathroom, left: 0.65, top: 0.60, width: 0.15, height: 0.20),
          Room(id: _fpUuid.v4(), name: 'Garage', type: RoomType.garage, left: 0.80, top: 0.60, width: 0.20, height: 0.20),
          Room(id: _fpUuid.v4(), name: 'Garden', type: RoomType.garden, left: 0.0, top: 0.80, width: 0.50, height: 0.20),
          Room(id: _fpUuid.v4(), name: 'Balcony', type: RoomType.balcony, left: 0.50, top: 0.80, width: 0.50, height: 0.20),
        ],
        elements: [
          PlanElement(id: _fpUuid.v4(), type: ElementType.door, label: 'Main Gate', x: 0.0, y: 0.15, wall: WallSide.west, direction: 'W'),
          PlanElement(id: _fpUuid.v4(), type: ElementType.door, label: 'Back Door', x: 1.0, y: 0.5, wall: WallSide.east, direction: 'E'),
          PlanElement(id: _fpUuid.v4(), type: ElementType.window, label: 'Window N', x: 0.3, y: 0.0, wall: WallSide.north, direction: 'N'),
          PlanElement(id: _fpUuid.v4(), type: ElementType.window, label: 'Window E', x: 1.0, y: 0.15, wall: WallSide.east, direction: 'E'),
        ],
      );

  static FloorPlan presetOffice() => FloorPlan(
        id: _fpUuid.v4(), name: 'Office Layout', preset: FloorPlanPreset.office,
        createdAt: DateTime.now(),
        rooms: [
          Room(id: _fpUuid.v4(), name: 'Reception', type: RoomType.reception, left: 0.0, top: 0.0, width: 1.0, height: 0.20),
          Room(id: _fpUuid.v4(), name: 'Open Work Area', type: RoomType.openWork, left: 0.0, top: 0.20, width: 0.62, height: 0.52),
          Room(id: _fpUuid.v4(), name: 'Conference Room', type: RoomType.conference, left: 0.62, top: 0.20, width: 0.38, height: 0.36),
          Room(id: _fpUuid.v4(), name: 'Cabin', type: RoomType.cabin, left: 0.62, top: 0.56, width: 0.38, height: 0.24),
          Room(id: _fpUuid.v4(), name: 'Break Room', type: RoomType.breakRoom, left: 0.0, top: 0.72, width: 1.0, height: 0.28),
        ],
        elements: [
          PlanElement(id: _fpUuid.v4(), type: ElementType.door, label: 'Entrance', x: 0.5, y: 0.0, wall: WallSide.north, direction: 'N'),
        ],
      );

  static FloorPlan generateCustom({
    required String name,
    required Map<RoomType, int> roomCounts,
  }) {
    List<Room> generatedRooms = [];
    int totalRooms = roomCounts.values.fold(0, (a, b) => a + b);
    if (totalRooms == 0) return FloorPlan(id: _fpUuid.v4(), name: name, preset: FloorPlanPreset.custom, createdAt: DateTime.now(), rooms: []);

    int cols = totalRooms <= 4 ? 2 : 3;
    int rows = (totalRooms / cols).ceil();
    if (rows == 0) rows = 1;
    double roomWidth = 1.0 / cols;
    double roomHeight = 1.0 / rows;
    int index = 0;
    
    final order = [RoomType.livingRoom, RoomType.masterBedroom, RoomType.diningRoom, RoomType.kitchen, RoomType.poojaRoom, RoomType.bathroom, RoomType.bedroom, RoomType.study, RoomType.balcony, RoomType.garage, RoomType.garden, RoomType.staircase, RoomType.store, RoomType.reception, RoomType.openWork, RoomType.conference, RoomType.cabin, RoomType.breakRoom, RoomType.custom];

    for (var type in order) {
      int count = roomCounts[type] ?? 0;
      for (int i = 0; i < count; i++) {
        int col = index % cols;
        int row = index ~/ cols;
        double finalWidth = roomWidth;
        if (row == rows - 1 && index == totalRooms - 1 && (index % cols) == 0 && cols > 1) finalWidth = 1.0;
        generatedRooms.add(Room(id: _fpUuid.v4(), name: count > 1 ? '${type.displayName} ${i + 1}' : type.displayName, type: type, left: col * roomWidth, top: row * roomHeight, width: finalWidth, height: roomHeight));
        index++;
      }
    }

    return FloorPlan(id: _fpUuid.v4(), name: name, preset: FloorPlanPreset.custom, createdAt: DateTime.now(), rooms: generatedRooms);
  }

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'preset': preset.name,
        'rooms': rooms.map((r) => r.toJson()).toList(),
        'elements': elements.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory FloorPlan.fromJson(Map<String, dynamic> j) => FloorPlan(
        id: j['id'] as String, name: j['name'] as String,
        preset: FloorPlanPreset.values.firstWhere((e) => e.name == j['preset'], orElse: () => FloorPlanPreset.bhk1),
        rooms: (j['rooms'] as List).map((r) => Room.fromJson(r as Map<String, dynamic>)).toList(),
        elements: j['elements'] != null ? (j['elements'] as List).map((e) => PlanElement.fromJson(e as Map<String, dynamic>)).toList() : [],
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

// ─── Plan Elements (Doors, Windows) ──────────────────────────

enum ElementType { door, window }
enum WallSide { north, south, east, west }

class PlanElement {
  final String id;
  final ElementType type;
  String label;
  double x; // normalized 0-1
  double y; // normalized 0-1
  final WallSide wall;
  final String direction; // N, S, E, W, NE, etc.

  PlanElement({required this.id, required this.type, required this.label, required this.x, required this.y, required this.wall, required this.direction});

  String get emoji => type == ElementType.door ? '🚪' : '🪟';

  bool get isVastuCompliant {
    // Doors: N, NE, E are auspicious
    if (type == ElementType.door) return ['N', 'NE', 'E'].contains(direction);
    // Windows: N, E, NE, NW are good
    return ['N', 'NE', 'E', 'NW'].contains(direction);
  }

  Map<String, dynamic> toJson() => {'id': id, 'type': type.name, 'label': label, 'x': x, 'y': y, 'wall': wall.name, 'direction': direction};

  factory PlanElement.fromJson(Map<String, dynamic> j) => PlanElement(
    id: j['id'] as String,
    type: ElementType.values.firstWhere((e) => e.name == j['type'], orElse: () => ElementType.door),
    label: j['label'] as String,
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    wall: WallSide.values.firstWhere((e) => e.name == j['wall'], orElse: () => WallSide.north),
    direction: j['direction'] as String? ?? 'N',
  );
}
