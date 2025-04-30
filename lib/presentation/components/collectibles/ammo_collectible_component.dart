import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../pages/game_screen.dart';
import '../player/human_player_component.dart';
import '../../../services/audio_service.dart';

class AmmoCollectibleComponent extends PositionComponent
    with HasGameRef<RunnerGame>, CollisionCallbacks {
  final int ammoAmount;
  double floatOffset = 0;
  double rotationSpeed = 1.0;
  double floatSpeed = 1.5;
  double lifeTime = 0; // Yaşam süresi
  double maxLifeTime = 10.0; // Maksimum yaşam süresi (10 saniye)
  bool isCollected = false;
  bool isFadingOut = false;
  double fadeOutTimer = 0.5; // Toplayınca 0.5 saniye kaybolma animasyonu
  
  final Paint _paint = Paint()..color = Colors.orange;
  final Paint _borderPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  AmmoCollectibleComponent({
    required Vector2 position,
    required Vector2 size,
    this.ammoAmount = 10,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    // Çarpışma kutusu ekle
    add(RectangleHitbox());

    // Rastgele başlangıç değerleri
    floatOffset = math.Random().nextDouble() * math.pi * 2;
    rotationSpeed = 0.5 + math.Random().nextDouble() * 1.0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Oyun durmuşsa güncelleme yapma
    if (gameRef.isPaused || gameRef.isGameOver) return;

    // Toplandıysa animasyon yap ve yok et
    if (isCollected) {
      fadeOutTimer -= dt;
      scale = Vector2.all(fadeOutTimer * 2); // Kaybolurken küçül

      if (fadeOutTimer <= 0) {
        removeFromParent();
      }
      return;
    }

    // Yüzen hareket animasyonu
    lifeTime += dt;
    angle += rotationSpeed * dt; // Dönme animasyonu
    position.y += math.sin(floatOffset + lifeTime * floatSpeed) * 0.5; // Yüzme animasyonu

    // Maksimum yaşam süresi dolduğunda yok et
    if (lifeTime >= maxLifeTime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Mermi kutusu çiz
    canvas.save();
    
    // Kutu gövdesi
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _paint,
    );
    
    // Kutu kenarları
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _borderPaint,
    );
    
    // Mermi simgesi
    final bulletPaint = Paint()..color = Colors.yellow;
    final bulletBorderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Üst taraftaki mermiler
    for (int i = 0; i < 3; i++) {
      final bulletX = size.x * 0.25 + (i * size.x * 0.25);
      final bulletY = size.y * 0.3;
      final bulletWidth = size.x * 0.15;
      final bulletHeight = size.y * 0.3;
      
      canvas.drawRect(
        Rect.fromLTWH(bulletX, bulletY, bulletWidth, bulletHeight),
        bulletPaint,
      );
      
      canvas.drawRect(
        Rect.fromLTWH(bulletX, bulletY, bulletWidth, bulletHeight),
        bulletBorderPaint,
      );
    }
    
    canvas.restore();
  }

  void collect() {
    if (!isCollected) {
      isCollected = true;
      
      // Parçacık efekti oluştur
      if (gameRef.particleSystem != null) {
        gameRef.particleSystem!.createExplosion(
          position: position,
          color: Colors.yellow,
          count: 20,
        );
      }
      
      // Ses efekti
     // gameRef.audioService.playSfx(SoundEffect.collect);
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is HumanPlayerComponent && !isCollected) {
      // Mermi ekle
      gameRef.addAmmo(ammoAmount);
      
      // Toplandı olarak işaretle
      collect();
    }
  }
}
