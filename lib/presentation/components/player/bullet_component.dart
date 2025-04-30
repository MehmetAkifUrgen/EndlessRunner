import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../domain/entities/weapon.dart';
import '../../pages/game_screen.dart';
import '../enemies/enemy_component.dart';
import '../particles/particle_system.dart';

class BulletComponent extends PositionComponent
    with HasGameRef<RunnerGame>, CollisionCallbacks {
  final Bullet bullet;
  final Vector2 direction;
  bool isActive = true;
  double travelDistance = 0; // Toplam katedilen mesafe
  final double maxDistance; // Maksimum menzil

  BulletComponent({
    required this.bullet,
    required Vector2 position,
    required this.direction,
    this.maxDistance = 1000,
  }) : super(
          position: position,
          size: Vector2(bullet.size, bullet.size),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    // Çarpışma kutusu ekle
    add(RectangleHitbox()..collisionType = CollisionType.active);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Oyun durmuşsa güncelleme yapma
    if (gameRef.isPaused || gameRef.isGameOver) return;

    // Mermiyi hareket ettir
    final distance = bullet.speed * dt;
    position.x += direction.x * distance;
    position.y += direction.y * distance;

    // Toplam mesafeyi güncelle
    travelDistance += distance;

    // Eğer maksimum mesafeyi aştıysa veya ekrandan çıktıysa
    if (travelDistance > maxDistance ||
        position.x > gameRef.size.x + 50 ||
        position.x < -50 ||
        position.y > gameRef.size.y + 50 ||
        position.y < -50) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Mermiyi çiz
    final paint = Paint()..color = bullet.color;

    // Mermi tipine göre çizim
    if (bullet.isPenetrating) {
      // Lazer tarzı uzun mermi
      final endX = bullet.size * 3;
      final glowPaint = Paint()
        ..color = bullet.color.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      // Işıklı gölge efekti
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bullet.size / 2, bullet.size / 2),
          width: bullet.size * 3,
          height: bullet.size,
        ),
        glowPaint,
      );

      // Ana mermi
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bullet.size / 2, bullet.size / 2),
          width: bullet.size * 2.5,
          height: bullet.size * 0.8,
        ),
        paint,
      );
    } else if (bullet.isExplosive) {
      // Patlayıcı mermi (turuncu-kırmızı renk geçişli)
      final gradientPaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.yellow, Colors.orange, Colors.red],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(bullet.size / 2, bullet.size / 2),
          radius: bullet.size / 2,
        ));

      canvas.drawCircle(
        Offset(bullet.size / 2, bullet.size / 2),
        bullet.size / 2,
        gradientPaint,
      );
    } else {
      // Standart mermi (yuvarlak)
      canvas.drawCircle(
        Offset(bullet.size / 2, bullet.size / 2),
        bullet.size / 2,
        paint,
      );
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Eğer mermi aktif değilse işlem yapma
    if (!isActive) return;

    // Düşmana çarptıysa
    if (other is EnemyComponent) {
      // Düşmana hasar ver
      final wasKilled = other.hit(bullet.damage);

      // Çarpışma efekti
      createHitEffect(intersectionPoints.first);

      // Eğer patlayıcı mermiyse ve düşman öldüyse çevresindeki düşmanlara da hasar ver
      if (bullet.isExplosive && wasKilled) {
        _createExplosion();
      }

      // Eğer mermi delici değilse, mermiyi yok et
      if (!bullet.isPenetrating) {
        isActive = false;
        removeFromParent();
      }
    }
  }

  void createHitEffect(Vector2 position) {
    // Çarpışma parçacık efekti
    final colors = [
      bullet.color,
      Colors.white,
      Colors.yellow.shade600,
    ];

    gameRef.particleSystem?.emit(
      count: 10,
      position: position,
      colors: colors,
      size: Vector2(3, 3),
      speed: 50,
      lifespan: 0.3,
    );
  }

  void _createExplosion() {
    // Patlama efekti
    final explosionColors = [
      Colors.yellow,
      Colors.orange,
      Colors.red,
      Colors.redAccent,
    ];

    gameRef.particleSystem?.emit(
      count: 30,
      position: position,
      colors: explosionColors,
      size: Vector2(8, 8),
      speed: 150,
      lifespan: 0.8,
      rotationSpeed: 5,
    );

    // Çevredeki düşmanlara hasar ver
    // Explosion radius kadar mesafedeki düşmanları bul
    for (final component in gameRef.children) {
      if (component is EnemyComponent) {
        final distance = position.distanceTo(component.position);
        if (distance <= bullet.explosionRadius) {
          // Mesafeye göre azalan hasar
          final distanceFactor = 1 - (distance / bullet.explosionRadius);
          final damage = bullet.damage * distanceFactor;
          component.hit(damage);
        }
      }
    }
  }
}
