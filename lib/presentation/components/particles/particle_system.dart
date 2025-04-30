import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'particle.dart'; // Temel Particle sınıfımız
import 'package:flutter/painting.dart';
import 'dart:math' as math;

class ParticleSystem extends Component {
  final List<Particle> particles = [];
  final int maxParticles;
  final math.Random random = math.Random();

  ParticleSystem({this.maxParticles = 200});

  @override
  void update(double dt) {
    // Ölen parçacıkları temizle
    particles.removeWhere((particle) => particle.isDead);

    // Parçacık sayısını kontrol et - çok fazlaysa en eski parçacıkları kaldır
    if (particles.length > maxParticles) {
      final toRemove = particles.length - maxParticles;
      particles.removeRange(0, toRemove);
    }

    // Parçacıkları güncelle
    for (var particle in particles) {
      particle.update(dt);
    }

    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    // Performans için sadece ekran içindeki parçacıkları çiz
    final currentParticles = particles.length;

    // Çok sayıda parçacık varsa hepsini işleme - FPS düşüşünü önlemek için
    final toRender = currentParticles > 100
        ? particles.sublist(currentParticles - 100)
        : particles;

    for (var particle in toRender) {
      particle.render(canvas);
    }
    super.render(canvas);
  }

  // Çok sayıda parçacık oluşturur
  void createParticles({
    required int count,
    required Vector2 position,
    required Vector2 particleSize,
    required List<Color> colors,
    required double speed,
    required double lifespan,
    double gravity = 200,
    double rotationSpeed = 0.0,
  }) {
    // Maksimum parçacık sayısını kontrol et
    final currentParticles = particles.length;
    final allowedCount = math.min(count, maxParticles - currentParticles);

    if (allowedCount <= 0) return;

    for (var i = 0; i < allowedCount; i++) {
      // Rastgele yön
      final angle = random.nextDouble() * 2 * math.pi;
      final speedValue = speed * (0.5 + random.nextDouble() * 0.5);

      final velocity = Vector2(
        math.cos(angle) * speedValue,
        math.sin(angle) * speedValue,
      );

      // Rastgele renk
      final color = colors[random.nextInt(colors.length)];

      // Rastgele başlangıç pozisyonu (küçük bir ofset)
      final startPos = Vector2(
        position.x + random.nextDouble() * 10 - 5,
        position.y + random.nextDouble() * 10 - 5,
      );

      // Parçacık oluştur ve listeye ekle
      final particle = Particle(
        position: startPos.clone(),
        velocity: velocity,
        color: color,
        size: particleSize.x * (0.7 + random.nextDouble() * 0.6),
        lifespan: lifespan * (0.7 + random.nextDouble() * 0.6),
      );

      particles.add(particle);
    }
  }

  // Daha basit bir arayüz sağlar - createParticles ile aynı işi yapar
  void emit({
    required int count,
    required Vector2 position,
    required List<Color> colors,
    required Vector2 size,
    required double speed,
    required double lifespan,
    double gravity = 200,
    double rotationSpeed = 0.0,
  }) {
    createParticles(
      count: count,
      position: position,
      particleSize: size,
      colors: colors,
      speed: speed,
      lifespan: lifespan,
    );
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
