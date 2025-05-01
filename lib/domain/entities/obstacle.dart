import 'package:flame/components.dart';
import 'dart:math' as math;

enum ObstacleType {
  // Temel engeller
  cube,
  wall,
  ramp,
  hole,

  // Yeni eklenen engeller
  spikes, // Dikenler
  laserGrid, // Lazer ızgara
  fireWall, // Ateş duvarı
  electricField, // Elektrik alanı
  movingBlade, // Hareket eden bıçak
  drone, // Uçan drone engeli
}

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
  final bool isAnimated; // Animasyonlu mu?
  final int damage; // Engelin verdiği hasar miktarı
  final String? effectId; // Özel etki ID'si (sound, particle gibi)
  final double speed; // Hareket eden engeller için hız

  Obstacle({
    required this.type,
    required this.position,
    required this.size,
    this.rotation = 0.0,
    this.isActive = true,
    this.isAnimated = false,
    this.damage = 1,
    this.effectId,
    this.speed = 1.0,
  });

  static Obstacle generateRandom(double zPosition, int laneCount,
      {double difficulty = 1.0}) {
    final rng = math.Random();
    // Zorluk düzeyine göre daha tehlikeli engelleri daha sık üretir
    final typeValues = ObstacleType.values;
    final filteredTypes = difficulty < 0.5
        ? typeValues.where((t) => t.index < 4).toList() // Kolay engeller
        : typeValues; // Tüm engel tipleri

    final randomIndex = rng.nextInt(filteredTypes.length);
    final type = filteredTypes[randomIndex];

    final lane = rng.nextInt(laneCount);
    final xPosition = (lane - (laneCount - 1) / 2) * 2.0;

    // Tip bazında boyut belirleme
    late Vector2 size;
    late bool isAnimated = false;
    late int damage = 1;
    String? effectId;
    double speed = 1.0;

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
      case ObstacleType.spikes:
        size = Vector2(1.8, 0.8);
        damage = 2;
        effectId = 'spike_impact';
        break;
      case ObstacleType.laserGrid:
        size = Vector2(1.5, 2.5);
        isAnimated = true;
        damage = 2;
        effectId = 'laser_zap';
        break;
      case ObstacleType.fireWall:
        size = Vector2(laneCount * 1.5, 3.0);
        isAnimated = true;
        damage = 2;
        effectId = 'fire_burn';
        break;
      case ObstacleType.electricField:
        size = Vector2(2.0, 2.0);
        isAnimated = true;
        damage = 2;
        effectId = 'electric_shock';
        break;
      case ObstacleType.movingBlade:
        size = Vector2(1.2, 1.2);
        isAnimated = true;
        damage = 3;
        speed = 1.5 + rng.nextDouble() * difficulty;
        effectId = 'blade_slice';
        break;
      case ObstacleType.drone:
        size = Vector2(1.5, 1.0);
        isAnimated = true;
        damage = 1;
        speed = 1.2 + rng.nextDouble() * difficulty;
        effectId = 'drone_buzz';
        break;
    }

    return Obstacle(
      type: type,
      position: Vector2(xPosition, 0),
      size: size,
      rotation: type == ObstacleType.ramp ? math.pi / 4 : 0.0,
      isAnimated: isAnimated,
      damage: damage,
      effectId: effectId,
      speed: speed,
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

  // Engel animasyon zamanlaması için yardımcı metot
  double getAnimationFrequency() {
    switch (type) {
      case ObstacleType.electricField:
        return 10.0; // Hızlı yanıp sönme
      case ObstacleType.laserGrid:
        return 3.0; // Orta hızlı
      case ObstacleType.fireWall:
        return 5.0; // Alev dalgalanması
      case ObstacleType.movingBlade:
        return 8.0; // Hızlı dönme
      case ObstacleType.drone:
        return 2.0; // Yavaş hovering
      default:
        return 1.0;
    }
  }
}
