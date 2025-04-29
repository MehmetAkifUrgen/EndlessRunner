import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_application_baris/presentation/pages/game_screen.dart'; // RunnerGame
import 'package:flutter_application_baris/domain/entities/character.dart'; // PlayerCharacter
import '../particles/particle_system.dart'; // ParticleSystem
import 'package:flutter_application_baris/services/audio_service.dart'; // AudioService ve SoundEffect
import '../obstacles/obstacle_component.dart'; // ObstacleComponent
import '../collectibles/collectible_component.dart'; // CollectibleComponent

class PlayerComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<RunnerGame> {
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
  bool visible = true;
  int playerDirection = 1; // Karakter yönü (1: sağ, -1: sol)
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
  final double minJumpVelocity = -500;
  final double maxJumpVelocity = -900;

  // Animasyon ve çizim değişkenleri
  late final Paint _paint;
  late final Paint _secondaryPaint;
  late final Paint _eyePaint;
  late final Paint _pupilPaint;
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

  // Yanıp sönme efekti için
  static const double blinkDuration = 0.1;
  static const int blinkCount = 10;
  bool isBlinking = false;
  double blinkTimer = 0;
  int currentBlink = 0;
  Color blinkEffectColor = Colors.white;
  bool _blinkVisible = true;

  PlayerComponent({
    required Vector2 position,
    required this.game,
    Color? color,
    Color? secondaryColor,
    this.character,
  })  : defaultColor = color ?? Colors.red,
        secondaryColor = secondaryColor ?? Colors.redAccent,
        super(
          position: position,
          size: Vector2(50, 70),
          anchor: Anchor.bottomCenter,
        ) {
    _paint = Paint()..color = defaultColor;
    _secondaryPaint = Paint()..color = this.secondaryColor;
    _eyePaint = Paint()..color = Colors.white;
    _pupilPaint = Paint()..color = Colors.black;

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
      anchor: Anchor.bottomCenter,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

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
          color: const Color(0x88CCCCCC),
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
        final dashPosition = Vector2(position.x + 5, position.y - size.y / 2);
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
          color: const Color(0x66CCCCCC),
        );
      }
    }

    // Yerdeyken scale'in 1 olduğundan emin ol
    if (isOnGround && scale != Vector2.all(1.0) && !isChargingJump) {
      scale = Vector2.all(1.0);
    }

    // Zıplama şarjı sırasında scale değişikliği
    if (isChargingJump) {
      final chargeRatio = jumpChargeDuration / maxChargeTime;
      scale = Vector2(1.0 - chargeRatio * 0.1, 1.0 + chargeRatio * 0.1);
    } else if (isOnGround && scale != Vector2.all(1.0)) {
      scale = Vector2.all(1.0);
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
        position.y = game.size.y - game.groundHeight; // Tam zemine oturt
        isOnGround = true;
        isJumping = false;
        isDoubleJumping = false;
        velocityY = 0;
        canDoubleJump = false; // Yere inince çift zıplama hakkı sıfırlanmalı
        if (scale != Vector2.all(1.0)) {
          scale = Vector2.all(1.0);
        }
      }
    } else {
      // Yerdeyken çift zıplama hakkı olmamalı
      if (canDoubleJump) canDoubleJump = false;
      if (isDoubleJumping) isDoubleJumping = false;
      if (isJumping) isJumping = false;
    }

    // Yanıp sönme efekti
    if (isBlinking) {
      blinkTimer += dt;
      if (blinkTimer >= blinkDuration) {
        blinkTimer = 0;
        currentBlink++;
        _blinkVisible = !_blinkVisible; // Görünürlüğü değiştir

        if (currentBlink >= blinkCount) {
          stopBlinking();
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;

    // Canvas üzerinde geçici transformasyon uygula
    canvas.save();

    // Karakter canvas'ının merkezine taşı
    canvas.translate(size.x / 2, size.y / 2);

    // Karakterin yönüne göre döndür
    if (playerDirection == -1) {
      canvas.scale(-1, 1);
    }

    // Kayma efekti uygula
    if (isSliding) {
      canvas.rotate(0.2);
    }

    // Dash efekti uygula
    if (isDashing) {
      final dashProgress = math.min(1.0, _dashTime / _dashDuration);
      final double dashScale = 1.0 + (0.3 * dashProgress);
      canvas.scale(dashScale, 1 / dashScale);
    }

    // Yanıp sönme efekti: Görünmez ise çizme
    if (isBlinking && !_blinkVisible) {
      // Yenilmezlik efekti ile çakışmaması için kontrol
      if (isInvincible && (_invincibilityTime * 10).floor() % 2 == 0) {
        // Hem blink hem invincible ise invincibility öncelikli (yani çizme)
      } else {
        canvas.restore(); // save() yapıldıysa restore et
        return; // Çizmeden çık
      }
    }

    // Yenilmezlik efekti
    if (isInvincible && (_invincibilityTime * 10).floor() % 2 == 0) {
      canvas.restore();
      return;
    }

    // Karakter ID'sine göre çiz, varsayılan olarak tavşan
    final characterId = game.selectedCharacter?.id ?? 'rabbit';

    switch (characterId) {
      case 'rabbit':
        _drawRabbit(canvas);
        break;
      case 'cheetah':
        _drawCheetah(canvas);
        break;
      case 'frog':
        _drawFrog(canvas);
        break;
      case 'fox':
        _drawFox(canvas);
        break;
      case 'eagle':
        _drawEagle(canvas);
        break;
      default:
        _drawDefaultShape(canvas);
        break;
    }

    // Çizim tamamlandı, transformasyonu geri al
    canvas.restore();
  }

  // Varsayılan şekil çizimi
  void _drawDefaultShape(Canvas canvas) {
    final rect = Rect.fromLTWH(-size.x / 2, -size.y / 2, size.x, size.y);
    canvas.drawRect(rect, _paint);
    // İkincil rengi kullanarak bir desen ekle
    final innerRect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x * 0.6,
      height: size.y * 0.6,
    );
    canvas.drawRect(innerRect, _secondaryPaint);
  }

  // Tavşan çizimi
  void _drawRabbit(Canvas canvas) {
    _drawRoundedRectCharacter(canvas, defaultColor, secondaryColor, 0.3);
  }

  // Çita çizimi
  void _drawCheetah(Canvas canvas) {
    _drawRoundedRectCharacter(canvas, defaultColor, secondaryColor, 0.4);
    // Çita için benek ekle
    final spotPaint = Paint()..color = Colors.black.withOpacity(0.7);
    final random = math.Random(1);
    for (int i = 0; i < 5; i++) {
      final spotX = (random.nextDouble() - 0.5) * size.x * 0.8;
      final spotY = (random.nextDouble() - 0.5) * size.y * 0.8;
      final spotRadius = 2 + random.nextDouble() * 2;
      canvas.drawCircle(Offset(spotX, spotY), spotRadius, spotPaint);
    }
  }

  // Kurbağa çizimi
  void _drawFrog(Canvas canvas) {
    _drawRoundedRectCharacter(canvas, defaultColor, secondaryColor, 0.5);
    // Kurbağa için büyük göz ekle
    final eyeRadius = size.x * 0.15;
    canvas.drawCircle(
        Offset(-size.x * 0.2, -size.y * 0.2), eyeRadius, _eyePaint);
    canvas.drawCircle(
        Offset(size.x * 0.2, -size.y * 0.2), eyeRadius, _eyePaint);
    canvas.drawCircle(
        Offset(-size.x * 0.2, -size.y * 0.2), eyeRadius * 0.5, _pupilPaint);
    canvas.drawCircle(
        Offset(size.x * 0.2, -size.y * 0.2), eyeRadius * 0.5, _pupilPaint);
  }

  // Tilki çizimi
  void _drawFox(Canvas canvas) {
    _drawRoundedRectCharacter(canvas, defaultColor, secondaryColor, 0.2);
    // Tilki için üçgen kulaklar ekle
    final earPaint = Paint()..color = defaultColor;
    final path = Path();
    path.moveTo(-size.x * 0.3, -size.y / 2);
    path.lineTo(-size.x * 0.1, -size.y / 2 - 15);
    path.lineTo(-size.x * 0.1, -size.y / 2);
    path.close();
    canvas.drawPath(path, earPaint);

    final path2 = Path();
    path2.moveTo(size.x * 0.3, -size.y / 2);
    path2.lineTo(size.x * 0.1, -size.y / 2 - 15);
    path2.lineTo(size.x * 0.1, -size.y / 2);
    path2.close();
    canvas.drawPath(path2, earPaint);
  }

  // Kartal çizimi
  void _drawEagle(Canvas canvas) {
    _drawRoundedRectCharacter(canvas, defaultColor, secondaryColor, 0.1);
    // Kartal için kanat benzeri şekil ekle
    final wingPaint = Paint()..color = secondaryColor;
    final path = Path();
    path.moveTo(-size.x / 2, -size.y * 0.1);
    path.quadraticBezierTo(
        -size.x * 0.8, size.y * 0.3, -size.x / 2, size.y * 0.7);
    path.close();
    canvas.drawPath(path, wingPaint);

    final path2 = Path();
    path2.moveTo(size.x / 2, -size.y * 0.1);
    path2.quadraticBezierTo(
        size.x * 0.8, size.y * 0.3, size.x / 2, size.y * 0.7);
    path2.close();
    canvas.drawPath(path2, wingPaint);
  }

  // Yuvarlatılmış dikdörtgen karakter çizimi için yardımcı metod
  void _drawRoundedRectCharacter(Canvas canvas, Color primary, Color secondary,
      double borderRadiusFactor) {
    final rect = Rect.fromLTWH(-size.x / 2, -size.y / 2, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.x * borderRadiusFactor),
    );
    _paint.color = primary;
    _secondaryPaint.color = secondary;

    canvas.drawRRect(rrect, _paint);

    // İç desen veya vurgu ekle
    final innerRect = Rect.fromCenter(
      center: Offset(0, size.y * 0.15),
      width: size.x * 0.7,
      height: size.y * 0.4,
    );
    final innerRRect = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(size.x * borderRadiusFactor * 0.5),
    );
    canvas.drawRRect(innerRRect, _secondaryPaint);

    // Göz ekle
    _drawEyes(canvas);
  }

  // Göz çizimi için yardımcı metod
  void _drawEyes(Canvas canvas) {
    final eyeRadius = size.x * 0.1;
    final pupilRadius = eyeRadius * 0.5;
    final eyeOffsetY = -size.y * 0.15;
    final eyeOffsetX = size.x * 0.18;

    canvas.drawCircle(Offset(-eyeOffsetX, eyeOffsetY), eyeRadius, _eyePaint);
    canvas.drawCircle(Offset(eyeOffsetX, eyeOffsetY), eyeRadius, _eyePaint);

    // Göz bebeği hareketini ekle (örneğin, aşağı bakma)
    final pupilOffsetY = eyeRadius * 0.2;
    canvas.drawCircle(Offset(-eyeOffsetX, eyeOffsetY + pupilOffsetY),
        pupilRadius, _pupilPaint);
    canvas.drawCircle(Offset(eyeOffsetX, eyeOffsetY + pupilOffsetY),
        pupilRadius, _pupilPaint);
  }

  // Zıplama işlemi
  void jump() {
    if (isOnGround) {
      // Normal zıplama
      final jumpVelocity = minJumpVelocity +
          (maxJumpVelocity - minJumpVelocity) *
              jumpChargeDuration /
              maxChargeTime;
      velocityY = jumpVelocity * jumpMultiplier;
      isOnGround = false;
      isJumping = true;
      canDoubleJump = true; // İlk zıplamadan sonra çift zıplama hakkı
      isChargingJump = false;
      jumpChargeDuration = 0;
      game.audioService.playSfx(SoundEffect.jump);
      game.particleSystem.createStars(position: position, color: defaultColor);
    } else if (canDoubleJump && !isDoubleJumping) {
      // Çift zıplama
      velocityY = minJumpVelocity * jumpMultiplier * 0.8; // Daha kısa zıplama
      isDoubleJumping = true;
      canDoubleJump = false; // Çift zıplama hakkı kullanıldı
      game.audioService.playSfx(SoundEffect.doubleJump);
      game.particleSystem
          .createExplosion(position: position, color: secondaryColor);
    }
  }

  // Zıplama için şarj başlat
  void startJumpCharge() {
    if (isOnGround) {
      isChargingJump = true;
      jumpChargeDuration = 0;
    }
  }

  // Zıplama şarjını güncelle
  void updateJumpCharge(double dt) {
    if (isChargingJump) {
      jumpChargeDuration += dt;
      if (jumpChargeDuration > maxChargeTime) {
        jumpChargeDuration = maxChargeTime;
      }
      // Şarj olurken görsel efekt eklenebilir (örneğin, scale)
      final chargeRatio = jumpChargeDuration / maxChargeTime;
      scale = Vector2(1.0 - chargeRatio * 0.1, 1.0 + chargeRatio * 0.1);
    }
  }

  // Zıplama şarjını bitir ve zıpla
  void releaseJumpCharge() {
    if (isChargingJump) {
      jump();
      scale = Vector2.all(1.0); // Ölçeği normale döndür
    }
  }

  // Kayma işlemi
  void slide() {
    if (!isSliding && isOnGround) {
      isSliding = true;
      _slideTime = 0;
      size = Vector2(50, 35); // Kayarken boyut küçülür
      game.audioService.playSfx(SoundEffect.slide);
    }
  }

  // Dash işlemi
  void dash() {
    if (!isDashing && dashCooldownRemaining <= 0) {
      isDashing = true;
      _dashTime = 0;
      dashCooldownRemaining = dashCooldown; // Bekleme süresini başlat
      game.audioService.playSfx(SoundEffect.dash);

      // Dash sırasında geçici hız artışı
      game.gameSpeed *= (1.5 * dashMultiplier);
      Future.delayed(Duration(milliseconds: (_dashDuration * 1000).toInt()),
          () {
        if (!isDashing) {
          // Dash bittiğinde hızı geri al
          game.gameSpeed /= (1.5 * dashMultiplier);
        }
      });
    }
  }

  // Çarpışma algılandığında
  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (isInvincible) {
      return;
    }

    if (other is ObstacleComponent) {
      if (game.hasShield) {
        game.hasShield = false;
        deactivateShieldEffect();
        other.removeFromParent();
        game.obstacles.remove(other);
        game.audioService.playSfx(SoundEffect.hit);
        game.particleSystem.createExplosion(
            position: other.position, color: Colors.blueAccent, count: 30);
      } else {
        hit();
        game.loseLife(); // Can azaltma fonksiyonunu çağır
      }
    } else if (other is CollectibleComponent) {
      game.collect(other);
    }
  }

  // Çarpma efekti
  void hit() {
    if (!isHit) {
      isHit = true;
      isInvincible = true; // Kısa süreli yenilmezlik
      _invincibilityTime = 0;

      // Hasar alınca parçalanma efekti
      game.audioService.playSfx(SoundEffect.hit);
      game.particleSystem
          .createExplosion(position: position, color: Colors.redAccent);
    }
  }

  // Görünürlüğü aç/kapat
  void toggleVisibility(bool isVisible) {
    visible = isVisible;
  }

  // Kalkan efektini aktifleştir
  void activateShieldEffect() {
    // Kalkan için görsel bir efekt eklenebilir
  }

  // Kalkan efektini devre dışı bırak
  void deactivateShieldEffect() {
    // Kalkan efektini kaldır
  }

  // Mıknatıs efektini aktifleştir
  void activateMagnetEffect() {
    // Mıknatıs için görsel efekt
  }

  // Mıknatıs efektini devre dışı bırak
  void deactivateMagnetEffect() {
    // Mıknatıs efektini kaldır
  }

  // Oyuncuyu resetle
  void reset() {
    position = Vector2(game.size.x * 0.1, game.size.y - game.groundHeight);
    velocityY = 0;
    isOnGround = true;
    isJumping = false;
    isDoubleJumping = false;
    canDoubleJump = false;
    isSliding = false;
    isDashing = false;
    isHit = false;
    isInvincible = false;
    scale = Vector2.all(1.0);
    dashCooldownRemaining = 0;
    stopBlinking(); // Yanıp sönmeyi durdur
    deactivateMagnetEffect();
    deactivateShieldEffect();
  }

  // Yanıp sönme efektini başlat
  void startBlinking(
      {double duration = blinkDuration * blinkCount,
      Color color = Colors.white}) {
    if (!isBlinking) {
      isBlinking = true;
      blinkTimer = 0;
      currentBlink = 0;
      _blinkVisible = true; // Başlangıçta görünür
      blinkEffectColor = color;
    }
  }

  // Yanıp sönme efektini durdur
  void stopBlinking() {
    isBlinking = false;
    _blinkVisible = true; // Efekt bitince görünür yap
  }
}
