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
