import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../screens/game_screen.dart';
import 'character.dart';

class PlayerComponent extends PositionComponent with CollisionCallbacks {
  // Oyuncu özellikleri
  final RunnerGame game;
  final PlayerCharacter? character;
  Color defaultColor;
  Color secondaryColor;
  bool isOnGround = false;
  bool isJumping = false;
  bool isDoubleJumping = false;
  bool canDoubleJump = false;
  bool isSliding = false;
  bool isDashing = false;
  bool isHit = false;
  bool isInvincible = false;
  double velocityY = 0;

  // Karakter özellikleri
  double jumpMultiplier = 1.0;
  double speedMultiplier = 1.0;
  double dashMultiplier = 1.0;
  double coinMultiplier = 1.0;

  // Zıplama özellikleri
  bool isChargingJump = false;
  double jumpChargeDuration = 0;
  final double maxChargeTime = 0.5;
  final double minJumpVelocity = -300;
  final double maxJumpVelocity = -600;

  // Animasyon ve çizim değişkenleri
  late final Paint _paint;
  late final Paint _secondaryPaint;
  double _hitAnimationTime = 0;
  double _slideTime = 0;
  final double _slideDuration = 0.5;
  double _dashTime = 0;
  final double _dashDuration = 0.5;
  double _invincibilityTime = 0;

  // Fizik sabitleri
  final double gravity = 1200;
  final double dashCooldown = 2.0;
  double dashCooldownRemaining = 0;

  PlayerComponent({
    required Vector2 position,
    required this.game,
    Color? color,
    Color? secondaryColor,
    this.character,
  })  : defaultColor = color ?? Colors.red,
        secondaryColor = secondaryColor ?? Colors.redAccent,
        super(position: position, size: Vector2(30, 50)) {
    _paint = Paint()..color = defaultColor;
    _secondaryPaint = Paint()..color = this.secondaryColor;

    // Karaktere göre özellikleri ayarla
    if (character != null) {
      jumpMultiplier = character!.attributes['jumpPower'] ?? 1.0;
      speedMultiplier = character!.attributes['speed'] ?? 1.0;
      dashMultiplier = character!.attributes['dashPower'] ?? 1.0;
      coinMultiplier = character!.attributes['coinBonus'] ?? 1.0;
    }

    // Çarpışma kutusunu ekle
    add(RectangleHitbox.relative(
      Vector2(0.8, 0.9),
      parentSize: size,
      position: Vector2(size.x * 0.1, size.y * 0.1),
    ));
  }

  @override
  void update(double dt) {
    // Çarpışma animasyonu
    if (isHit) {
      _hitAnimationTime += dt;
      if (_hitAnimationTime >= 0.3) {
        isHit = false;
        _hitAnimationTime = 0;
        scale = Vector2.all(1);
      }
    }

    // Kayma animasyonu
    if (isSliding) {
      _slideTime += dt;

      // Kayma sırasında toz parçacıkları oluştur
      if (_slideTime < _slideDuration) {
        final slidePosition = Vector2(position.x, position.y);
        game.particleSystem.createRunningDust(
          position: slidePosition,
          count: 1,
          speed: 10,
          size: 5,
          lifespan: 0.4,
          color: Color(0x88CCCCCC),
        );
      }

      if (_slideTime >= _slideDuration) {
        isSliding = false;
        _slideTime = 0;
        size = Vector2(30, 50);
      }
    }

    // Dash animasyonu
    if (isDashing) {
      _dashTime += dt;

      // Dash sırasında hız çizgisi parçacıkları
      if (_dashTime < _dashDuration) {
        final dashPosition = Vector2(position.x + 5, position.y - height / 2);
        game.particleSystem.createRunningDust(
          position: dashPosition,
          count: 2,
          speed: 50,
          size: 8,
          lifespan: 0.3,
          color: Colors.white.withOpacity(0.6),
        );
      }

      if (_dashTime >= _dashDuration) {
        isDashing = false;
        _dashTime = 0;
      }
    }

    // Koşma animasyonu için ayak izi parçacıkları
    if (isOnGround && !isSliding && !isDashing) {
      // Her 0.3 saniyede bir koşma parçacığı ekle
      if ((game.gameTime * 5).floor() % 3 == 0) {
        final runPosition = Vector2(position.x + 5, position.y);
        game.particleSystem.createRunningDust(
          position: runPosition,
          count: 1,
          speed: 15,
          size: 3,
          lifespan: 0.5,
          color: Color(0x66CCCCCC),
        );
      }
    }

    // Dash bekleme süresi
    if (dashCooldownRemaining > 0) {
      dashCooldownRemaining -= dt;
    }

    // Dokunulmazlık süresi
    if (isInvincible && !game.hasShield) {
      _invincibilityTime += dt;
      if (_invincibilityTime >= 1.5) {
        isInvincible = false;
        _invincibilityTime = 0;
      }
    }

    // Yerçekimi uygula
    if (!isOnGround) {
      velocityY += gravity * dt;
      position.y += velocityY * dt;

      // Zeminde mi kontrol et
      if (position.y >= game.size.y - game.groundHeight) {
        position.y = game.size.y - game.groundHeight;
        if (velocityY > 0) {
          // Yere indiğinde durumu sıfırla
          isOnGround = true;
          isJumping = false;
          isDoubleJumping = false;
          velocityY = 0;
        }
      }
    }

    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    // Temel oyuncu çizimi
    if (isSliding) {
      // Kayma durumunda daha kısa ve geniş
      final rect = Rect.fromLTWH(0, height - 20, width, 20);
      canvas.drawRect(rect, _paint);
    } else {
      // Normal durumda
      final rect = Rect.fromLTWH(0, 0, width, height);
      canvas.drawRect(rect, _paint);

      // Yüz detayları
      final eyeSize = width * 0.2;
      final eyeY = height * 0.2;

      // Göz çizimi
      final leftEyePaint = Paint()..color = Colors.white;
      final rightEyePaint = Paint()..color = Colors.white;

      // Göz bebekleri - koşma yönüne bakacak şekilde
      final leftPupilPaint = Paint()..color = Colors.black;
      final rightPupilPaint = Paint()..color = Colors.black;

      // Gözleri çiz
      canvas.drawCircle(Offset(width * 0.3, eyeY), eyeSize, leftEyePaint);
      canvas.drawCircle(Offset(width * 0.7, eyeY), eyeSize, rightEyePaint);

      // Göz bebeklerini çiz - dash sırasında yana, zıplarken yukarı baksın
      double pupilOffsetX = 0;
      double pupilOffsetY = 0;

      if (isDashing) {
        pupilOffsetX = eyeSize * 0.3;
      } else if (isJumping || !isOnGround) {
        pupilOffsetY = -eyeSize * 0.3;
      }

      canvas.drawCircle(Offset(width * 0.3 + pupilOffsetX, eyeY + pupilOffsetY),
          eyeSize * 0.5, leftPupilPaint);
      canvas.drawCircle(Offset(width * 0.7 + pupilOffsetX, eyeY + pupilOffsetY),
          eyeSize * 0.5, rightPupilPaint);

      // Karakter tipi detayları - karakterin ikincil rengini kullan
      // Örnek: kafa bandı, kıyafet detayları vs.
      if (character != null) {
        // Kafa bandı çiz - karakterin ID'sine göre farklı şekiller
        switch (character!.id) {
          case 'speedy':
            // Hızlı karakter - akış çizgileri
            final linePaint = Paint()
              ..color = secondaryColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2;

            canvas.drawLine(Offset(0, height * 0.4),
                Offset(width * 0.8, height * 0.4), linePaint);
            break;

          case 'jumper':
            // Zıplayan karakter - yay şeklinde kafa bandı
            final headbandPaint = Paint()..color = secondaryColor;
            canvas.drawRect(
                Rect.fromLTWH(
                    width * 0.1, height * 0.05, width * 0.8, height * 0.08),
                headbandPaint);
            break;

          case 'dasher':
            // Dash uzmanı - omuz parçası
            final shoulderPaint = Paint()..color = secondaryColor;
            canvas.drawRect(
                Rect.fromLTWH(
                    width * 0.6, height * 0.3, width * 0.4, height * 0.15),
                shoulderPaint);
            break;

          case 'golden':
            // VIP karakter - altın taç
            final crownPaint = Paint()..color = secondaryColor;

            final crown = Path();
            // Taç taban kısmı
            crown.moveTo(width * 0.2, height * 0.05);
            crown.lineTo(width * 0.8, height * 0.05);
            crown.lineTo(width * 0.7, height * 0.15);
            crown.lineTo(width * 0.3, height * 0.15);
            crown.close();

            // Taç uçları
            crown.moveTo(width * 0.3, height * 0.05);
            crown.lineTo(width * 0.4, height * -0.05);
            crown.lineTo(width * 0.5, height * 0.05);
            crown.moveTo(width * 0.5, height * 0.05);
            crown.lineTo(width * 0.6, height * -0.05);
            crown.lineTo(width * 0.7, height * 0.05);

            canvas.drawPath(crown, crownPaint);
            break;

          default:
            // Standart karakter - basit kemer
            final beltPaint = Paint()..color = secondaryColor;
            canvas.drawRect(
                Rect.fromLTWH(0, height * 0.6, width, height * 0.05),
                beltPaint);
        }
      }

      // Ağız çizimi - duruma göre değişsin
      final mouthPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final mouth = Path();
      if (isJumping || !isOnGround) {
        // Zıplarken "O" şeklinde ağız
        mouth.addOval(Rect.fromCenter(
          center: Offset(width * 0.5, height * 0.6),
          width: width * 0.3,
          height: width * 0.3,
        ));
      } else if (isDashing) {
        // Dash yaparken "gülümseyen" ağız
        mouth.moveTo(width * 0.3, height * 0.6);
        mouth.quadraticBezierTo(
            width * 0.5, height * 0.7, width * 0.7, height * 0.6);
      } else {
        // Normal koşarken "düz" ağız
        mouth.moveTo(width * 0.3, height * 0.6);
        mouth.lineTo(width * 0.7, height * 0.6);
      }
      canvas.drawPath(mouth, mouthPaint);
    }

    // Dash efekti
    if (isDashing) {
      // Arkada hareket çizgileri
      final dashPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (int i = 1; i <= 3; i++) {
        final line = Path();
        line.moveTo(-i * 10, height * 0.2);
        line.lineTo(-i * 5, height * 0.5);
        line.lineTo(-i * 10, height * 0.8);
        canvas.drawPath(line, dashPaint);
      }
    }

    // Dokunulmazlık efekti
    if (isInvincible) {
      final shieldPaint = Paint()
        ..color = Colors.blueAccent.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      // Etrafında parlayan bir daire
      canvas.drawCircle(
        Offset(width / 2, height / 2),
        math.max(width, height) * 0.7,
        shieldPaint,
      );
    }

    // Çarpışma animasyonu
    if (isHit) {
      // Kırmızıya döner
      _paint.color = Colors.red;
    } else {
      // Normal renge dön
      _paint.color = defaultColor;
    }
  }

  void startJumpCharge() {
    if (isOnGround && !isJumping && !isSliding) {
      isChargingJump = true;
      jumpChargeDuration = 0; // Şarj süresini sıfırla

      // Basılı tutulduğunda bir görsel geri bildirim için boyutu değiştir
      scale = Vector2(1.1, 0.9); // Hafif basılmış görünüm
    } else if (!isOnGround && canDoubleJump && !isSliding) {
      // Havadayken çift zıplama
      doubleJump();
    }
  }

  void executeJump() {
    if (isChargingJump) {
      isChargingJump = false;

      if (isOnGround) {
        // Normal zıplama
        isJumping = true;
        isOnGround = false;
        canDoubleJump = true;

        // Şarj edilen zıplama gücüne göre
        final chargePercent =
            (jumpChargeDuration / maxChargeTime).clamp(0.0, 1.0);
        // Karakter özelliklerine göre zıplama gücünü ayarla
        velocityY = minJumpVelocity +
            (maxJumpVelocity - minJumpVelocity) *
                chargePercent *
                jumpMultiplier;

        // Zıplama parçacık efekti
        final jumpPosition = Vector2(position.x + width / 2, position.y);
        game.particleSystem.createSmoke(
          position: jumpPosition,
          count: 8,
          speed: 40 + chargePercent * 40,
          size: 10 + chargePercent * 10,
          lifespan: 0.6 + chargePercent * 0.4,
          color: Colors.grey.shade300,
        );

        scale = Vector2.all(1);
        jumpChargeDuration = 0;
      } else if (canDoubleJump) {
        doubleJump();
      }
    }
  }

  void doubleJump() {
    // Çift zıplama
    isDoubleJumping = true;
    canDoubleJump = false;

    // Çift zıplama daha zayıf olsun - yine de karakter özelliklerine göre
    velocityY = minJumpVelocity * 0.8 * jumpMultiplier;

    // Çift zıplama parçacık efekti - daha renkli
    final doubleJumpPosition =
        Vector2(position.x + width / 2, position.y - height / 2);
    game.particleSystem.createStars(
      position: doubleJumpPosition,
      color: Colors.amber,
      count: 12,
      speed: 150,
      size: 6,
      lifespan: 0.8,
    );
  }

  // Kayma hareketi
  void slide() {
    if (isOnGround && !isSliding && !isChargingJump) {
      isSliding = true;
      _slideTime = 0;

      // Kayma başlangıç parçacık efekti
      final slideStartPosition =
          Vector2(position.x + width / 2, position.y - 5);
      game.particleSystem.createRunningDust(
        position: slideStartPosition,
        count: 8,
        speed: 40,
        size: 8,
        lifespan: 0.6,
        color: Colors.grey.shade400,
      );

      // Kayarken çarpışma kutusunu değiştir
      size = Vector2(40, 20);
    }
  }

  // Dash hareketi
  void dash() {
    if (!isDashing && dashCooldownRemaining <= 0) {
      isDashing = true;
      _dashTime = 0;
      // Karakter özelliklerine göre dash bekleme süresini ayarla
      dashCooldownRemaining = dashCooldown / dashMultiplier;

      // Dash başlangıç parçacık efekti
      final dashStartPosition =
          Vector2(position.x + width / 2, position.y - height / 2);
      game.particleSystem.createExplosion(
        position: dashStartPosition,
        color: Colors.lightBlueAccent.withOpacity(0.7),
        count: 20,
        speed: 200,
        size: 4,
        lifespan: 0.5,
      );

      // Dash sırasında kısa süreli dokunulmazlık
      isInvincible = true;
      _invincibilityTime = 0;
    }
  }

  // Para toplama çarpanını getir - altın bonus özelliği için
  double getCoinMultiplier() {
    return coinMultiplier;
  }

  // Hız çarpanını getir
  double getSpeedMultiplier() {
    return speedMultiplier;
  }
}
