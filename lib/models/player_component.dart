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
  bool visible = true; // Görünürlük kontrolü için
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
        super(position: position, size: Vector2(50, 70)) {
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
    // BURAYA DİKKAT! TEST LOGU
    print('***** RENDER METODU ÇALIŞIYOR *****');

    // Render metodunun çağrıldığını ve görünürlük durumunu logla
    print('Render called. Visible: $visible');

    if (!visible) return;

    // Görünürlük dikdörtgeni çiz
    final Rect visibilityRect = Rect.fromLTWH(0, 0, size.x, size.y);

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

    // Yenilmezlik efekti
    if (isInvincible && (_invincibilityTime * 10).floor() % 2 == 0) {
      // Yanıp sönme efekti, hiçbir şey çizme
      canvas.restore();
      return;
    }

    // Karakter ID'sine göre çiz, varsayılan olarak tavşan
    final characterId = game.selectedCharacter?.id ?? 'rabbit';

    // Hangi karakterin çizildiğini daha detaylı logla
    print(
        'Selected character ID: $characterId, Game Object: ${game.selectedCharacter}');
    print('Character attributes: ${character?.attributes}');

    switch (characterId) {
      case 'rabbit':
        print('Drawing Rabbit...');
        _drawRabbit(canvas);
        break;
      case 'cheetah':
        print('Drawing Cheetah...');
        _drawCheetah(canvas);
        break;
      case 'frog':
        print('Drawing Frog...');
        _drawFrog(canvas);
        break;
      case 'fox':
        print('Drawing Fox...');
        _drawFox(canvas);
        break;
      case 'eagle':
        print('Drawing Eagle...');
        _drawEagle(canvas);
        break;
      default:
        print('Drawing Default (Rabbit)...');
        _drawRabbit(canvas); // Varsayılan
    }

    // Canvas'ı eski haline getir
    canvas.restore();
  }

  // Tavşan karakterini çiz (Test için parlak kırmızı dikdörtgen)
  void _drawRabbit(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;

    // Çok dikkat çekici parlak kırmızı renk
    final testPaint = Paint()
      ..color = Colors.red.shade700
      ..style = PaintingStyle.fill;

    // Tüm karakter alanını kaplayan büyük bir dikdörtgen
    canvas.drawRect(
      Rect.fromLTWH(-w / 2, -h / 2, w, h),
      testPaint,
    );

    // Kenar çizgisi ekleyelim ki sınırları belli olsun
    final borderPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(
      Rect.fromLTWH(-w / 2, -h / 2, w, h),
      borderPaint,
    );

    // İçine yazı ekleyelim
    final textSpan = TextSpan(
      text: 'TAVŞAN',
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }

  // Çita karakterini çiz (Yeniden Düzenlendi)
  void _drawCheetah(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;
    final bodyPaint = Paint()..color = Colors.amber.shade600; // Sarımsı kahve
    final bellyPaint = Paint()..color = Colors.amber.shade100; // Açık karın
    final spotPaint = Paint()..color = Colors.black87; // Siyah benekler
    final eyePaint = Paint()..color = Colors.black;
    final nosePaint = Paint()..color = Colors.black;

    // Vücut (uzunlamasına oval)
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.6), width: w * 0.8, height: h * 0.5),
      bodyPaint,
    );
    // Karın
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.65), width: w * 0.7, height: h * 0.3),
      bellyPaint,
    );

    // Baş
    canvas.drawCircle(Offset(w * 0.75, h * 0.4), w * 0.2, bodyPaint);

    // Kulaklar (yuvarlak)
    canvas.drawCircle(Offset(w * 0.68, h * 0.28), w * 0.08, bodyPaint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.28), w * 0.08, bodyPaint);

    // Kuyruk (uzun ve ince)
    final tailPath = Path()
      ..moveTo(w * 0.2, h * 0.6)
      ..quadraticBezierTo(w * 0.05, h * 0.7, w * 0.1, h * 0.9)
      ..lineTo(w * 0.15, h * 0.85)
      ..quadraticBezierTo(w * 0.1, h * 0.7, w * 0.22, h * 0.65)
      ..close();
    canvas.drawPath(tailPath, bodyPaint);

    // Bacaklar
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.6, h * 0.75, w * 0.15, h * 0.25),
            Radius.circular(5)),
        bodyPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.45, h * 0.75, w * 0.15, h * 0.25),
            Radius.circular(5)),
        bodyPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.3, h * 0.75, w * 0.15, h * 0.25),
            Radius.circular(5)),
        bodyPaint);

    // Gözler
    canvas.drawCircle(Offset(w * 0.7, h * 0.4), w * 0.05, eyePaint);
    canvas.drawCircle(Offset(w * 0.8, h * 0.4), w * 0.05, eyePaint);

    // Burun
    canvas.drawCircle(Offset(w * 0.8, h * 0.45), w * 0.04, nosePaint);

    // Benekler
    for (int i = 0; i < 15; i++) {
      final x = w * 0.2 + math.Random().nextDouble() * w * 0.6;
      final y = h * 0.4 + math.Random().nextDouble() * h * 0.4;
      final radius = w * 0.02 + math.Random().nextDouble() * w * 0.01;
      canvas.drawCircle(Offset(x, y), radius, spotPaint);
    }
  }

  // Kurbağa karakterini çiz (Yeniden Düzenlendi)
  void _drawFrog(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;
    final bodyPaint = Paint()..color = Colors.green.shade500;
    final bellyPaint = Paint()..color = Colors.lightGreen.shade100;
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = Colors.black;

    // Vücut (geniş oval)
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.65), width: w * 0.8, height: h * 0.6),
      bodyPaint,
    );
    // Karın
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.7), width: w * 0.6, height: h * 0.4),
      bellyPaint,
    );

    // Baş (vücudun üstünde)
    canvas.drawCircle(Offset(w * 0.5, h * 0.4), w * 0.3, bodyPaint);

    // Gözler (büyük ve üstte)
    final eyeRadius = w * 0.15;
    canvas.drawCircle(Offset(w * 0.35, h * 0.25), eyeRadius, bodyPaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.25), eyeRadius, bodyPaint);
    canvas.drawCircle(Offset(w * 0.35, h * 0.25), eyeRadius * 0.8, eyePaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.25), eyeRadius * 0.8, eyePaint);
    canvas.drawCircle(Offset(w * 0.35, h * 0.25), eyeRadius * 0.4, pupilPaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.25), eyeRadius * 0.4, pupilPaint);

    // Ağız (geniş gülümseme)
    final mouthPath = Path()
      ..moveTo(w * 0.3, h * 0.45)
      ..quadraticBezierTo(w * 0.5, h * 0.55, w * 0.7, h * 0.45);
    canvas.drawPath(
        mouthPath,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Bacaklar (yana doğru)
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.2, h * 0.8), width: w * 0.3, height: h * 0.2),
        bodyPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.8, h * 0.8), width: w * 0.3, height: h * 0.2),
        bodyPaint);
  }

  // Tilki karakterini çiz (Yeniden Düzenlendi)
  void _drawFox(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;
    final bodyPaint = Paint()..color = Colors.orange.shade800;
    final bellyPaint = Paint()..color = Colors.white;
    final earInnerPaint = Paint()..color = Colors.pink.shade100;
    final tailTipPaint = Paint()..color = Colors.white;
    final eyePaint = Paint()..color = Colors.black;
    final nosePaint = Paint()..color = Colors.black;

    // Vücut
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.6), width: w * 0.7, height: h * 0.6),
      bodyPaint,
    );
    // Karın
    final bellyPath = Path()
      ..moveTo(w * 0.5, h * 0.4)
      ..quadraticBezierTo(w * 0.3, h * 0.6, w * 0.5, h * 0.8)
      ..quadraticBezierTo(w * 0.7, h * 0.6, w * 0.5, h * 0.4)
      ..close();
    canvas.drawPath(bellyPath, bellyPaint);

    // Baş (üçgenimsi)
    final headPath = Path()
      ..moveTo(w * 0.5, h * 0.15)
      ..lineTo(w * 0.3, h * 0.45)
      ..lineTo(w * 0.7, h * 0.45)
      ..close();
    canvas.drawPath(headPath, bodyPaint);

    // Kulaklar (sivri üçgen)
    final earHeight = h * 0.25;
    final earWidth = w * 0.18;
    final leftEar = Path()
      ..moveTo(w * 0.3, h * 0.3)
      ..lineTo(w * 0.2, h * 0.1)
      ..lineTo(w * 0.4, h * 0.2)
      ..close();
    final rightEar = Path()
      ..moveTo(w * 0.7, h * 0.3)
      ..lineTo(w * 0.8, h * 0.1)
      ..lineTo(w * 0.6, h * 0.2)
      ..close();
    canvas.drawPath(leftEar, bodyPaint);
    canvas.drawPath(rightEar, bodyPaint);
    // Kulak içleri
    // ... (İsteğe bağlı, daha basit tutulabilir)

    // Kuyruk (kabarık, beyaz uçlu)
    final tailBase = Offset(w * 0.2, h * 0.7);
    final tailPath = Path()
      ..moveTo(tailBase.dx, tailBase.dy)
      ..quadraticBezierTo(w * 0.05, h * 0.9, w * 0.15, h * 1.1) // Alt kıvrım
      ..quadraticBezierTo(w * 0.3, h * 1.15, w * 0.3, h * 0.9) // Üst kıvrım
      ..quadraticBezierTo(w * 0.25, h * 0.8, tailBase.dx, tailBase.dy)
      ..close();
    canvas.drawPath(tailPath, bodyPaint);
    // Kuyruk ucu
    canvas.drawCircle(Offset(w * 0.15, h * 1.05), w * 0.1, tailTipPaint);

    // Bacaklar
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.6, h * 0.8, w * 0.15, h * 0.2),
            Radius.circular(5)),
        bodyPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.4, h * 0.8, w * 0.15, h * 0.2),
            Radius.circular(5)),
        bodyPaint);

    // Gözler
    canvas.drawCircle(Offset(w * 0.4, h * 0.3), w * 0.05, eyePaint);
    canvas.drawCircle(Offset(w * 0.6, h * 0.3), w * 0.05, eyePaint);

    // Burun
    canvas.drawCircle(Offset(w * 0.5, h * 0.38), w * 0.04, nosePaint);
  }

  // Kartal karakterini çiz (Yeniden Düzenlendi)
  void _drawEagle(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;
    final bodyPaint = Paint()..color = Colors.brown.shade700;
    final headPaint = Paint()..color = Colors.white;
    final beakPaint = Paint()..color = Colors.amber.shade700;
    final eyePaint = Paint()..color = Colors.black;

    // Kanatlar (geniş)
    final wingPath = Path()
      ..moveTo(w * 0.1, h * 0.5)
      ..quadraticBezierTo(w * 0.5, h * 0.1, w * 0.9, h * 0.5) // Üst yay
      ..quadraticBezierTo(w * 0.7, h * 0.8, w * 0.5, h * 0.9) // Alt orta
      ..quadraticBezierTo(w * 0.3, h * 0.8, w * 0.1, h * 0.5)
      ..close();
    canvas.drawPath(wingPath, bodyPaint);

    // Vücut (kanatların altında)
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.7), width: w * 0.4, height: h * 0.5),
      bodyPaint,
    );

    // Baş (beyaz)
    canvas.drawCircle(Offset(w * 0.5, h * 0.35), w * 0.25, headPaint);

    // Gaga (sarı, kancalı)
    final beakPath = Path()
      ..moveTo(w * 0.5, h * 0.4)
      ..lineTo(w * 0.6, h * 0.45)
      ..lineTo(w * 0.55, h * 0.5)
      ..lineTo(w * 0.5, h * 0.4)
      ..close();
    canvas.drawPath(beakPath, beakPaint);

    // Gözler
    canvas.drawCircle(Offset(w * 0.43, h * 0.35), w * 0.04, eyePaint);
    canvas.drawCircle(Offset(w * 0.57, h * 0.35), w * 0.04, eyePaint);

    // Bacaklar/Pençeler (basit)
    canvas.drawRect(
        Rect.fromLTWH(w * 0.4, h * 0.9, w * 0.05, h * 0.1), beakPaint);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.55, h * 0.9, w * 0.05, h * 0.1), beakPaint);
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
