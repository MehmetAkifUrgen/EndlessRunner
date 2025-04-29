import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui'; // PathMetrics, PathMetric, Tangent için eklendi
import '../../pages/game_screen.dart'; // RunnerGame importu
import '../../../utils/extensions.dart'; // DarkenColor importu

// Dağ Bileşeni (Arka Plan)
class MountainComponent extends PositionComponent with HasGameRef<RunnerGame> {
  final Color mountainColor; // Tema rengi (nullable değil)
  final Paint _paint;
  final math.Random _random = math.Random();

  MountainComponent({
    required Vector2 position,
    required Vector2 size,
    required this.mountainColor,
    required RunnerGame game,
  })  : _paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (mountainColor ?? Colors.blueGrey.shade700).withOpacity(0.8),
              (mountainColor ?? Colors.blueGrey.shade900).withOpacity(1.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.x, size.y))
          ..style = PaintingStyle.fill,
        super(position: position, size: size) {
    anchor = Anchor.bottomCenter;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Dağ gölgesi
    final shadowPath = Path();
    shadowPath.moveTo(0, size.y);
    shadowPath.lineTo(size.x / 2, 0);
    shadowPath.lineTo(size.x, size.y);
    shadowPath.close();

    canvas.drawShadow(shadowPath, Colors.black, 8.0, true);

    // Dağın kendisi
    final path = Path();
    path.moveTo(0, size.y);
    path.lineTo(size.x / 2, 0);
    path.lineTo(size.x, size.y);
    path.close();

    canvas.drawPath(path, _paint);

    // Dağ zirvesi kar efekti
    final snowPath = Path();
    snowPath.moveTo(size.x / 2 - size.x / 8, size.y / 6);
    snowPath.lineTo(size.x / 2, 0);
    snowPath.lineTo(size.x / 2 + size.x / 8, size.y / 6);
    snowPath.close();

    canvas.drawPath(snowPath, Paint()..color = Colors.white.withOpacity(0.7));
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Paralaks efekti: Dağlar oyuncudan daha yavaş hareket eder
    position.x -= game.gameSpeed * dt * 0.1; // Hızın %10'u ile hareket

    // Ekranın solundan çıkınca sağına ışınla (sürekli döngü)
    if (position.x + size.x / 2 < -50) {
      // Biraz pay bırak
      position.x = game.size.x + size.x / 2 + _random.nextDouble() * 100;
      // Yüksekliği ve şekli rastgele değiştir
      size = Vector2(
          100 + _random.nextDouble() * 150, 80 + _random.nextDouble() * 150);
      _paint.color = mountainColor
          .darken(_random.nextDouble() * 0.1); // Paint rengi güncellendi
      position.y = game.size.y - game.groundHeight - _random.nextDouble() * 100;
    }
  }
}
