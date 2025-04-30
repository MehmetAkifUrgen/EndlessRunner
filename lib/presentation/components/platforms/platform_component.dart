import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../domain/entities/platform.dart';
import '../../pages/game_screen.dart';

class PlatformComponent extends PositionComponent
    with HasGameRef<RunnerGame>, CollisionCallbacks {
  final GamePlatform platform;
  double lifeTime = 0; // Platformun aktif kalma süresi
  double movementPhase = 0; // Hareket eden platformlar için sine fazı
  double initialX = 0; // Hareket eden platformların başlangıç X pozisyonu
  bool isCrumbling = false; // Platform çöküyor mu?
  double crumbleTime = 0; // Çökme zamanı

  PlatformComponent({
    required this.platform,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(platform.width, platform.height),
          anchor: Anchor.topLeft,
        );

  @override
  Future<void> onLoad() async {
    // Çarpışma kutusu ekle
    add(RectangleHitbox());

    // Başlangıç değerlerini kaydet
    initialX = position.x;

    // Crumbling platform için başlangıç süresi ata
    if (platform.type == PlatformType.crumbling) {
      lifeTime = platform.lifespan;
    }

    // Hareket eden platformlar için rastgele başlangıç fazı
    if (platform.type == PlatformType.moving) {
      movementPhase = math.Random().nextDouble() * math.pi * 2;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Oyun durmuşsa güncelleme yapma
    if (gameRef.isPaused || gameRef.isGameOver) return;

    // Platform tipine göre güncelleme
    switch (platform.type) {
      case PlatformType.moving:
        // Hareket eden platform - Sine hareketi
        movementPhase += dt;
        position.x =
            initialX + math.sin(movementPhase) * platform.movementDistance;
        break;

      case PlatformType.crumbling:
        // Oyuncu temas ettiyse zamanla çökme
        if (isCrumbling) {
          crumbleTime -= dt;

          // Titreşim efekti
          if (crumbleTime > 0) {
            position.x = initialX + (math.Random().nextDouble() - 0.5) * 4;
          } else {
            // Süre bittiyse platformu sil
            removeFromParent();
          }
        }
        break;

      default:
        // Diğer platform tipleri için standart davranış
        // Oyun hızına göre hareket et
        position.x -= gameRef.gameSpeed * dt;

        // Ekrandan çıktıysa kaldır
        if (position.x < -size.x) {
          removeFromParent();
        }
        break;
    }
  }

  // Oyuncu platformun üzerine bastığında çağrılır
  void playerLanded() {
    // Platform tipine göre davranış
    switch (platform.type) {
      case PlatformType.crumbling:
        // Çökme platformu oyuncu temas edince çökmeye başlar
        if (!isCrumbling) {
          isCrumbling = true;
          crumbleTime = platform.lifespan;
          // Çatlama efekti eklenebilir
        }
        break;

      case PlatformType.bouncy:
        // Zıplama efekti
        // Parçacık efekti veya ses efekti eklenebilir
        break;

      case PlatformType.hazardous:
        // Hasar verici platform
        // Zarar verme efekti eklenebilir
        break;

      default:
        // Diğer platformlar için standart davranış
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    // Arka plan
    final bgPaint = Paint()
      ..color = platform.color
      ..style = PaintingStyle.fill;

    // Platform kenarları için gradient
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          platform.color.withOpacity(0.8),
          platform.color.withOpacity(0.3),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    // Platform tipine göre özel render
    switch (platform.type) {
      case PlatformType.bouncy:
        // Zıplama platformu için yaylı görünüm
        final bouncyRect = Rect.fromLTWH(0, 0, size.x, size.y);
        canvas.drawRRect(
          RRect.fromRectAndRadius(bouncyRect, const Radius.circular(8)),
          bgPaint,
        );

        // Yay çizgileri
        final linePaint = Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..strokeWidth = 1.5;

        for (int i = 1; i < 5; i++) {
          canvas.drawLine(
            Offset(size.x * i / 5, 2),
            Offset(size.x * i / 5, size.y - 2),
            linePaint,
          );
        }
        break;

      case PlatformType.hazardous:
        // Tehlikeli platform için dikenli görünüm
        final hazardRect = Rect.fromLTWH(0, 0, size.x, size.y - 5);
        canvas.drawRect(hazardRect, bgPaint);

        // Dikenler
        final path = Path();
        final spikeCount = (size.x / 10).floor();
        final spikeWidth = size.x / spikeCount;

        for (int i = 0; i < spikeCount; i++) {
          path.moveTo(i * spikeWidth, size.y - 5);
          path.lineTo(i * spikeWidth + spikeWidth / 2, size.y);
          path.lineTo((i + 1) * spikeWidth, size.y - 5);
        }

        final spikePaint = Paint()
          ..color = Colors.red.shade700
          ..style = PaintingStyle.fill;

        canvas.drawPath(path, spikePaint);
        break;

      case PlatformType.crumbling:
        // Çöken platform için çatlak görünümü
        if (isCrumbling) {
          // Çatlak efekti
          final crackPaint = Paint()
            ..color = Colors.black.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;

          final crackSeverity = 1.0 - (crumbleTime / platform.lifespan);
          final path = Path();

          // Çatlaklar
          final random =
              math.Random(42); // Sabit seed ile her seferinde aynı çatlaklar

          for (int i = 0; i < 3 + (crackSeverity * 5).floor(); i++) {
            final startX = random.nextDouble() * size.x;
            path.moveTo(startX, 0);

            double currentX = startX;
            double currentY = 0;

            for (int j = 0; j < 5; j++) {
              currentX += (random.nextDouble() - 0.5) * 10 * crackSeverity;
              currentY += size.y / 5;
              path.lineTo(currentX, currentY);
            }
          }

          canvas.drawPath(path, crackPaint);
        }

        // Normal çizim
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.x, size.y),
          bgPaint,
        );
        break;

      default:
        // Normal platform
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.x, size.y),
          bgPaint,
        );

        // Kenar çizgisi
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.x, size.y),
          borderPaint,
        );

        // Üst kenar için daha parlak çizgi
        final topHighlight = Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        canvas.drawLine(
          const Offset(0, 0),
          Offset(size.x, 0),
          topHighlight,
        );
        break;
    }
  }
}
