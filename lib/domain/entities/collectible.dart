import 'dart:math' as math;
import 'obstacle.dart'; // Aynı klasörde
import 'package:flame/components.dart';

enum CollectibleType {
  coin, // Para, puan kazandırır
  extraLife, // Ekstra can
  scoreBoost, // Puan artırıcı
  shield, // Geçici dokunulmazlık kalkanı
  magnet, // Paraları kendine çeker
  speedBoost, // Geçici hız artışı
  slowMotion // Engelleri yavaşlatır
}

class Collectible {
  final CollectibleType type;
  final Vector2 position;
  final double size;
  final bool isActive;

  Collectible({
    required this.type,
    required this.position,
    this.size = 0.5,
    this.isActive = true,
  });

  // Yeni toplanılabilir öğe örnekleri oluşturan fabrika metodu
  static Collectible generateRandom(double zPosition, int laneCount) {
    final rng = math.Random();

    // Çoğunlukla coin, ara sıra diğer öğeler
    CollectibleType type;
    final typeRoll = rng.nextDouble();
    if (typeRoll < 0.85) {
      type = CollectibleType.coin;
    } else if (typeRoll < 0.95) {
      type = CollectibleType.scoreBoost;
    } else {
      type = CollectibleType.extraLife;
    }

    // Rastgele şerit pozisyonu
    final lane = rng.nextInt(laneCount);
    final xPosition = (lane - (laneCount - 1) / 2) * 2.0;

    // Y pozisyonu (havada)
    final yPosition = rng.nextDouble() * 2.0;

    return Collectible(
      type: type,
      position: Vector2(xPosition, yPosition),
    );
  }

  // Çarpışma kontrolü için sınır kutusu oluştur
  BoundingBox getBoundingBox() {
    final halfSize = size / 2;
    return BoundingBox(
      min: Vector2(position.x - halfSize, position.y - halfSize),
      max: Vector2(position.x + halfSize, position.y + halfSize),
    );
  }
}
 