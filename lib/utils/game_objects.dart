import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../domain/entities/obstacle.dart'; // Güncellendi
import '../domain/entities/collectible.dart'; // Güncellendi
import 'dart:math' as math;

class GameObjects {
  // Oyuncu karakterini oluştur
  static PositionComponent createPlayer() {
    final player = RectangleComponent(
      size: Vector2(40, 60),
      position: Vector2(0, 0),
      paint: Paint()..color = Colors.red,
      anchor: Anchor.bottomLeft,
    );
    return player;
  }

  // Engel nesnesi oluştur
  static PositionComponent createObstacle(ObstacleType type) {
    switch (type) {
      case ObstacleType.cube:
        return RectangleComponent(
          size: Vector2(30, 30),
          paint: Paint()..color = Colors.orangeAccent,
          anchor: Anchor.bottomLeft,
        );

      case ObstacleType.wall:
        return RectangleComponent(
          size: Vector2(80, 50),
          paint: Paint()..color = Colors.orangeAccent,
          anchor: Anchor.bottomLeft,
        );

      case ObstacleType.ramp:
        final ramp = RectangleComponent(
          size: Vector2(40, 20),
          paint: Paint()..color = Colors.orangeAccent,
          anchor: Anchor.bottomLeft,
        );
        ramp.angle = math.pi / 4; // 45 derece
        return ramp;

      case ObstacleType.hole:
        return RectangleComponent(
          size: Vector2(40, 10),
          paint: Paint()..color = Colors.black,
          anchor: Anchor.bottomLeft,
        );
    }
  }

  // Toplanabilir öğe oluştur
  static PositionComponent createCollectible(CollectibleType type) {
    final collectible = CircleComponent(
      radius: 12.5,
      paint: Paint()..color = Colors.yellowAccent, // Renk türe göre değişebilir
      anchor: Anchor.center,
    );
    // TODO: Farklı toplanabilir türleri için farklı görünümler ekle
    return collectible;
  }

  // Basit küp oluştur
  static PositionComponent createSimpleCube() {
    final cube = RectangleComponent(
      size: Vector2(30, 30),
      paint: Paint()..color = Colors.orangeAccent,
      anchor: Anchor.bottomLeft,
    );
    return cube;
  }
}
