import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CloudComponent extends PositionComponent {
  final Vector2 velocity;
  final double gameWidth;
  final Paint _paint = Paint();
  final Path _cloudPath = Path();
  final Random _random = Random();
  double _time = 0;
  final double _waveSpeed = 0.5; // Bulut dalgalanma hızı

  CloudComponent({
    required Vector2 position,
    required this.velocity,
    required this.gameWidth,
  }) : super(position: position, size: Vector2(80, 40)) {
    _paint.color = Colors.white.withOpacity(0.9);
    _generatePath();
  }

  void _generatePath() {
    _cloudPath.reset();

    final width = size.x;
    final height = size.y;

    // Bir dizi yuvarlak oluşturarak bulut görünümü elde edelim
    const circleCount = 5;
    final circles = <Offset>[];
    final radii = <double>[];

    for (int i = 0; i < circleCount; i++) {
      double x = _random.nextDouble() * width;
      double y =
          (height / 2) + (_random.nextDouble() * height / 3 - height / 6);
      double radius = height * (0.3 + _random.nextDouble() * 0.4);
      circles.add(Offset(x, y));
      radii.add(radius);
    }

    // İlk daireyi ekle
    _cloudPath.addOval(Rect.fromCircle(center: circles[0], radius: radii[0]));

    // Diğer daireleri birleştir
    for (int i = 1; i < circleCount; i++) {
      _cloudPath.addOval(Rect.fromCircle(center: circles[i], radius: radii[i]));
    }
  }

  @override
  void update(double dt) {
    position.x += velocity.x * dt;

    // Hafif dalgalanma efekti
    _time += dt * _waveSpeed;
    position.y += sin(_time) * 0.3;

    // Ekranın dışına çıkınca diğer tarafa al
    if (position.x > gameWidth) {
      position.x = -size.x;
    }
  }

  @override
  void render(Canvas canvas) {
    // Gölge
    canvas.save();
    canvas.translate(5, 5);
    canvas.drawPath(_cloudPath, Paint()..color = Colors.black.withOpacity(0.2));
    canvas.restore();

    // Ana bulut
    canvas.drawPath(_cloudPath, _paint);

    // Parlaklık noktaları (güneş ışığı efekti)
    canvas.save();
    canvas.translate(size.x * 0.2, size.y * 0.3);
    canvas.drawCircle(
        Offset.zero, size.y * 0.15, Paint()..color = Colors.white);
    canvas.restore();
  }
}
