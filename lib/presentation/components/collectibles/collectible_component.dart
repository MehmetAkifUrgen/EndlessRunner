import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../domain/entities/collectible.dart'; // Entity importu
import '../../pages/game_screen.dart'; // RunnerGame importu
import '../player/player_component.dart'; // PlayerComponent importu
import 'dart:math';

// Toplanabilir Bileşen
class CollectibleComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<RunnerGame> {
  final CollectibleType type;
  final RunnerGame game;
  late final Paint _paint;
  late final Paint _glowPaint;
  final Random _random = Random();
  double _animTime = 0;
  double _hoverHeight = 0;
  double _rotationSpeed = 0.5;
  double _rotation = 0;

  CollectibleComponent({
    required Vector2 position,
    required this.type,
    required this.game,
  }) : super(
            position: position,
            size: _getSizeForType(type),
            anchor: Anchor.center) {
    // Ortadan konumlandır
    final Color baseColor = _getColorForType(type);
    _paint = Paint()..color = baseColor;

    // Parıltı efekti için ikinci bir paint
    _glowPaint = Paint()
      ..color = baseColor.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Başlangıç yüksekliği rastgele
    _hoverHeight = _random.nextDouble() * 10;

    // Rastgele dönme hızı
    _rotationSpeed = 0.2 + _random.nextDouble() * 0.6;

    // Hitbox ekle (biraz daha büyük olabilir, toplaması kolay olsun)
    add(RectangleHitbox(
        size: size * 1.2, position: -size * 0.1)); // Biraz büyüt ve ortala
  }

  // Türe göre boyut döndür
  static Vector2 _getSizeForType(CollectibleType type) {
    switch (type) {
      case CollectibleType.coin:
        return Vector2(25, 25);
      case CollectibleType.magnet:
      case CollectibleType.shield:
      case CollectibleType.slowMotion:
        return Vector2(35, 35); // Power-up'lar biraz daha büyük
      case CollectibleType.extraLife: // Eksik case eklendi
        return Vector2(30, 30); // Kalp ikonu için boyut
      case CollectibleType.scoreBoost: // scoreBoost case'i eklendi
        return Vector2(30, 30); // Örnek boyut
      case CollectibleType.speedBoost: // speedBoost case'i eklendi
        return Vector2(35, 35); // Örnek boyut (şimşek ikonu?)
    }
  }

  // Türe göre renk döndür
  Color _getColorForType(CollectibleType type) {
    switch (type) {
      case CollectibleType.coin:
        return Colors.amber;
      case CollectibleType.magnet:
        return Colors.grey.shade400;
      case CollectibleType.shield:
        return Colors.lightBlueAccent;
      case CollectibleType.slowMotion:
        return Colors.cyanAccent;
      case CollectibleType.extraLife: // Eksik case eklendi
        return Colors.red.shade400;
      case CollectibleType.scoreBoost: // scoreBoost case'i eklendi
        return Colors.purpleAccent;
      case CollectibleType.speedBoost:
        return Colors.orangeAccent;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Hareket zamanlayıcıları güncelle
    _animTime += dt;

    // Havada yükselip alçalma animasyonu
    _hoverHeight = sin(_animTime * 2) * 5;
    position.y += sin(_animTime * 3) * 0.5; // Yukarı aşağı hareket

    // Dönme animasyonu
    _rotation += _rotationSpeed * dt;

    // Sola doğru hareket (eğer mıknatıs tarafından çekilmiyorsa)
    if (!game.hasMagnet ||
        game.player == null ||
        (position + size / 2)
                .distanceTo(game.player!.position + game.player!.size / 2) >=
            150.0) {
      position.x -= game.gameSpeed *
          dt *
          0.8; // Toplanabilirler biraz daha yavaş gidebilir
    }

    // Ekran dışına çıkarsa kendini kaldır (oyun motoru zaten yapıyor)
    // if (position.x < -size.x) {
    //   removeFromParent();
    //   game.collectibles.remove(this);
    // }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();

    // Dönme ve yükseğe kaldırma
    canvas.translate(0, -_hoverHeight);
    canvas.rotate(_rotation);

    // Parıltı efekti çiz
    _renderGlow(canvas);

    // Toplanabilirlerin tipine göre şekil çiz
    _renderCollectible(canvas);

    canvas.restore();
  }

  void _renderGlow(Canvas canvas) {
    // Parıltı efekti
    canvas.drawCircle(
      Offset.zero,
      size.x * 0.6,
      _glowPaint,
    );
  }

  void _renderCollectible(Canvas canvas) {
    switch (type) {
      case CollectibleType.coin:
        _renderCoin(canvas);
        break;
      case CollectibleType.extraLife:
        _renderHeart(canvas);
        break;
      case CollectibleType.shield:
        _renderShield(canvas);
        break;
      case CollectibleType.magnet:
        _renderMagnet(canvas);
        break;
      case CollectibleType.slowMotion:
        _renderClock(canvas);
        break;
      case CollectibleType.scoreBoost:
        _renderStar(canvas);
        break;
      case CollectibleType.speedBoost:
        _renderLightning(canvas);
        break;
    }
  }

  void _renderCoin(Canvas canvas) {
    // Altın para
    final Paint goldPaint = Paint()..color = Colors.amber;
    final Paint highlightPaint = Paint()..color = Colors.yellowAccent;

    // Ana daire
    canvas.drawCircle(Offset.zero, size.x * 0.4, goldPaint);

    // Parlak kenar
    final Path highlightPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset.zero, radius: size.x * 0.4),
        -math.pi / 4,
        math.pi / 2,
      );
    canvas.drawPath(
        highlightPath,
        highlightPaint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    // "C" harfi
    final textPaint = TextPaint(
      style: TextStyle(
        color: Colors.amber.shade900,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    textPaint.render(
      canvas,
      "C",
      Vector2(-5, -7),
    );
  }

  void _renderHeart(Canvas canvas) {
    // Kalp şekli
    final path = Path();
    final size = this.size.x * 0.35;

    path.moveTo(0, size * 0.3);
    path.cubicTo(
      -size,
      -size * 0.5,
      -size * 2,
      size * 0.5,
      0,
      size * 1.5,
    );
    path.cubicTo(
      size * 2,
      size * 0.5,
      size,
      -size * 0.5,
      0,
      size * 0.3,
    );

    canvas.drawPath(path, _paint);
  }

  void _renderShield(Canvas canvas) {
    // Kalkan şekli
    final path = Path();
    final s = size.x * 0.4;

    path.moveTo(0, -s);
    path.lineTo(-s, -s * 0.3);
    path.quadraticBezierTo(-s, s, 0, s);
    path.quadraticBezierTo(s, s, s, -s * 0.3);
    path.lineTo(0, -s);

    canvas.drawPath(path, _paint);

    // Kalkan ortasındaki çizgi
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, -s * 0.3),
      Offset(0, s * 0.5),
      linePaint,
    );
  }

  void _renderMagnet(Canvas canvas) {
    // Mıknatıs şekli
    final barHeight = size.y * 0.5;
    final barWidth = size.x * 0.2;
    final archHeight = size.y * 0.3;

    // Mıknatısın gövdesi
    final redPaint = Paint()..color = Colors.red;
    final bluePaint = Paint()..color = Colors.blue;

    // Sol kutup (Kırmızı)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            -size.x * 0.25 - barWidth, -barHeight / 2, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      ),
      redPaint,
    );

    // Sağ kutup (Mavi)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.25, -barHeight / 2, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      ),
      bluePaint,
    );

    // Üst bağlantı (kavis)
    final archPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = barWidth;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(0, -barHeight / 2 + barWidth / 2),
        width: size.x * 0.5,
        height: archHeight,
      ),
      math.pi,
      math.pi,
      false,
      archPaint,
    );
  }

  void _renderClock(Canvas canvas) {
    // Saat şekli
    final clockPaint = Paint()
      ..color = _paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Saat çemberi
    canvas.drawCircle(
      Offset.zero,
      size.x * 0.4,
      clockPaint,
    );

    // Akrep ve yelkovan
    final handPaint = Paint()
      ..color = _paint.color
      ..strokeWidth = 2;

    // Akrep (kısa)
    canvas.drawLine(
      Offset.zero,
      Offset(size.x * 0.2, -size.y * 0.1),
      handPaint,
    );

    // Yelkovan (uzun)
    handPaint.strokeWidth = 1;
    canvas.drawLine(
      Offset.zero,
      Offset(0, -size.y * 0.3),
      handPaint,
    );

    // 12, 3, 6, 9 noktaları
    final dotPaint = Paint()..color = _paint.color;
    canvas.drawCircle(Offset(0, -size.y * 0.35), 2, dotPaint);
    canvas.drawCircle(Offset(size.x * 0.35, 0), 2, dotPaint);
    canvas.drawCircle(Offset(0, size.y * 0.35), 2, dotPaint);
    canvas.drawCircle(Offset(-size.x * 0.35, 0), 2, dotPaint);
  }

  void _renderStar(Canvas canvas) {
    // Yıldız şekli (5 köşeli)
    final path = Path();
    final outerRadius = size.x * 0.4;
    final innerRadius = outerRadius * 0.4;
    const points = 5;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = i * math.pi / points -
          math.pi / 2; // -pi/2 rotasyonu ile en üst noktadan başla
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, _paint);

    // Merkezdeki parlak nokta
    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset.zero, size.x * 0.1, centerPaint);
  }

  void _renderLightning(Canvas canvas) {
    // Şimşek şekli
    final path = Path();
    final s = size.x * 0.4;

    path.moveTo(0, -s);
    path.lineTo(s * 0.4, -s * 0.2);
    path.lineTo(0, s * 0.3);
    path.lineTo(s * 0.6, s);
    path.lineTo(s * 0.2, 0);
    path.lineTo(s * 0.8, -s * 0.6);
    path.lineTo(0, -s);

    canvas.drawPath(path, _paint);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    // Sadece oyuncu ile çarpışmayı dikkate al
    if (other is PlayerComponent) {
      // game.collect(this); // Oyun motoru zaten handleCollision içinde yapıyor
      removeFromParent(); // Kendini kaldır
      game.collectibles.remove(this);
    }
  }

  Color get color => _paint.color;
}
