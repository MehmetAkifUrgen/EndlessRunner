import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../pages/game_screen.dart';

class BackgroundComponent extends PositionComponent
    with HasGameRef<RunnerGame> {
  final Paint _skyPaint = Paint();
  final Paint _mountainPaint = Paint();
  final Paint _groundPaint = Paint();
  final Paint _linePaint = Paint();

  final List<Cloud> _clouds = [];
  final List<Mountain> _mountains = [];
  final List<Star> _stars = [];

  double _groundY = 0;
  double _time = 0;

  // Paralaks çarpanları - daha etkili paralaks için değerler ayarlandı
  final double _mountainParallaxFactor = 0.4;
  final double _cloudParallaxFactor = 0.2;
  final double _starParallaxFactor = 0.05;

  // Statik renkler
  static const Color _skyTopColor = Color(0xFF1A237E);
  static const Color _skyMiddleColor = Color(0xFF5C6BC0);
  static const Color _skyBottomColor = Color(0xFF9FA8DA);
  static const Color _mountainColor = Color(0xFF455A64);
  static const Color _groundColor = Color(0xFF2E7D32);

  BackgroundComponent() {
    _skyPaint
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _skyTopColor,
          _skyMiddleColor,
          _skyBottomColor,
        ],
      ).createShader(Rect.fromLTWH(0, 0, 1, 500));

    _mountainPaint..color = _mountainColor;
    _groundPaint..color = _groundColor;

    _linePaint
      ..color = Colors.green.shade800
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _initializeStars();
    _generateClouds();
    _generateMountains();

    // Yer seviyesi
    _groundY = size.y * 0.8;
  }

  void _initializeStars() {
    // Yıldızlar
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.x;
      final y = random.nextDouble() * (size.y * 0.6);
      final particleSize = 1.0 + random.nextDouble() * 3;
      final twinkleSpeed = 0.5 + random.nextDouble() * 2;

      _stars.add(Star(
        position: Vector2(x, y),
        particleSize: particleSize,
        twinkleSpeed: twinkleSpeed,
        twinkleOffset: random.nextDouble() * math.pi * 2,
      ));
    }
  }

  void _generateClouds() {
    _clouds.clear();
    final random = math.Random();

    // Bulut sayısını ekran boyutuna göre ayarla
    final cloudCount = math.max(6, (size.x / 150).ceil());

    for (int i = 0; i < cloudCount; i++) {
      final x = random.nextDouble() * size.x * 1.5;
      final y = 50 + random.nextDouble() * 150;
      final width = 80 + random.nextDouble() * 150;
      final height = 40 + random.nextDouble() * 60;
      final speed = 5 + random.nextDouble() * 15; // Daha yavaş hareket

      _clouds.add(Cloud(
        position: Vector2(x, y),
        width: width,
        height: height,
        speed: speed,
      ));
    }
  }

  void _generateMountains() {
    _mountains.clear();
    final random = math.Random();

    // Dağ sayısını ekran boyutuna göre ayarla
    final mountainCount = math.max(4, (size.x / 200).ceil());

    for (int i = 0; i < mountainCount; i++) {
      final x = i * size.x / (mountainCount - 1);
      final height = 100 + random.nextDouble() * 150;

      _mountains.add(Mountain(
        position: Vector2(x, _groundY),
        width: size.x / 2,
        height: height,
      ));
    }
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
    _groundY = size.y * 0.8;

    // Yeniden boyutlandırma sonrası arka planı güncelle
    if (_mountains.isEmpty) {
      _generateMountains();
    } else {
      _repositionMountains();
    }

    if (_clouds.isEmpty) {
      _generateClouds();
    } else {
      _repositionClouds();
    }

    if (_stars.isEmpty) {
      _initializeStars();
    } else {
      _repositionStars();
    }

    // Gökyüzü gradyanını güncelle
    _skyPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _skyTopColor,
        _skyMiddleColor,
        _skyBottomColor,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
  }

  void _repositionMountains() {
    // Dağları yeni ekran boyutuna göre yeniden konumlandır
    final mountainCount = _mountains.length;
    for (int i = 0; i < mountainCount; i++) {
      final mountain = _mountains[i];
      mountain.position.x = i * size.x / (mountainCount - 1);
      mountain.position.y = _groundY;
    }
  }

  void _repositionClouds() {
    // Bulutları yeni ekran boyutuna göre yeniden konumlandır
    for (final cloud in _clouds) {
      // Ekran dışındaki bulutları ekran içine al
      if (cloud.position.x > size.x) {
        cloud.position.x = math.Random().nextDouble() * size.x;
      }
    }
  }

  void _repositionStars() {
    // Yıldızları yeni ekran boyutuna göre yeniden konumlandır
    final random = math.Random();
    for (final star in _stars) {
      // Ekran dışındaki yıldızları ekran içine al
      if (star.position.x > size.x || star.position.y > size.y * 0.6) {
        star.position.x = random.nextDouble() * size.x;
        star.position.y = random.nextDouble() * (size.y * 0.6);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Yıldızları güncelle
    for (final star in _stars) {
      star.update(dt);
    }

    // Bulutları güncelle
    for (int i = 0; i < _clouds.length; i++) {
      final cloud = _clouds[i];
      cloud.position.x -= cloud.speed * dt * _cloudParallaxFactor;

      // Ekrandan çıkan bulutları yeniden konumlandır
      if (cloud.position.x + cloud.width < 0) {
        cloud.position.x = size.x + math.Random().nextDouble() * 100;
        cloud.position.y = 50 + math.Random().nextDouble() * 150;
      }
    }

    // Dağları güncelle
    for (int i = 0; i < _mountains.length; i++) {
      final mountain = _mountains[i];
      mountain.position.x -= game.gameSpeed * dt * _mountainParallaxFactor;

      // Ekrandan çıkan dağları yeniden konumlandır
      if (mountain.position.x + mountain.width < 0) {
        final lastMountain =
            _mountains[(i - 1 + _mountains.length) % _mountains.length];
        mountain.position.x =
            lastMountain.position.x + lastMountain.width * 0.8;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Gökyüzü
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _skyPaint,
    );

    // Yıldızlar - render performansı için ekranda olanları çiz
    for (final star in _stars) {
      if (star.position.x >= 0 &&
          star.position.x <= size.x &&
          star.position.y >= 0 &&
          star.position.y <= size.y) {
        star.render(canvas);
      }
    }

    // Dağlar
    for (final mountain in _mountains) {
      if (mountain.position.x + mountain.width >= 0 &&
          mountain.position.x <= size.x) {
        mountain.render(canvas);
      }
    }

    // Bulutlar
    for (final cloud in _clouds) {
      if (cloud.position.x + cloud.width >= 0 &&
          cloud.position.x <= size.x &&
          cloud.position.y + cloud.height >= 0 &&
          cloud.position.y <= size.y) {
        cloud.render(canvas);
      }
    }

    // Yer (zemin)
    canvas.drawRect(
      Rect.fromLTWH(0, _groundY, size.x, size.y - _groundY),
      _groundPaint,
    );

    // Zemin üzerinde çizgiler
    for (int i = 0; i < 10; i++) {
      final y = _groundY + i * 10;
      if (y < size.y) {
        _linePaint.color = Colors.green.shade800.withOpacity(0.3 - i * 0.03);
        canvas.drawLine(
          Offset(0, y),
          Offset(size.x, y),
          _linePaint,
        );
      }
    }
  }
}

class Star {
  Vector2 position;
  double particleSize;
  double twinkleSpeed;
  double twinkleOffset;
  double _time = 0;
  late final Paint _paint;

  Star({
    required this.position,
    required this.particleSize,
    required this.twinkleSpeed,
    required this.twinkleOffset,
  }) {
    _paint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
  }

  void update(double dt) {
    _time += dt;
  }

  void render(Canvas canvas) {
    final brightness =
        0.5 + 0.5 * math.sin(_time * twinkleSpeed + twinkleOffset);

    _paint.color = Colors.white.withOpacity(brightness);

    canvas.drawCircle(
      Offset(position.x, position.y),
      particleSize * (0.8 + 0.2 * brightness),
      _paint,
    );
  }
}

class Cloud {
  Vector2 position;
  double width;
  double height;
  double speed;
  late final Paint _paint;
  late final Paint _innerPaint;

  Cloud({
    required this.position,
    required this.width,
    required this.height,
    required this.speed,
  }) {
    _paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    _innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  }

  void render(Canvas canvas) {
    // Ana bulut gövdesi
    canvas.drawOval(
      Rect.fromLTWH(position.x, position.y, width, height),
      _paint,
    );

    // İç detaylar için daha açık renk
    canvas.drawOval(
      Rect.fromLTWH(position.x + width * 0.2, position.y + height * 0.2,
          width * 0.6, height * 0.6),
      _innerPaint,
    );

    // Ek bulut parçaları
    canvas.drawOval(
      Rect.fromLTWH(position.x - width * 0.1, position.y + height * 0.3,
          width * 0.5, height * 0.7),
      _paint,
    );

    canvas.drawOval(
      Rect.fromLTWH(position.x + width * 0.6, position.y + height * 0.2,
          width * 0.5, height * 0.7),
      _paint,
    );
  }
}

class Mountain {
  Vector2 position;
  double width;
  double height;
  late final Paint _paint;
  late final Paint _snowPaint;
  late final Paint _detailPaint;

  Mountain({
    required this.position,
    required this.width,
    required this.height,
  }) {
    _paint = Paint()
      ..color = const Color(0xFF546E7A)
      ..style = PaintingStyle.fill;

    _snowPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    _detailPaint = Paint()
      ..color = const Color(0xFF37474F).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
  }

  void render(Canvas canvas) {
    final path = Path();

    // Dağ silüeti
    path.moveTo(position.x, position.y);

    // Sol taraf
    path.lineTo(position.x + width * 0.3, position.y - height * 0.7);

    // Zirve
    path.lineTo(position.x + width * 0.5, position.y - height);

    // Sağ taraf
    path.lineTo(position.x + width * 0.8, position.y - height * 0.6);

    // Taban
    path.lineTo(position.x + width, position.y);

    // Kapatma
    path.close();

    canvas.drawPath(path, _paint);

    // Kar efekti
    final snowPath = Path();

    // Kar silüeti
    final snowY = position.y - height * 0.9;

    snowPath.moveTo(position.x + width * 0.4, snowY);
    snowPath.lineTo(position.x + width * 0.5, position.y - height);
    snowPath.lineTo(position.x + width * 0.6, snowY);
    snowPath.close();

    canvas.drawPath(snowPath, _snowPaint);

    // Gölge ve detay
    final detailPath = Path();

    // Sol yamaç detayı
    detailPath.moveTo(position.x + width * 0.2, position.y - height * 0.3);
    detailPath.lineTo(position.x + width * 0.3, position.y - height * 0.5);
    detailPath.lineTo(position.x + width * 0.4, position.y - height * 0.4);

    // Sağ yamaç detayı
    detailPath.moveTo(position.x + width * 0.6, position.y - height * 0.4);
    detailPath.lineTo(position.x + width * 0.7, position.y - height * 0.5);
    detailPath.lineTo(position.x + width * 0.8, position.y - height * 0.3);

    canvas.drawPath(detailPath, _detailPaint);
  }
}
