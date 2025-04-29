import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Particle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  double size;
  double lifespan;
  double maxLifespan;
  bool isDead = false;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifespan,
  }) : maxLifespan = lifespan;

  void update(double dt) {
    position.add(velocity * dt);
    lifespan -= dt;

    if (lifespan <= 0) {
      isDead = true;
    }
  }

  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color.withOpacity((lifespan / maxLifespan).clamp(0.0, 1.0));
    canvas.drawCircle(Offset(position.x, position.y),
        size * (lifespan / maxLifespan).clamp(0.1, 1.0), paint);
  }
}

// Konfeti parçacık sınıfı
class ConfettiParticle extends Particle {
  double rotation = 0;
  double rotationSpeed;
  final double width;
  final double height;

  ConfettiParticle({
    required Vector2 position,
    required Vector2 velocity,
    required Color color,
    required double lifespan,
    this.width = 5.0,
    this.height = 10.0,
  })  : rotationSpeed = (Random().nextDouble() * 10) - 5,
        super(
          position: position,
          velocity: velocity,
          color: color,
          size: max(width, height),
          lifespan: lifespan,
        );

  @override
  void update(double dt) {
    super.update(dt);
    rotation += rotationSpeed * dt;

    // Parçacık yavaşlaması
    velocity.scale(0.95);
  }

  @override
  void render(Canvas canvas) {
    final opacity = (lifespan / maxLifespan).clamp(0.0, 1.0);
    final paint = Paint()..color = color.withOpacity(opacity);

    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(rotation);

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: width * opacity,
        height: height * opacity,
      ),
      paint,
    );

    canvas.restore();
  }
}

// Yıldız parçacık sınıfı
class StarParticle extends Particle {
  double rotation = 0;
  double rotationSpeed;
  final double spikes;

  StarParticle({
    required Vector2 position,
    required Vector2 velocity,
    required Color color,
    required double size,
    required double lifespan,
    this.spikes = 5,
  })  : rotationSpeed = (Random().nextDouble() * 5) - 2.5,
        super(
          position: position,
          velocity: velocity,
          color: color,
          size: size,
          lifespan: lifespan,
        );

  @override
  void update(double dt) {
    super.update(dt);
    rotation += rotationSpeed * dt;

    // Parçacık yavaş yavaş küçülür
    size *= 0.99;
  }

  @override
  void render(Canvas canvas) {
    final opacity = (lifespan / maxLifespan).clamp(0.0, 1.0);
    final paint = Paint()..color = color.withOpacity(opacity);

    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(rotation);

    final path = Path();
    final outerRadius = size * opacity;
    final innerRadius = outerRadius / 2;

    for (int i = 0; i < spikes * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * pi) / spikes;
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }
}

// Duman parçacık sınıfı
class SmokeParticle extends Particle {
  SmokeParticle({
    required Vector2 position,
    required Vector2 velocity,
    required Color color,
    required double size,
    required double lifespan,
  }) : super(
          position: position,
          velocity: velocity,
          color: color,
          size: size,
          lifespan: lifespan,
        );

  @override
  void render(Canvas canvas) {
    final opacity = (lifespan / maxLifespan).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withOpacity(opacity * 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    canvas.drawCircle(
      Offset(position.x, position.y),
      size * opacity,
      paint,
    );
  }
}
