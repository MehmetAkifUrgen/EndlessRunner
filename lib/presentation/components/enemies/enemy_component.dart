import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../domain/entities/enemy.dart';
import '../../pages/game_screen.dart';
import '../particles/particle_system.dart';

class EnemyComponent extends PositionComponent
    with HasGameRef<RunnerGame>, CollisionCallbacks {
  final Enemy enemy;
  int health;
  bool isJumping = false;
  double jumpVelocity = 0;
  double gravity = 900;
  double initialY = 0;
  double jumpHeight = 100;
  bool isHit = false;
  double hitAnimationTimer = 0;
  double movementSineOffset = 0;
  final double movementAmplitude = 30;

  EnemyComponent({
    required this.enemy,
    required Vector2 position,
    required Vector2 size,
  })  : health = enemy.health,
        super(
          position: position,
          size: size,
          anchor: Anchor.bottomCenter,
        );

  @override
  Future<void> onLoad() async {
    // Başlangıç Y pozisyonunu kaydet
    initialY = position.y;

    // Çarpışma kutusu ekle
    add(RectangleHitbox());

    // Eğer düşman uçan tipteyse, başlangıçta biraz yukarıda olsun
    if (enemy.canFly) {
      position.y -= math.Random().nextDouble() * 100 + 50;
      // Sine hareketi için rastgele başlangıç değeri
      movementSineOffset = math.Random().nextDouble() * math.pi * 2;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Oyun durmuşsa güncelleme yapma
    if (gameRef.isPaused || gameRef.isGameOver) return;

    // Oyun hızına göre düşmanı hareket ettir
    position.x -= gameRef.gameSpeed * enemy.speed * dt;

    // Eğer ekranın solundan çıktıysa kaldır
    if (position.x < -size.x) {
      removeFromParent();
      return;
    }

    // Vurulma animasyonu
    if (isHit) {
      hitAnimationTimer -= dt;
      if (hitAnimationTimer <= 0) {
        isHit = false;
      }
    }

    // Düşman tipine göre davranışlar
    if (enemy.canJump && !isJumping) {
      // Belirli aralıklarla zıplama işlemi
      if (math.Random().nextDouble() < 0.01) {
        jump();
      }
    }

    // Zıplama ise güncelleme
    if (isJumping) {
      jumpVelocity += gravity * dt;
      position.y += jumpVelocity * dt;

      // Yere değdiyse zıplama biter
      if (position.y >= initialY) {
        position.y = initialY;
        isJumping = false;
      }
    }

    // Uçan düşmanlar için sine hareketi
    if (enemy.canFly) {
      movementSineOffset += dt;
      position.y = initialY -
          jumpHeight -
          math.sin(movementSineOffset) * movementAmplitude;
    }
  }

  void jump() {
    if (!isJumping) {
      isJumping = true;
      jumpVelocity = -500; // Yukarı yönlü hız
    }
  }

  // Hasar alma metodu
  bool takeDamage(double damage) {
    health -= damage.ceil(); // int değere çevirdik
    isHit = true;
    hitAnimationTimer = 0.2;

    // Darbe efekti oluştur
    if (gameRef.particleSystem != null) {
      final particleColors = [
        Colors.red.shade300,
        Colors.red.shade600,
        Colors.red.shade900,
      ];

      gameRef.particleSystem.createParticles(
        count: 5, // Performans için 10'dan 5'e düşürüldü
        position: Vector2(position.x, position.y - size.y / 2),
        particleSize: Vector2(3, 3), // Performans için boyutu küçülttük
        colors: particleColors,
        speed: 80,
        gravity: 300,
        lifespan: 0.3, // Performans için kısalttık
      );
    }

    // Eğer düşman öldüyse
    if (health <= 0) {
      die();
      return true; // Öldürüldü
    }

    return false; // Hala hayatta
  }

  // Hasar alma ve çarpışma için kullanılan hit metodu
  bool hit(double damage) {
    return takeDamage(damage);
  }

  void die() {
    // Öldüğünde puanı artır
    gameRef.score += enemy.pointValue;

    // Öldüğünde parçacık efekti
    if (gameRef.particleSystem != null) {
      final particleColors = [
        Colors.red.shade400,
        Colors.orange.shade700,
        Colors.yellow.shade600,
      ];

      gameRef.particleSystem.createParticles(
        count: 30,
        position: Vector2(position.x, position.y - size.y / 2),
        particleSize: Vector2(8, 8),
        colors: particleColors,
        speed: 200,
        gravity: 300,
        lifespan: 1.0,
        rotationSpeed: 5.0,
      );
    }

    // Mermi düşürme şansı
    if (math.Random().nextInt(100) < enemy.ammoDropChance) {
      gameRef.spawnAmmoDrop(position.clone());
    }

    // Düşmanı yok et
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final enemyType = enemy.type;

    canvas.save();

    switch (enemyType) {
      case EnemyType.zombie:
        _drawZombie(canvas);
        break;
      case EnemyType.robot:
        _drawRobot(canvas);
        break;
      case EnemyType.monster:
        _drawMonster(canvas);
        break;
      default:
        _drawBasicEnemy(canvas);
    }

    // Vurulma efekti
    if (isHit) {
      final hitPaint = Paint()..color = Colors.red.withOpacity(0.5);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        hitPaint,
      );
    }

    // Can barı - düşman hasar aldığında veya isHit aktif olduğunda göster
    if (isHit || health < enemy.health) {
      // Can barının arkaplanı (gri)
      final backgroundPaint = Paint()
        ..color = Colors.grey.shade800
        ..style = PaintingStyle.fill;

      // Can barı için dikdörtgen (arkaplan)
      final barWidth = size.x * 1.2;
      final barHeight = size.y * 0.1;
      final barLeft = -size.x * 0.1; // Düşmanı ortalar
      final barTop = -size.y * 0.2; // Düşmanın üstünde gösterir

      final backgroundRect =
          Rect.fromLTWH(barLeft, barTop, barWidth, barHeight);
      canvas.drawRRect(
          RRect.fromRectAndCorners(
            backgroundRect,
            topLeft: Radius.circular(barHeight / 2),
            topRight: Radius.circular(barHeight / 2),
            bottomLeft: Radius.circular(barHeight / 2),
            bottomRight: Radius.circular(barHeight / 2),
          ),
          backgroundPaint);

      // Can barının kendisi (yeşilden kırmızıya doğru renk değişimi)
      final healthRatio = health / enemy.health;
      final currentBarWidth = barWidth * healthRatio;

      // Sağlık durumuna göre renk değişimi (yeşil -> sarı -> kırmızı)
      Color healthColor;
      if (healthRatio > 0.6) {
        healthColor = Colors.green;
      } else if (healthRatio > 0.3) {
        healthColor = Colors.yellow;
      } else {
        healthColor = Colors.red;
      }

      final healthPaint = Paint()
        ..color = healthColor
        ..style = PaintingStyle.fill;

      // Can barı çizimi
      final healthRect =
          Rect.fromLTWH(barLeft, barTop, currentBarWidth, barHeight);
      canvas.drawRRect(
          RRect.fromRectAndCorners(
            healthRect,
            topLeft: Radius.circular(barHeight / 2),
            topRight: Radius.circular(barHeight / 2),
            bottomLeft: Radius.circular(barHeight / 2),
            bottomRight: Radius.circular(barHeight / 2),
          ),
          healthPaint);

      // Kalan can değerini metin olarak gösterme
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$health/${enemy.health}',
          style: TextStyle(
            color: Colors.white,
            fontSize: barHeight * 0.7,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(barLeft + (barWidth - textPainter.width) / 2,
              barTop + (barHeight - textPainter.height) / 2));
    }

    canvas.restore();
  }

  // Zombi çizimi
  void _drawZombie(Canvas canvas) {
    // Ana gövde - yeşilimsi renk
    final bodyPaint = Paint()..color = Colors.green.shade800;
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.3, size.y * 0.3, size.x * 0.4, size.y * 0.4),
      bodyPaint,
    );

    // Kafa - daha yeşil
    final headPaint = Paint()..color = Colors.green.shade600;
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.2),
      size.x * 0.15,
      headPaint,
    );

    // Korkunç kırmızı gözler
    final eyePaint = Paint()..color = Colors.red;
    canvas.drawCircle(
      Offset(size.x * 0.45, size.y * 0.18),
      size.x * 0.04,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(size.x * 0.55, size.y * 0.18),
      size.x * 0.04,
      eyePaint,
    );

    // Zombi ağzı - düzensiz bir çizgi
    final mouthPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final mouthPath = Path();
    mouthPath.moveTo(size.x * 0.4, size.y * 0.25);
    mouthPath.lineTo(size.x * 0.45, size.y * 0.28);
    mouthPath.lineTo(size.x * 0.5, size.y * 0.25);
    mouthPath.lineTo(size.x * 0.55, size.y * 0.28);
    mouthPath.lineTo(size.x * 0.6, size.y * 0.25);
    canvas.drawPath(mouthPath, mouthPaint);

    // Kollar ve bacaklar - yeşilimsi
    final limbPaint = Paint()..color = Colors.green.shade700;

    // Sol kol - ileri uzanan pençe
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.1, size.y * 0.3, size.x * 0.2, size.y * 0.1),
      limbPaint,
    );

    // Sağ kol
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.7, size.y * 0.3, size.x * 0.2, size.y * 0.1),
      limbPaint,
    );

    // Bacaklar
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.35, size.y * 0.7, size.x * 0.1, size.y * 0.3),
      limbPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.55, size.y * 0.7, size.x * 0.1, size.y * 0.3),
      limbPaint,
    );
  }

  // Robot çizimi
  void _drawRobot(Canvas canvas) {
    // Gövde - metalik gri
    final bodyPaint = Paint()..color = Colors.blueGrey.shade700;
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.3, size.y * 0.3, size.x * 0.4, size.y * 0.4),
      bodyPaint,
    );

    // Kafa - kare kafa
    final headPaint = Paint()..color = Colors.blueGrey.shade600;
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.35, size.y * 0.1, size.x * 0.3, size.x * 0.25),
      headPaint,
    );

    // Anten
    final antenPaint = Paint()..color = Colors.grey.shade800;
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.48, size.y * 0.05, size.x * 0.04, size.y * 0.05),
      antenPaint,
    );
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.04),
      size.x * 0.02,
      Paint()..color = Colors.red,
    );

    // Gözler - elektronik göz
    final eyePaint = Paint()..color = Colors.blue;
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.38, size.y * 0.15, size.x * 0.08, size.y * 0.04),
      eyePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.54, size.y * 0.15, size.x * 0.08, size.y * 0.04),
      eyePaint,
    );

    // Ağız - düz çizgi
    final mouthPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.x * 0.4, size.y * 0.25),
      Offset(size.x * 0.6, size.y * 0.25),
      mouthPaint,
    );

    // Metal parçaları - gövde üzerinde
    final panelPaint = Paint()..color = Colors.blueGrey.shade500;
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.35, size.y * 0.35, size.x * 0.3, size.y * 0.1),
      panelPaint,
    );

    // Düğmeler/kontrol paneli
    final buttonPaint = Paint()..color = Colors.red;
    canvas.drawCircle(
      Offset(size.x * 0.4, size.y * 0.4),
      size.x * 0.02,
      buttonPaint,
    );
    buttonPaint.color = Colors.yellow;
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.4),
      size.x * 0.02,
      buttonPaint,
    );
    buttonPaint.color = Colors.green;
    canvas.drawCircle(
      Offset(size.x * 0.6, size.y * 0.4),
      size.x * 0.02,
      buttonPaint,
    );

    // Robot kollar
    final limbPaint = Paint()..color = Colors.blueGrey.shade800;

    // Sol kol
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.2, size.y * 0.35, size.x * 0.1, size.y * 0.25),
      limbPaint,
    );

    // Robot pençe - sol
    final clawPaint = Paint()..color = Colors.blueGrey.shade900;
    canvas.drawCircle(
      Offset(size.x * 0.25, size.y * 0.65),
      size.x * 0.08,
      clawPaint,
    );

    // Sağ kol
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.7, size.y * 0.35, size.x * 0.1, size.y * 0.25),
      limbPaint,
    );

    // Robot pençe - sağ
    canvas.drawCircle(
      Offset(size.x * 0.75, size.y * 0.65),
      size.x * 0.08,
      clawPaint,
    );

    // Bacaklar
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.35, size.y * 0.7, size.x * 0.1, size.y * 0.3),
      limbPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.55, size.y * 0.7, size.x * 0.1, size.y * 0.3),
      limbPaint,
    );
  }

  // Canavar çizimi
  void _drawMonster(Canvas canvas) {
    // Vücut - mor/koyu mor
    final bodyPaint = Paint()..color = Colors.deepPurple;
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.25, size.y * 0.3, size.x * 0.5, size.y * 0.5),
      bodyPaint,
    );

    // Baş - büyük baş
    final headPaint = Paint()..color = Colors.purple;
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.2),
      size.x * 0.25,
      headPaint,
    );

    // Gözler - üç göz
    final eyePaint = Paint()..color = Colors.yellow;
    canvas.drawCircle(
      Offset(size.x * 0.4, size.y * 0.15),
      size.x * 0.06,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(size.x * 0.6, size.y * 0.15),
      size.x * 0.06,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.25),
      size.x * 0.04,
      eyePaint,
    );

    // Pupiller
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(
      Offset(size.x * 0.4, size.y * 0.15),
      size.x * 0.03,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(size.x * 0.6, size.y * 0.15),
      size.x * 0.03,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.25),
      size.x * 0.02,
      pupilPaint,
    );

    // Ağız - keskin dişli
    final mouthPaint = Paint()..color = Colors.red.shade900;
    final mouthPath = Path();
    mouthPath.moveTo(size.x * 0.35, size.y * 0.3);
    mouthPath.lineTo(size.x * 0.4, size.y * 0.35);
    mouthPath.lineTo(size.x * 0.45, size.y * 0.3);
    mouthPath.lineTo(size.x * 0.5, size.y * 0.35);
    mouthPath.lineTo(size.x * 0.55, size.y * 0.3);
    mouthPath.lineTo(size.x * 0.6, size.y * 0.35);
    mouthPath.lineTo(size.x * 0.65, size.y * 0.3);
    canvas.drawPath(mouthPath, mouthPaint);

    // Dişler
    final teethPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 3; i++) {
      final x = size.x * (0.4 + i * 0.1);
      final toothPath = Path();
      toothPath.moveTo(x, size.y * 0.35);
      toothPath.lineTo(x - size.x * 0.02, size.y * 0.38);
      toothPath.lineTo(x + size.x * 0.02, size.y * 0.38);
      toothPath.close();
      canvas.drawPath(toothPath, teethPaint);
    }

    // Tentaküller
    final tentaclePaint = Paint()..color = Colors.deepPurple.shade800;

    // Alt tentaküller
    for (int i = 0; i < 4; i++) {
      final startX = size.x * (0.3 + i * 0.13);
      final tentaclePath = Path();
      tentaclePath.moveTo(startX, size.y * 0.7);
      tentaclePath.cubicTo(startX - size.x * 0.1, size.y * 0.8,
          startX + size.x * 0.1, size.y * 0.9, startX, size.y * 1.0);

      final tentacleStroke = Paint()
        ..color = Colors.deepPurple.shade800
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      canvas.drawPath(tentaclePath, tentacleStroke);
    }

    // Yan tentaküller
    final leftTentacle = Path();
    leftTentacle.moveTo(size.x * 0.25, size.y * 0.5);
    leftTentacle.quadraticBezierTo(
        size.x * 0.05, size.y * 0.5, size.x * 0.1, size.y * 0.3);

    final rightTentacle = Path();
    rightTentacle.moveTo(size.x * 0.75, size.y * 0.5);
    rightTentacle.quadraticBezierTo(
        size.x * 0.95, size.y * 0.5, size.x * 0.9, size.y * 0.3);

    canvas.drawPath(
        leftTentacle,
        Paint()
          ..color = Colors.deepPurple.shade800
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);

    canvas.drawPath(
        rightTentacle,
        Paint()
          ..color = Colors.deepPurple.shade800
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);
  }

  // Temel düşman çizimi (varsayılan tür için)
  void _drawBasicEnemy(Canvas canvas) {
    // Basit bir şekil
    final paint = Paint()..color = Colors.red.shade700;

    // Gövde
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.3, size.y * 0.3, size.x * 0.4, size.y * 0.4),
      paint,
    );

    // Kafa
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.2),
      size.x * 0.2,
      paint,
    );

    // Gözler
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.x * 0.4, size.y * 0.2),
      size.x * 0.05,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(size.x * 0.6, size.y * 0.2),
      size.x * 0.05,
      eyePaint,
    );

    // Siyah gözbebekleri
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(
      Offset(size.x * 0.4, size.y * 0.2),
      size.x * 0.02,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(size.x * 0.6, size.y * 0.2),
      size.x * 0.02,
      pupilPaint,
    );

    // Kırmızı kollar ve bacaklar
    final limbPaint = Paint()..color = Colors.red.shade900;

    // Kollar
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.2, size.y * 0.35, size.x * 0.1, size.y * 0.2),
      limbPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.7, size.y * 0.35, size.x * 0.1, size.y * 0.2),
      limbPaint,
    );

    // Bacaklar
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.35, size.y * 0.7, size.x * 0.1, size.y * 0.3),
      limbPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.55, size.y * 0.7, size.x * 0.1, size.y * 0.3),
      limbPaint,
    );
  }
}
