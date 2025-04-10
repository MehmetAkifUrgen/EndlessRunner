import 'package:flame/components.dart';
import 'dart:math' as math;

enum ObstacleType { cube, wall, ramp, hole }

class BoundingBox {
  final Vector2 min;
  final Vector2 max;

  BoundingBox({required this.min, required this.max});

  bool intersects(BoundingBox other) {
    return (min.x <= other.max.x && max.x >= other.min.x) &&
        (min.y <= other.max.y && max.y >= other.min.y);
  }
}

class Obstacle {
  final ObstacleType type;
  final Vector2 position;
  final Vector2 size;
  final double rotation;
  final bool isActive;

  Obstacle({
    required this.type,
    required this.position,
    required this.size,
    this.rotation = 0.0,
    this.isActive = true,
  });

  static Obstacle generateRandom(double zPosition, int laneCount) {
    final rng = math.Random();
    final type = ObstacleType.values[rng.nextInt(ObstacleType.values.length)];

    final lane = rng.nextInt(laneCount);
    final xPosition = (lane - (laneCount - 1) / 2) * 2.0;

    late Vector2 size;

    switch (type) {
      case ObstacleType.cube:
        size = Vector2(1.0, 1.0);
        break;
      case ObstacleType.wall:
        size = Vector2(laneCount * 2.0, 2.0);
        break;
      case ObstacleType.ramp:
        size = Vector2(2.0, 1.0);
        break;
      case ObstacleType.hole:
        size = Vector2(2.0, 0.5);
        break;
    }

    return Obstacle(
      type: type,
      position: Vector2(xPosition, 0),
      size: size,
      rotation: type == ObstacleType.ramp ? math.pi / 4 : 0.0,
    );
  }

  BoundingBox getBoundingBox() {
    final halfWidth = size.x / 2;
    final halfHeight = size.y / 2;
    return BoundingBox(
      min: Vector2(position.x - halfWidth, position.y - halfHeight),
      max: Vector2(position.x + halfWidth, position.y + halfHeight),
    );
  }
}
