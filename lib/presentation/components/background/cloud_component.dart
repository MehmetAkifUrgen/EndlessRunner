import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../pages/game_screen.dart';

class CloudComponent extends PositionComponent with HasGameRef<RunnerGame> {
  final Paint _paint = Paint()..color = Colors.white.withOpacity(0.8);
  final math.Random _random = math.Random();

  CloudComponent({
    required Vector2 position,
    required Vector2 size,
    double speed = 50, // Bu parametre artık kullanılmıyor
  }) : super(
          position: position,
          size: size,
        );

  // update metodu kaldırıldı, bulutlar artık kesinlikle hareket etmeyecek

  @override
  void render(Canvas canvas) {
    final path = Path();

    // Bulut şekli
    final bulutGenisligi = size.x;
    final bulutYuksekligi = size.y;

    // Ana şekil - oval
    path.addOval(Rect.fromCenter(
        center: Offset(bulutGenisligi / 2, bulutYuksekligi / 2),
        width: bulutGenisligi * 0.8,
        height: bulutYuksekligi * 0.5));

    // Üst kısım - küçük yuvarlaklar
    final kucukDaireSayisi = 3 + _random.nextInt(3); // 3-5 arası küçük daire

    for (int i = 0; i < kucukDaireSayisi; i++) {
      final x = bulutGenisligi * (0.2 + _random.nextDouble() * 0.6);
      final y = bulutYuksekligi * (0.1 + _random.nextDouble() * 0.3);
      final yaricap = bulutGenisligi * (0.1 + _random.nextDouble() * 0.15);

      path.addOval(Rect.fromCircle(center: Offset(x, y), radius: yaricap));
    }

    // Gölge efekti
    canvas.drawShadow(path, Colors.grey.withOpacity(0.3), 4.0, true);

    // Bulut çizimi
    canvas.drawPath(path, _paint);
  }
}
