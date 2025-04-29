import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../pages/game_screen.dart';

class GrassComponent extends PositionComponent with HasGameRef<RunnerGame> {
  final Color? groundColor;
  late final Paint _mainPaint;
  late final Paint _grassPaint;
  final List<Offset> _grassBlades = [];
  final Random _random = Random();
  final int _bladeCount = 100;
  double _time = 0;

  GrassComponent({
    required Vector2 position,
    required Vector2 size,
    this.groundColor,
  }) : super(position: position, size: size) {
    _mainPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          (groundColor ?? Colors.green.shade800).withOpacity(1.0),
          (groundColor ?? Colors.green.shade900).withOpacity(1.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    _grassPaint = Paint()
      ..color = (groundColor ?? Colors.green.shade800).withOpacity(0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    _generateGrassBlades();
  }

  void _generateGrassBlades() {
    for (int i = 0; i < _bladeCount; i++) {
      double x = _random.nextDouble() * size.x;
      double heightVariation = _random.nextDouble() * 10 + 5;
      _grassBlades.add(Offset(x, heightVariation));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    // Ana zemin
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _mainPaint,
    );

    // Zeminde doku deseni
    final patternPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < 20; i++) {
      double y = i * (size.y / 20);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.x, y),
        patternPaint,
      );
    }

    // Çim sapları
    for (int i = 0; i < _grassBlades.length; i++) {
      final blade = _grassBlades[i];
      final waveOffset = sin(_time * 2 + i * 0.1) * 1.5;

      final path = Path()
        ..moveTo(blade.dx, 0)
        ..quadraticBezierTo(blade.dx + waveOffset, -blade.dy / 2,
            blade.dx + waveOffset * 0.5, -blade.dy);

      canvas.drawPath(path, _grassPaint);
    }
  }
}
