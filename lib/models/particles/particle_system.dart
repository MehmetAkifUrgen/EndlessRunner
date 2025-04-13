import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'particle.dart';
import 'package:flutter/painting.dart';

class ParticleSystem extends Component {
  final List<Particle> particles = [];
  final int maxParticles;
  final Random random = Random();

  ParticleSystem({this.maxParticles = 200});

  @override
  void update(double dt) {
    // Ölen parçacıkları temizle
    particles.removeWhere((particle) => particle.isDead);

    // Parçacıkları güncelle
    for (var particle in particles) {
      particle.update(dt);
    }

    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    for (var particle in particles) {
      particle.render(canvas);
    }
    super.render(canvas);
  }

  // Dairesel parçacık patlaması
  void createExplosion({
    required Vector2 position,
    required Color color,
    int count = 20,
    double speed = 100.0,
    double size = 5.0,
    double lifespan = 1.0,
  }) {
    for (int i = 0; i < count; i++) {
      if (particles.length >= maxParticles) break;

      final angle = random.nextDouble() * 2 * pi;
      final velocity = Vector2(
        cos(angle) * speed * (0.5 + random.nextDouble()),
        sin(angle) * speed * (0.5 + random.nextDouble()),
      );

      particles.add(
        Particle(
          position: position.clone(),
          velocity: velocity,
          color: color,
          size: size * (0.5 + random.nextDouble()),
          lifespan: lifespan * (0.5 + random.nextDouble()),
        ),
      );
    }
  }

  // Konfeti patlaması
  void createConfetti({
    required Vector2 position,
    int count = 30,
    double speed = 200.0,
    double lifespan = 2.0,
  }) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange
    ];

    for (int i = 0; i < count; i++) {
      if (particles.length >= maxParticles) break;

      final angle = random.nextDouble() * 2 * pi;
      final velocity = Vector2(
        cos(angle) * speed * (0.3 + random.nextDouble()),
        sin(angle) * speed * (0.3 + random.nextDouble()) -
            100, // Biraz yukarı doğru
      );

      particles.add(
        ConfettiParticle(
          position: position.clone(),
          velocity: velocity,
          color: colors[random.nextInt(colors.length)],
          lifespan: lifespan * (0.5 + random.nextDouble()),
          width: 3 + random.nextDouble() * 5,
          height: 6 + random.nextDouble() * 10,
        ),
      );
    }
  }

  // Yıldız parçacık patlaması
  void createStars({
    required Vector2 position,
    required Color color,
    int count = 10,
    double speed = 150.0,
    double size = 10.0,
    double lifespan = 1.5,
  }) {
    for (int i = 0; i < count; i++) {
      if (particles.length >= maxParticles) break;

      final angle = random.nextDouble() * 2 * pi;
      final velocity = Vector2(
        cos(angle) * speed * (0.5 + random.nextDouble()),
        sin(angle) * speed * (0.5 + random.nextDouble()),
      );

      particles.add(
        StarParticle(
          position: position.clone(),
          velocity: velocity,
          color: color,
          size: size * (0.5 + random.nextDouble()),
          lifespan: lifespan * (0.5 + random.nextDouble()),
          spikes: random.nextInt(3) + 4, // 4-6 köşeli yıldızlar
        ),
      );
    }
  }

  // Duman parçacıkları
  void createSmoke({
    required Vector2 position,
    int count = 8,
    double speed = 50.0,
    double size = 20.0,
    double lifespan = 2.0,
    Color color = Colors.grey,
  }) {
    for (int i = 0; i < count; i++) {
      if (particles.length >= maxParticles) break;

      // Yukarı doğru duman
      final angle = -pi / 2 +
          (random.nextDouble() - 0.5) * pi / 4; // -π/2 ± π/8 (yukarı doğru)
      final velocity = Vector2(
        cos(angle) * speed * (0.3 + random.nextDouble()),
        sin(angle) * speed * (0.3 + random.nextDouble()),
      );

      particles.add(
        SmokeParticle(
          position: position.clone(),
          velocity: velocity,
          color: color,
          size: size * (0.6 + random.nextDouble()),
          lifespan: lifespan * (0.7 + random.nextDouble()),
        ),
      );
    }
  }

  // Koşma parçacıkları
  void createRunningDust({
    required Vector2 position,
    int count = 3,
    double speed = 20.0,
    double size = 10.0,
    double lifespan = 0.7,
    Color color = const Color(0xBBBBBBBB),
  }) {
    for (int i = 0; i < count; i++) {
      if (particles.length >= maxParticles) break;

      // Zeminden hafif yukarı ve arkaya doğru
      final velocity = Vector2(
        -speed * (0.8 + random.nextDouble() * 0.4), // Arkaya doğru
        -speed * 0.5 * random.nextDouble(), // Hafif yukarı
      );

      particles.add(
        SmokeParticle(
          position: position.clone(),
          velocity: velocity,
          color: color,
          size: size * (0.7 + random.nextDouble() * 0.6),
          lifespan: lifespan * (0.6 + random.nextDouble() * 0.8),
        ),
      );
    }
  }

  // Güç yükseltme efekti
  void createPowerUpEffect({
    required Vector2 position,
    required Color color,
    int count = 20,
    double size = 8.0,
    double lifespan = 1.5,
  }) {
    createStars(
      position: position,
      color: color,
      count: count ~/ 2,
      speed: 180,
      size: size,
      lifespan: lifespan,
    );

    createExplosion(
      position: position,
      color: color.withOpacity(0.7),
      count: count ~/ 2,
      speed: 120,
      size: size * 0.8,
      lifespan: lifespan * 0.8,
    );
  }
}
