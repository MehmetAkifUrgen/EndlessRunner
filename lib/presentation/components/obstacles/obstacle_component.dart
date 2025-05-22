import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/obstacle.dart'; // Entity importu
import '../../pages/game_screen.dart'; // RunnerGame importu
// import '../../../utils/extensions.dart'; // Gerek kalmadı

// Engel Bileşeni
class ObstacleComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<RunnerGame> {
  final ObstacleType type;
  final Color color; // final olarak geri döndü
  final RunnerGame game;
  late final Paint _paint;
  late final Paint _shadowPaint;
  late final Paint _strokePaint;
  late final Paint _detailPaint;

  bool isActive = true;
  double _animTime = 0;
  Vector2 velocity = Vector2.zero();

  static final Map<ObstacleType, Vector2> _typeToSize = {
    ObstacleType.cube: Vector2(40, 40),
    ObstacleType.wall: Vector2(60, 80), // Biraz daha geniş duvar
    ObstacleType.ramp: Vector2(60, 50),
    ObstacleType.hole: Vector2(60, 20),
  };

  ObstacleComponent({
    required Vector2 position,
    required this.type,
    required this.color,
    required this.game,
  }) : super(position: position, anchor: Anchor.bottomLeft) {
    anchor = Anchor.bottomCenter;

    // Engel türüne göre boyut ayarla
    size = _getSizeForType(type);

    // Ana renk
    _paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Gölge efekti
    _shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Kenar çizgisi
    _strokePaint = Paint()
      ..color = color.darken(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Detay çizgisi
    _detailPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Çarpışma tespiti için hitbox ekle
    add(RectangleHitbox(
      position: Vector2(0, -size.y),
      size: size,
      isSolid: true,
    ));
  }

  Vector2 _getSizeForType(ObstacleType type) {
    return _typeToSize[type] ?? Vector2(40, 40);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;

    if (isActive) {
      // Sola doğru hareket
      position.x -= game.gameSpeed * dt;

      // Ekran dışına çıktıysa kaldır
      if (position.x < -size.x * 2) {
        removeFromParent();
        game.obstacles.remove(this);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    switch (type) {
      case ObstacleType.cube:
        _renderCube(canvas);
        break;
      case ObstacleType.wall:
        _renderWall(canvas);
        break;
      case ObstacleType.ramp:
        _renderRamp(canvas);
        break;
      case ObstacleType.hole:
        _renderHole(canvas);
        break;
      case ObstacleType.spikes:
        _renderSpikes(canvas);
        break;
      case ObstacleType.laserGrid:
        _renderLaserGrid(canvas);
        break;
      case ObstacleType.fireWall:
        _renderFireWall(canvas);
        break;
      case ObstacleType.electricField:
        _renderElectricField(canvas);
        break;
      case ObstacleType.movingBlade:
        _renderMovingBlade(canvas);
        break;
      case ObstacleType.drone:
        _renderDrone(canvas);
        break;
    }
  }

  void _renderCube(Canvas canvas) {
    // Hafif bir sallanma efekti - değeri sınırla
    final wiggle = math.sin(_animTime * 4) * math.min(2.0, size.x * 0.05);

    // Gölge
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(5, -size.y + 5, size.x, size.y),
        const Radius.circular(5),
      ),
      _shadowPaint,
    );

    // Küp ana gövdesi
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(wiggle, -size.y, size.x, size.y),
        const Radius.circular(5),
      ),
      _paint,
    );

    // Küp kenarları
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(wiggle, -size.y, size.x, size.y),
        const Radius.circular(5),
      ),
      _strokePaint,
    );

    // Küp üzerine detay çizgileri - önceden tanımlanmış _detailPaint kullan
    // Yatay çizgi
    canvas.drawLine(
      Offset(wiggle + 10, -size.y + size.y / 2),
      Offset(wiggle + size.x - 10, -size.y + size.y / 2),
      _detailPaint,
    );

    // Dikey çizgi
    canvas.drawLine(
      Offset(wiggle + size.x / 2, -size.y + 10),
      Offset(wiggle + size.x / 2, -size.y + size.y - 10),
      _detailPaint,
    );
  }

  void _renderWall(Canvas canvas) {
    // Duvar gölgesi
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(5, -size.y + 5, size.x, size.y),
        const Radius.circular(5),
      ),
      _shadowPaint,
    );

    // Duvar ana gövdesi
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -size.y, size.x, size.y),
        const Radius.circular(5),
      ),
      _paint,
    );

    // Duvar kenarları
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -size.y, size.x, size.y),
        const Radius.circular(5),
      ),
      _strokePaint,
    );

    // Duvar üzerine tuğla deseni - _detailPaint renk ayarı
    _detailPaint.color = color.darken(0.1);

    const brickRows = 6;
    const brickCols = 2;
    const offsetRows = [0, 0.5]; // Her satırın offset'i

    for (int row = 0; row < brickRows; row++) {
      final offsetX = offsetRows[row % offsetRows.length];

      for (int col = 0; col < brickCols + offsetX; col++) {
        final brickWidth = size.x / brickCols;
        final brickHeight = size.y / brickRows;
        final left = col * brickWidth - (offsetX * brickWidth / 2);
        final top = -size.y + row * brickHeight;

        if (left + brickWidth > 0 && left < size.x) {
          canvas.drawRect(
            Rect.fromLTWH(left, top, brickWidth, brickHeight),
            _detailPaint,
          );
        }
      }
    }

    // Rengi sıfırla
    _detailPaint.color = Colors.white.withOpacity(0.3);
  }

  void _renderRamp(Canvas canvas) {
    // Rampa gölgesi
    final shadowPath = Path()
      ..moveTo(5, 0)
      ..lineTo(size.x + 5, 0)
      ..lineTo(size.x + 5, -size.y + 5)
      ..lineTo(5, 0)
      ..close();

    canvas.drawPath(shadowPath, _shadowPaint);

    // Rampa ana gövdesi
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.x, 0)
      ..lineTo(size.x, -size.y)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, _paint);

    // Rampa kenarları
    canvas.drawPath(path, _strokePaint);

    // Rampa üzerine çizgiler - önceden tanımlanmış _detailPaint kullan
    for (int i = 1; i < 5; i++) {
      final x = i * size.x / 5;
      final y = -size.y * (x / size.x);

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, y),
        _detailPaint,
      );
    }
  }

  void _renderHole(Canvas canvas) {
    // Çukur (siyah bir oval)
    final holePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Derinlik efekti için gradyan
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black,
          Colors.black.withOpacity(0.7),
        ],
        stops: const [0.7, 1.0],
      ).createShader(
        Rect.fromLTWH(-size.x / 2, -size.y, size.x * 2, size.y * 2),
      );

    // Gölge
    canvas.drawOval(
      Rect.fromLTWH(0, -size.y, size.x, size.y * 2),
      Paint()..color = Colors.black.withOpacity(0.2),
    );

    // Çukurun kendisi
    canvas.drawOval(
      Rect.fromLTWH(0, -size.y, size.x, size.y * 2),
      gradientPaint,
    );

    // Çukur kenarında toprak efekti
    final dirtPaint = Paint()
      ..color = Colors.brown.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawOval(
      Rect.fromLTWH(0, -size.y, size.x, size.y * 2),
      dirtPaint,
    );

    // Kenar detayları
    final detailPath = Path();

    for (int i = 0; i < 10; i++) {
      final angle = i * (math.pi / 5);
      final radius = size.x / 2;
      final x = radius + math.cos(angle) * radius * 0.9;
      final y = -size.y + size.y + math.sin(angle) * radius * 0.9;

      detailPath.moveTo(x, y);
      detailPath.lineTo(x + math.cos(angle) * 3, y + math.sin(angle) * 3);
    }

    canvas.drawPath(
      detailPath,
      Paint()
        ..color = Colors.brown.shade800
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _renderSpikes(Canvas canvas) {
    // Gölge
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(5, -size.y + 5, size.x, size.y),
        const Radius.circular(2),
      ),
      _shadowPaint,
    );

    // Temel platform
    final basePaint = Paint()..color = Colors.grey.shade800;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -size.y * 0.5, size.x, size.y * 0.5),
        const Radius.circular(2),
      ),
      basePaint,
    );

    // Dikenleri çiz
    final spikePaint = Paint()..color = Colors.red.shade800;
    final spikeCount = 6;
    final spikeWidth = size.x / spikeCount;

    for (int i = 0; i < spikeCount; i++) {
      final spikeHeight = size.y * 0.7 + math.sin(_animTime * 2 + i) * 5;
      final spikePath = Path()
        ..moveTo(i * spikeWidth, -size.y * 0.5)
        ..lineTo((i + 0.5) * spikeWidth, -size.y - spikeHeight * 0.2)
        ..lineTo((i + 1) * spikeWidth, -size.y * 0.5)
        ..close();

      canvas.drawPath(spikePath, spikePaint);
    }

    // Kenar çizgileri
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -size.y * 0.5, size.x, size.y * 0.5),
        const Radius.circular(2),
      ),
      _strokePaint,
    );
  }

  void _renderLaserGrid(Canvas canvas) {
    // Gölge
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(5, -size.y + 5, size.x, size.y),
        const Radius.circular(5),
      ),
      _shadowPaint,
    );

    // Lazer cihazları (üst ve alt)
    final devicePaint = Paint()..color = Colors.grey.shade800;

    // Üst cihaz - y pozisyonunu 0'a ayarla
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -size.y, size.x, size.y * 0.15),
        const Radius.circular(3),
      ),
      devicePaint,
    );

    // Alt cihaz - y pozisyonunu 0'a ayarla
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -size.y * 0.15, size.x, size.y * 0.15),
        const Radius.circular(3),
      ),
      devicePaint,
    );

    // Lazer ışınları
    final pulseEffect = math.sin(_animTime * 8).abs() * 0.5 + 0.5;
    final laserPaint = Paint()
      ..color = Colors.red.withOpacity(0.7 * pulseEffect)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Lazer ışık efekti
    final glowPaint = Paint()
      ..color = Colors.red.withOpacity(0.3 * pulseEffect)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * pulseEffect);

    const laserCount = 5;
    final laserGap = size.x / (laserCount + 1);

    for (int i = 1; i <= laserCount; i++) {
      final x = i * laserGap;

      // Önce ışık efekti
      canvas.drawLine(
        Offset(x, -size.y),
        Offset(x, -size.y * 0.15),
        glowPaint,
      );

      // Sonra ana lazer
      canvas.drawLine(
        Offset(x, -size.y),
        Offset(x, -size.y * 0.15),
        laserPaint,
      );
    }

    // Cihaz detayları
    final detailPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (int i = 1; i <= laserCount; i++) {
      final x = i * laserGap;
      // Üst ışık
      canvas.drawCircle(
        Offset(x, -size.y + size.y * 0.075),
        size.x * 0.03,
        detailPaint,
      );
      // Alt ışık
      canvas.drawCircle(
        Offset(x, -size.y * 0.075),
        size.x * 0.03,
        detailPaint,
      );
    }
  }

  void _renderFireWall(Canvas canvas) {
    // Ateş duvarı temeli
    final basePaint = Paint()..color = Colors.brown.shade900;
    canvas.drawRect(
      Rect.fromLTWH(0, -size.y * 0.1, size.x, size.y * 0.1),
      basePaint,
    );

    // Ateş efekti
    final fireCount = (size.x / 15).ceil();

    for (int i = 0; i < fireCount; i++) {
      final offset = 2.0 * math.sin(_animTime * 3 + i);
      final fireHeight = size.y * 0.8 + math.sin(_animTime * 5 + i * 2) * 10;

      // Alev yolu
      final firePath = Path();
      firePath.moveTo(i * size.x / fireCount, -size.y * 0.1);

      // Alev dalgaları
      for (int j = 1; j < 8; j++) {
        final waveX = i * size.x / fireCount +
            size.x / (fireCount * 2) +
            math.sin(_animTime * 4 + j + i) * 5;
        final waveY = -size.y * 0.1 -
            j * fireHeight / 8 +
            math.sin(_animTime * 3 + j * 2 + i) * 3;

        firePath.quadraticBezierTo(
            waveX, waveY - 5, (i + 0.5) * size.x / fireCount, waveY);
      }

      // Aleve devam et
      firePath.quadraticBezierTo((i + 0.5) * size.x / fireCount + 3,
          -size.y - fireHeight, (i + 1) * size.x / fireCount, -size.y * 0.1);

      firePath.close();

      // Alev renk gradyanı
      final gradient = RadialGradient(
        center: Alignment(0.0, 0.5),
        radius: 1.0,
        colors: [
          Colors.yellow,
          Colors.orange,
          Colors.red.shade900,
        ],
        stops: const [0.1, 0.5, 0.9],
      ).createShader(
        Rect.fromLTWH(i * size.x / fireCount, -size.y - fireHeight,
            size.x / fireCount, size.y + fireHeight),
      );

      final firePaint = Paint()
        ..shader = gradient
        ..style = PaintingStyle.fill;

      canvas.drawPath(firePath, firePaint);
    }

    // Ateş ışık efekti
    final glowPaint = Paint()
      ..color = Colors.orange.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawRect(
      Rect.fromLTWH(0, -size.y, size.x, size.y),
      glowPaint,
    );
  }

  void _renderElectricField(Canvas canvas) {
    // Ana elektrik alanı
    final fieldPaint = Paint()
      ..color = Colors.blue.shade800.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -size.y, size.x, size.y),
        const Radius.circular(10),
      ),
      fieldPaint,
    );

    // Elektrik efekti
    final pulseEffect = math.sin(_animTime * 10).abs() * 0.5 + 0.5;
    final electricPaint = Paint()
      ..color = Colors.lightBlue.shade100.withOpacity(0.8 * pulseEffect)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Rastgele elektrik yolları
    final rng = math.Random(_animTime.floor() * 10);
    final pathCount = 5 + (pulseEffect * 5).floor();

    for (int i = 0; i < pathCount; i++) {
      final electricPath = Path();
      final startX = rng.nextDouble() * size.x;
      electricPath.moveTo(startX, -size.y);

      var currentX = startX;
      var currentY = -size.y;

      while (currentY < 0) {
        final nextX = currentX + (rng.nextDouble() - 0.5) * 30;
        final nextY = currentY + rng.nextDouble() * 20;

        electricPath.lineTo(
          nextX.clamp(0, size.x),
          nextY.clamp(-size.y, 0),
        );

        currentX = nextX.clamp(0, size.x);
        currentY = nextY;
      }

      canvas.drawPath(electricPath, electricPaint);
    }

    // Kenar parlaması
    final glowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2 + 0.2 * pulseEffect)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * pulseEffect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, -size.y + 2, size.x - 4, size.y - 4),
        const Radius.circular(8),
      ),
      glowPaint,
    );

    // Elektrik jeneratör cihazı
    final devicePaint = Paint()..color = Colors.grey.shade800;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.4, -size.y * 0.1, size.x * 0.2, size.y * 0.1),
        const Radius.circular(3),
      ),
      devicePaint,
    );

    // Işık göstergesi
    final lightPaint = Paint()..color = Colors.blue.withOpacity(pulseEffect);
    canvas.drawCircle(
      Offset(size.x * 0.5, -size.y * 0.05),
      size.x * 0.03,
      lightPaint,
    );
  }

  void _renderMovingBlade(Canvas canvas) {
    // Dönme animasyonu
    final rotationAngle = _animTime * 10;

    canvas.save();
    // Merkeze taşı, döndür, sonra pozisyona geri getir
    canvas.translate(size.x / 2, -size.y / 2);
    canvas.rotate(rotationAngle);
    canvas.translate(-size.x / 2, size.y / 2);

    // Bıçak gölgesi
    final shadowPath = Path()
      ..addOval(Rect.fromLTWH(5, -size.y + 5, size.x, size.y));
    canvas.drawPath(shadowPath, _shadowPaint);

    // Bıçak merkezi
    final centerPaint = Paint()..color = Colors.grey.shade800;
    canvas.drawCircle(
      Offset(size.x / 2, -size.y / 2),
      size.x * 0.15,
      centerPaint,
    );

    // Bıçak kanatları - keskin ve tehlikeli
    final bladePaint = Paint()..color = Colors.grey.shade400;
    final bladeEdgePaint = Paint()..color = Colors.grey.shade200;

    for (int i = 0; i < 4; i++) {
      final bladeAngle = math.pi / 2 * i;
      final bladePath = Path();

      bladePath.moveTo(size.x / 2, -size.y / 2);
      bladePath.lineTo(
        size.x / 2 + math.cos(bladeAngle) * size.x * 0.4,
        -size.y / 2 + math.sin(bladeAngle) * size.y * 0.4,
      );
      bladePath.lineTo(
        size.x / 2 + math.cos(bladeAngle + 0.4) * size.x * 0.35,
        -size.y / 2 + math.sin(bladeAngle + 0.4) * size.y * 0.35,
      );
      bladePath.close();

      canvas.drawPath(bladePath, bladePaint);

      // Keskin kenarlar
      canvas.drawLine(
        Offset(
          size.x / 2 + math.cos(bladeAngle) * size.x * 0.1,
          -size.y / 2 + math.sin(bladeAngle) * size.y * 0.1,
        ),
        Offset(
          size.x / 2 + math.cos(bladeAngle) * size.x * 0.4,
          -size.y / 2 + math.sin(bladeAngle) * size.y * 0.4,
        ),
        bladeEdgePaint..strokeWidth = 2,
      );
    }

    // Merkez detayı - metal vida görünümü
    final centerDetailPaint = Paint()..color = Colors.grey.shade600;
    canvas.drawCircle(
      Offset(size.x / 2, -size.y / 2),
      size.x * 0.08,
      centerDetailPaint,
    );

    // Vida çizgisi
    canvas.drawLine(
      Offset(size.x / 2 - size.x * 0.06, -size.y / 2),
      Offset(size.x / 2 + size.x * 0.06, -size.y / 2),
      Paint()
        ..color = Colors.black
        ..strokeWidth = 2,
    );

    canvas.restore();
  }

  void _renderDrone(Canvas canvas) {
    // Drone havada süzülme hareketi
    final hoverOffset = math.sin(_animTime * 2) * 5;

    // Gölge - drone yükseldikçe küçülür
    final shadowScale = math.max(0.6, 1.0 - hoverOffset.abs() / 20);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, 0),
        width: size.x * 0.6 * shadowScale,
        height: size.y * 0.2 * shadowScale,
      ),
      _shadowPaint,
    );

    // Drone gövdesi - y pozisyonunu 0'a ayarla
    final bodyPaint = Paint()..color = Colors.grey.shade800;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.2, -size.y * 0.5, size.x * 0.6, size.y * 0.2),
        const Radius.circular(5),
      ),
      bodyPaint,
    );

    // Drone kanatları/pervaneler
    final wingPaint = Paint()..color = Colors.grey.shade600;

    // Sol pervane
    _renderDronePropeller(
      canvas,
      Offset(size.x * 0.25, -size.y * 0.5),
      _animTime * 20,
      wingPaint,
    );

    // Sağ pervane
    _renderDronePropeller(
      canvas,
      Offset(size.x * 0.75, -size.y * 0.5),
      _animTime * 20 + math.pi,
      wingPaint,
    );

    // Işıklar
    final lightPulse = math.sin(_animTime * 5).abs();
    final lightPaint = Paint()
      ..color = Colors.red.withOpacity(0.7 + lightPulse * 0.3);

    canvas.drawCircle(
      Offset(size.x * 0.3, -size.y * 0.45),
      size.x * 0.03,
      lightPaint,
    );

    canvas.drawCircle(
      Offset(size.x * 0.7, -size.y * 0.45),
      size.x * 0.03,
      lightPaint,
    );

    // Kamera lens
    final cameraPaint = Paint()..color = Colors.black;
    canvas.drawCircle(
      Offset(size.x * 0.5, -size.y * 0.4),
      size.x * 0.05,
      cameraPaint,
    );

    // Lens yansıması
    final lensPaint = Paint()..color = Colors.blue.withOpacity(0.8);
    canvas.drawCircle(
      Offset(size.x * 0.5, -size.y * 0.4),
      size.x * 0.02,
      lensPaint,
    );
  }

  // Drone pervanesi yardımcı metodu
  void _renderDronePropeller(
      Canvas canvas, Offset center, double rotation, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Pervane merkezi
    canvas.drawCircle(
      Offset.zero,
      size.x * 0.05,
      paint,
    );

    // Pervane kanatları
    for (int i = 0; i < 3; i++) {
      final angle = (math.pi * 2 / 3) * i;
      final bladePath = Path()
        ..moveTo(0, 0)
        ..lineTo(
            math.cos(angle) * size.x * 0.15, math.sin(angle) * size.x * 0.15)
        ..lineTo(math.cos(angle + 0.3) * size.x * 0.12,
            math.sin(angle + 0.3) * size.x * 0.12)
        ..close();

      canvas.drawPath(bladePath, paint);
    }

    canvas.restore();
  }
}

extension ColorExtension on Color {
  Color darken(double amount) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  Color lighten(double amount) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final hslLight =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }
}
