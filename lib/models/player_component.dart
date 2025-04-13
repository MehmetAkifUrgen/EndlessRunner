import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../screens/game_screen.dart';

class PlayerComponent extends PositionComponent with CollisionCallbacks {
  // Oyuncu özellikleri
  final RunnerGame game;
  Color defaultColor;
  bool isOnGround = false;
  bool isJumping = false;
  bool isDoubleJumping = false;
  bool canDoubleJump = false;
  bool isSliding = false;
  bool isDashing = false;
  bool isHit = false;
  bool isInvincible = false;
  double velocityY = 0;

  // Zıplama özellikleri
  bool isChargingJump = false;
  double jumpChargeDuration = 0;
  final double maxChargeTime = 0.5;
  final double minJumpVelocity = -300;
  final double maxJumpVelocity = -600;

  // Animasyon ve çizim değişkenleri
  late final Paint _paint;
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
  })  : defaultColor = color ?? Colors.red,
        super(position: position, size: Vector2(30, 50)) {
    _paint = Paint()..color = defaultColor;

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
      if (_slideTime >= _slideDuration) {
        isSliding = false;
        _slideTime = 0;
        size = Vector2(30, 50);
      }
    }

    // Dash animasyonu
    if (isDashing) {
      _dashTime += dt;
      if (_dashTime >= _dashDuration) {
        isDashing = false;
        _dashTime = 0;
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
      canvas.drawCircle(Offset(width / 2, height / 2),
          math.max(width, height) * 0.8, shieldPaint);
    }

    super.render(canvas);
  }

  // Zıplama şarjı başlat
  void startJumpCharge() {
    if (isOnGround && !isSliding) {
      isChargingJump = true;
      jumpChargeDuration = 0;
    }
  }

  // Zıplama yap
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
        velocityY = minJumpVelocity +
            (maxJumpVelocity - minJumpVelocity) * chargePercent;

        scale = Vector2.all(1);
        jumpChargeDuration = 0;
      } else if (canDoubleJump) {
        // Çift zıplama
        isDoubleJumping = true;
        canDoubleJump = false;

        // Çift zıplama daha zayıf olsun
        velocityY = minJumpVelocity * 0.8;
      }
    }
  }

  // Kayma hareketi
  void slide() {
    if (isOnGround && !isSliding && !isChargingJump) {
      isSliding = true;
      _slideTime = 0;

      // Kayarken çarpışma kutusunu değiştir
      size = Vector2(40, 20);
    }
  }

  // Dash hareketi
  void dash() {
    if (!isDashing && dashCooldownRemaining <= 0) {
      isDashing = true;
      _dashTime = 0;
      dashCooldownRemaining = dashCooldown;

      // Dash sırasında kısa süreli dokunulmazlık
      isInvincible = true;
      _invincibilityTime = 0;
    }
  }
}
