import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../domain/entities/character.dart';
import '../../../domain/entities/weapon.dart';
import '../../../domain/entities/platform.dart';
import '../../pages/game_screen.dart';
import 'bullet_component.dart';
import '../enemies/enemy_component.dart';
import '../platforms/platform_component.dart';
import '../obstacles/obstacle_component.dart';
import '../collectibles/collectible_component.dart';

enum PlayerState {
  running,
  jumping,
  doubleJumping,
  sliding,
  dashing,
  falling,
  shooting,
  hit,
  dead
}

class HumanPlayerComponent extends PositionComponent
    with HasGameRef<RunnerGame>, CollisionCallbacks {
  // Karakter özellikleri
  final PlayerCharacter character;
  final Color primaryColor;
  final Color secondaryColor;

  // Hareket değişkenleri
  double gravity = 1500;
  double jumpVelocity = -600;
  double doubleJumpVelocity = -550;
  double verticalVelocity = 0;
  double dashDistance = 200;
  double dashDuration = 0.2;
  double dashCooldown = 0.5;
  double slideDuration = 0.5;
  double slideTimer = 0;
  double dashTimer = 0;
  double dashCooldownTimer = 0;

  // Durum değişkenleri
  bool isJumping = false;
  bool hasDoubleJumped = false;
  bool isDashing = false;
  bool isSliding = false;
  bool isOnGround = true;
  bool isInvulnerable = false;
  double invulnerabilityTimer = 0;
  double hitAnimationTimer = 0;
  double groundLevel;

  // Silah ve mermi sistemi
  Weapon currentWeapon;
  final AmmoSystem ammoSystem;
  double fireRateTimer = 0;
  bool isReloading = false;
  double reloadTimer = 0;
  bool isPoweredUp = false;
  double poweredUpTimer = 0;

  // Kılıç sallama değişkenleri
  bool isSwingingBlade = false;
  double swingAngle = 0.0;
  double swingDuration = 0.3; // Saniye cinsinden kılıç sallama süresi
  double swingTimer = 0.0;
  double swingRange = 70.0; // Kılıcın menzili

  // Oyun durumu
  PlayerState state = PlayerState.running;

  // Silah güçlendirme metodu
  void powerUpWeapon(double duration) {
    if (duration <= 0) {
      isPoweredUp = false;
    } else {
      isPoweredUp = true;
      poweredUpTimer = duration;
    }
  }

  HumanPlayerComponent({
    required Vector2 position,
    required this.character,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.lightBlue,
    required double groundHeight,
    Weapon? weapon,
  })  : groundLevel = position.y,
        currentWeapon = weapon ?? Weapon.fromType(WeaponType.pistol),
        ammoSystem = AmmoSystem(maxAmmo: 50, startingAmmo: 30),
        super(
          position: position,
          size: Vector2(50, 80),
          anchor: Anchor.bottomCenter,
        );

  @override
  Future<void> onLoad() async {
    // Çarpışma kutusu ekle
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Oyun durmuşsa güncelleme yapma
    if (gameRef.isPaused || gameRef.isGameOver) return;

    // Kılıç sallama animasyonunu güncelle
    if (isSwingingBlade) {
      swingTimer += dt;
      // Sallama animasyonu için açı hesapla (0'dan 180 dereceye)
      swingAngle = math.pi * (swingTimer / swingDuration);

      // Sallama bittiğinde sıfırla
      if (swingTimer >= swingDuration) {
        isSwingingBlade = false;
        swingTimer = 0.0;
        swingAngle = 0.0;
      }

      // Kılıç sallarken çarpışma kontrolü yap
      _checkBladeCollision();
    }

    // Zamanla güçlendirilmiş mermi durumunu güncelle
    if (isPoweredUp) {
      poweredUpTimer -= dt;
      if (poweredUpTimer <= 0) {
        isPoweredUp = false;
      }
    }

    // Vurulma animasyonunu güncelle
    if (hitAnimationTimer > 0) {
      hitAnimationTimer -= dt;
    }

    // Dokunulmazlık süresini güncelle
    if (isInvulnerable) {
      invulnerabilityTimer -= dt;
      if (invulnerabilityTimer <= 0) {
        isInvulnerable = false;
      }
    }

    // Dash zamanlayıcısını güncelle
    if (dashTimer > 0) {
      dashTimer -= dt;
      if (dashTimer <= 0) {
        isDashing = false;
      }
    }

    // Dash bekleme süresini güncelle
    if (dashCooldownTimer > 0) {
      dashCooldownTimer -= dt;
    }

    // Kayma zamanlayıcısını güncelle
    if (slideTimer > 0) {
      slideTimer -= dt;
      if (slideTimer <= 0) {
        isSliding = false;
        size.y = 80; // Normal boyuta geri dön
        position.y = groundLevel; // Yerden doğru yüksekliğe ayarla
      }
    }

    // Ateş etme hızı zamanlayıcısını güncelle
    if (fireRateTimer > 0) {
      fireRateTimer -= dt;
    }

    // Silah yeniden yükleme zamanlayıcısını güncelle
    if (isReloading) {
      reloadTimer -= dt;
      if (reloadTimer <= 0) {
        isReloading = false;
        // Silah yeniden dolduğunda mermi ekle
        ammoSystem.reload(currentWeapon.ammoCapacity);
      }
    }

    // Zıplama ve yerçekimi hesaplamaları
    if (!isOnGround) {
      verticalVelocity += gravity * dt;
      position.y += verticalVelocity * dt;

      // Zemine değdiyse zıplama durumunu sıfırla
      if (position.y >= groundLevel) {
        position.y = groundLevel;
        isOnGround = true;
        isJumping = false;
        hasDoubleJumped = false;
        verticalVelocity = 0;
        state = PlayerState.running;
      } else if (verticalVelocity > 0) {
        // Yukarı çıkmazsa, düşüyor olarak işaretle
        state = PlayerState.falling;
      }
    }

    // Dash hareketi
    if (isDashing) {
      // Dash sırasında biraz ileriye git
      position.x += dashDistance * (dt / dashDuration);
    }

    // Durum güncellemesi
    updateState();
  }

  // Düşmanla çarpışma kontrolü
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Düşmana çarpma
    if (other is EnemyComponent && !isInvulnerable) {
      // Can kaybı (invulnerable olmadığı sürece)
      takeDamage(other.enemy.attackDamage);
    }

    // Engel ile çarpışma kontrolü eklendi
    if (other is ObstacleComponent && !isInvulnerable) {
      if (gameRef.hasShield) {
        gameRef.hasShield = false; // Kalkanı kaldır
        // Kalkan sesi vb. eklenebilir
        other.removeFromParent(); // Engeli kaldır
        gameRef.obstacles.remove(other);
      } else {
        takeDamage(1); // 1 birim hasar ver (can azaltır ve dokunulmazlık verir)
        other.removeFromParent(); // Engeli kaldır
        gameRef.obstacles.remove(other);
      }
    }

    // Platforma çarpma/üzerinde durma
    if (other is PlatformComponent) {
      // Eğer karakterin alt kısmı platformun üst kısmına değiyorsa
      final playerBottom = position.y;
      final platformTop = other.position.y;

      if (verticalVelocity > 0 && playerBottom <= platformTop + 10) {
        // Platformun üzerine çık
        position.y = platformTop;
        isOnGround = true;
        isJumping = false;
        hasDoubleJumped = false;
        verticalVelocity = 0;
        state = PlayerState.running;

        // Eğer yerleşik platformsa (normal değilse) özel davranış tetikle
        other.playerLanded();

        // Platform tipine göre davranış
        switch (other.platform.type) {
          case PlatformType.bouncy:
            // Zıplattır
            jump(other.platform.bounceForce);
            break;

          case PlatformType.hazardous:
            // Zarar ver
            takeDamage(other.platform.damage);
            break;

          default:
            // Diğer platformlar için normal davranış
            break;
        }
      }
    }

    // Toplanabilir öğelere çarpma (coin, güçlendirici, vb.)
    if (other is CollectibleComponent) {
      gameRef.handleCollision(other);
    }
  }

  // Sağlık durumunu güncelle ve hasar al
  void takeDamage(double damage) {
    if (isInvulnerable) return; // Dokunulmazsa zarar alma

    // Hasar efekti göster
    hitAnimationTimer = 0.3;
    state = PlayerState.hit;

    // Oyuna hasar bildir
    gameRef.loseLife();

    // Dokunulmazlık süresi ekle
    isInvulnerable = true;
    invulnerabilityTimer = 2.0;

    // Ses efekti - kaldırıldı
    // gameRef.audioService.playSfx('hit');

    // Oyuncu öldüyse durumu güncelle
    if (gameRef.isGameOver) {
      state = PlayerState.dead;
    }
  }

  // Zıplama işlemi
  void jump([double strengthMultiplier = 1.0]) {
    // Zaten çift zıpladıysa, artık zıplayamaz
    if (hasDoubleJumped) return;

    // İlk zıplama
    if (isOnGround) {
      isOnGround = false;
      isJumping = true;
      verticalVelocity = jumpVelocity * strengthMultiplier;
      state = PlayerState.jumping;

      // Ses efekti - kaldırıldı
      // gameRef.audioService.playSfx('jump');
    }
    // Çift zıplama
    else if (isJumping && !hasDoubleJumped) {
      hasDoubleJumped = true;
      verticalVelocity = doubleJumpVelocity * strengthMultiplier;
      state = PlayerState.doubleJumping;

      // Ses efekti - kaldırıldı
      // gameRef.audioService.playSfx('double_jump');
    }
  }

  // Dash (hızlı hareket) işlemi
  void dash() {
    // Eğer bekleme süresi dolmuşsa dash yapılabilir
    if (dashCooldownTimer <= 0 && !isDashing) {
      isDashing = true;
      dashTimer = dashDuration;
      dashCooldownTimer = dashCooldown;
      state = PlayerState.dashing;

      // Ses efekti - kaldırıldı
      // gameRef.audioService.playSfx('dash');
    }
  }

  // Kayma işlemi
  void slide() {
    // Yerde olduğunda ve kaymıyorsa kayabilir
    if (isOnGround && !isSliding) {
      isSliding = true;
      slideTimer = slideDuration;
      state = PlayerState.sliding;

      // Karakteri alçalt (çömelme/kayma animasyonu için)
      size.y = 40; // Yarı boyut
      position.y = groundLevel; // Zemini korumak için pozisyonu ayarla

      // Ses efekti - kaldırıldı
      // gameRef.audioService.playSfx('slide');
    }
  }

  // Ateş etme işlemi
  void shoot() {
    // Karakterin silah tipini kontrol et
    final weaponType = character.attributes['weaponType'] as String? ?? 'sword';

    // Silah tipine göre ateş et
    switch (weaponType) {
      case 'bow':
        // Kızılderili karakteri - ok atma
        if (isSwingingBlade) return;

        // Ok atma başlat
        isSwingingBlade = true;
        swingTimer = 0.0;
        state = PlayerState.shooting;

        // Ok oluştur ve fırlat
        _shootArrow();
        break;

      case 'axe':
      case 'sword':
      default:
        // Kılıç veya balta sallama
        if (isSwingingBlade) return;

        // Kılıç sallama başlat
        isSwingingBlade = true;
        swingTimer = 0.0;
        state = PlayerState.shooting;

        // Efekt oluştur
        if (gameRef.particleSystem != null) {
          _createSwordSlashEffect();
        }
        break;
    }
  }

  // Ok atma metodu
  void _shootArrow() {
    // gameRef null kontrolü ekleyelim
    if (gameRef == null) {
      print("ERROR: gameRef null - cannot shoot arrow");
      return;
    }

    // Okun çıkış konumunu hesapla (karakterin ön tarafından)
    final arrowPosition = Vector2(
      position.x + size.x * 0.6, // Okun başlangıç pozisyonu
      position.y - size.y * 0.5, // Karakter boyunun üst kısmı
    );

    // Ok yönünü belirle (sağa doğru)
    final arrowDirection = Vector2(1, 0);

    // Okun hızını hesapla
    double arrowSpeed = 350.0; // Varsayılan ok hızı

    // Karakterin range değeri varsa oku daha hızlı/uzağa atsın
    final range = character.attributes['range'] as double? ?? 1.0;
    arrowSpeed *= range;

    // Ok oluştur ve oyuna ekle
    final arrow = ArrowBulletComponent(
      bullet: Bullet(
        damage: 1.0,
        speed: arrowSpeed,
        size: 20.0,
        color: Colors.brown.shade800,
      ),
      position: arrowPosition,
      direction: arrowDirection,
    );

    // Oku oyuna ekle
    gameRef.add(arrow);

    // Ok atma efekti
    if (gameRef.particleSystem != null) {
      _createArrowTrailEffect(arrowPosition);
    }
  }

  // Ok izi efekti
  void _createArrowTrailEffect(Vector2 position) {
    gameRef.particleSystem?.emit(
      count: 10,
      position: position,
      colors: [Colors.brown.shade300, Colors.brown.shade600],
      size: Vector2(5, 5),
      speed: 20,
      lifespan: 0.2,
    );
  }

  // Kılıç çarpışma kontrolü
  void _checkBladeCollision() {
    if (!isSwingingBlade) return;

    // Silah tipini kontrol et
    final weaponType = character.attributes['weaponType'] as String? ?? 'sword';

    // Silaha göre menzil ve hasar hesapla
    double range = swingRange;
    double damageMultiplier = 1.0;

    if (weaponType == 'axe') {
      // Balta için değerler
      range *= 0.8; // Balta daha kısa menzilli
      damageMultiplier = character.attributes['damage'] as double? ?? 1.5;
    }

    // Silahın ucunun pozisyonunu hesapla (karakterin önünde)
    final bladePositionX = position.x + size.x * 0.8;
    final bladePositionY = position.y - size.y * 0.5;
    final bladePosition = Vector2(bladePositionX, bladePositionY);

    // Menzil içindeki düşmanları bul
    for (final enemy in gameRef.enemies) {
      // Düşmanla silah arasındaki mesafeyi hesapla
      final distance = enemy.position.distanceTo(bladePosition);

      // Eğer düşman silah menziline girdiyse hasar ver
      if (distance < range) {
        final damage =
            isPoweredUp ? 3.0 * damageMultiplier : 1.0 * damageMultiplier;
        enemy.hit(damage);
      }
    }
  }

  // Kılıç sallama parçacık efekti
  void _createSwordSlashEffect() {
    // Kılıcın konumunu hesapla
    final swordPosition = Vector2(
      position.x + size.x * 0.8, // Karakterin önünde
      position.y - size.y * 0.5, // Karakter boyunun ortası
    );

    // Silah tipini kontrol et
    final weaponType = character.attributes['weaponType'] as String? ?? 'sword';

    // Silah tipine göre farklı efekt oluştur
    if (weaponType == 'axe') {
      // Balta efekti - turuncu/kırmızı
      gameRef.particleSystem?.emit(
        count: 15,
        position: swordPosition,
        colors: [
          Colors.orange.shade200,
          Colors.red.shade600,
          Colors.orange.shade400
        ],
        size: Vector2(12.0, 12.0),
        speed: 90.0,
        lifespan: 0.3,
      );
    } else {
      // Kılıç efekti - beyaz/mavi
      gameRef.particleSystem?.emit(
        count: 15,
        position: swordPosition,
        colors: [Colors.white, Colors.lightBlue.shade200, Colors.blue.shade600],
        size: Vector2(10.0, 10.0),
        speed: 80.0,
        lifespan: 0.3,
      );
    }
  }

  // Katana kılıcı çizim metodu
  void _drawKatana(
      Canvas canvas, Vector2 size, double armAngle, bool isSwinging) {
    // Silah tipini kontrol et
    final weaponType = character.attributes['weaponType'] as String? ?? 'sword';

    switch (weaponType) {
      case 'bow':
        _drawBow(canvas, size, armAngle, isSwinging);
        break;
      case 'axe':
        _drawAxe(canvas, size, armAngle, isSwinging);
        break;
      case 'sword':
      default:
        _drawSword(canvas, size, armAngle, isSwinging);
        break;
    }
  }

  // Kılıç çizim metodu
  void _drawSword(
      Canvas canvas, Vector2 size, double armAngle, bool isSwinging) {
    // Kılıcın başlangıç pozisyonu (sağ elin ucu)
    double handleX, handleY;

    if (isSwinging) {
      // Sallama sırasında kılıcın pozisyonu kola bağlı
      double elbowX =
          size.x * 0.6 + math.cos(armAngle - math.pi / 4) * size.x * 0.15;
      double elbowY =
          size.y * 0.35 + math.sin(armAngle - math.pi / 4) * size.x * 0.15;
      handleX = elbowX + math.cos(armAngle) * size.x * 0.2;
      handleY = elbowY + math.sin(armAngle) * size.x * 0.2;
    } else {
      // Normal duruşta kılıcın pozisyonu
      handleX = size.x * 0.75;
      handleY = size.y * 0.4;
    }

    // Kılıç açısı
    double swordAngle = isSwinging ? armAngle : math.pi * 0.1; // Hafif eğimli

    // Kılıç uzunluğu ve genişliği
    final bladeLength = size.x * 0.6; // Uzun bir katana
    final bladeWidth = size.x * 0.03; // İnce bir bıçak

    // Kılıç kabzası (handle)
    final handlePaint = Paint()..color = Colors.brown.shade900;
    final handleLength = size.x * 0.15;
    final handleWidth = size.x * 0.04;

    // Kılıç bıçağı (blade)
    final bladePaint = Paint()..color = Colors.grey.shade300;

    // Sallama animasyonu sırasında kılıç parıltısı
    if (isSwinging) {
      bladePaint.maskFilter = MaskFilter.blur(BlurStyle.outer, 2.0);
      if (isPoweredUp) {
        bladePaint.color =
            Colors.lightBlue.shade200; // Güçlendirilmiş kılıç rengi
      }
    }

    // Kabza ucundaki tutacağı çiz (tsuba)
    final tsubaPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(handleX, handleY), handleWidth * 1.5, tsubaPaint);

    // Kabzayı çiz
    canvas.save();
    canvas.translate(handleX, handleY);
    canvas.rotate(swordAngle + math.pi); // Kabza açısı (kılıcın tersi)
    canvas.drawRect(
        Rect.fromLTWH(
            -handleLength, -handleWidth / 2, handleLength, handleWidth),
        handlePaint);
    canvas.restore();

    // Bıçağı çiz
    canvas.save();
    canvas.translate(handleX, handleY);
    canvas.rotate(swordAngle);

    // Kılıç bıçağı
    canvas.drawRect(
        Rect.fromLTWH(0, -bladeWidth / 2, bladeLength, bladeWidth), bladePaint);

    // Kılıç ucu (keskin köşe)
    final bladeTipPath = Path();
    bladeTipPath.moveTo(bladeLength, -bladeWidth / 2);
    bladeTipPath.lineTo(bladeLength + bladeWidth * 3, 0);
    bladeTipPath.lineTo(bladeLength, bladeWidth / 2);
    bladeTipPath.close();
    canvas.drawPath(bladeTipPath, bladePaint);

    // Güçlendirilmiş kılıç için parıltı efekti
    if (isPoweredUp) {
      final glowPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0);

      canvas.drawRect(
          Rect.fromLTWH(0, -bladeWidth, bladeLength, bladeWidth * 2),
          glowPaint);
    }

    canvas.restore();
  }

  // Balta çizim metodu
  void _drawAxe(Canvas canvas, Vector2 size, double armAngle, bool isSwinging) {
    // Baltanın başlangıç pozisyonu (sağ elin ucu)
    double handleX, handleY;

    if (isSwinging) {
      // Sallama sırasında baltanın pozisyonu kola bağlı
      double elbowX =
          size.x * 0.6 + math.cos(armAngle - math.pi / 4) * size.x * 0.15;
      double elbowY =
          size.y * 0.35 + math.sin(armAngle - math.pi / 4) * size.x * 0.15;
      handleX = elbowX + math.cos(armAngle) * size.x * 0.2;
      handleY = elbowY + math.sin(armAngle) * size.x * 0.2;
    } else {
      // Normal duruşta baltanın pozisyonu
      handleX = size.x * 0.75;
      handleY = size.y * 0.4;
    }

    // Balta açısı
    double axeAngle = isSwinging ? armAngle : math.pi * 0.1; // Hafif eğimli

    // Balta sapı
    final handlePaint = Paint()..color = Colors.brown.shade700;
    final handleLength = size.x * 0.5; // Uzun bir sap
    final handleWidth = size.x * 0.04; // Kalınlık

    // Balta başı
    final bladePaint = Paint()..color = Colors.grey.shade600;

    // Sallama animasyonu sırasında balta parıltısı
    if (isSwinging) {
      bladePaint.maskFilter = MaskFilter.blur(BlurStyle.outer, 2.0);
      if (isPoweredUp) {
        bladePaint.color = Colors.orange.shade300; // Güçlendirilmiş balta rengi
      }
    }

    // Sapı çiz
    canvas.save();
    canvas.translate(handleX, handleY);
    canvas.rotate(axeAngle);
    canvas.drawRect(
        Rect.fromLTWH(0, -handleWidth / 2, handleLength, handleWidth),
        handlePaint);

    // Balta başını çiz
    final axeHeadPath = Path();
    final axeHeadSize = size.x * 0.2;

    // Balta başının pozisyonu
    final double axeHeadX = handleLength - axeHeadSize * 0.3;
    final double axeHeadY = 0.0;

    // Balta başı şekli
    axeHeadPath.moveTo(axeHeadX, axeHeadY - handleWidth / 2);
    axeHeadPath.lineTo(axeHeadX + axeHeadSize * 0.3, axeHeadY - axeHeadSize);
    axeHeadPath.lineTo(axeHeadX + axeHeadSize, axeHeadY - axeHeadSize * 0.5);
    axeHeadPath.lineTo(axeHeadX + axeHeadSize, axeHeadY + axeHeadSize * 0.5);
    axeHeadPath.lineTo(axeHeadX + axeHeadSize * 0.3, axeHeadY + axeHeadSize);
    axeHeadPath.lineTo(axeHeadX, axeHeadY + handleWidth / 2);
    axeHeadPath.close();

    canvas.drawPath(axeHeadPath, bladePaint);

    // Balta ortasındaki metal detay
    final axeDetailPaint = Paint()..color = Colors.grey.shade400;
    canvas.drawCircle(Offset(axeHeadX, axeHeadY),
        (handleWidth * 0.8).toDouble(), axeDetailPaint);

    // Güçlendirilmiş balta için parıltı efekti
    if (isPoweredUp) {
      final glowPaint = Paint()
        ..color = Colors.orange.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0);

      canvas.drawPath(axeHeadPath, glowPaint);
    }

    canvas.restore();
  }

  // Yay çizim metodu
  void _drawBow(Canvas canvas, Vector2 size, double armAngle, bool isSwinging) {
    // Yayın başlangıç pozisyonu (sağ elin ucu)
    double handleX, handleY;

    if (isSwinging) {
      // Ok atma sırasında yayın pozisyonu kola bağlı
      double elbowX =
          size.x * 0.6 + math.cos(armAngle - math.pi / 4) * size.x * 0.15;
      double elbowY =
          size.y * 0.35 + math.sin(armAngle - math.pi / 4) * size.x * 0.15;
      handleX = elbowX + math.cos(armAngle) * size.x * 0.2;
      handleY = elbowY + math.sin(armAngle) * size.x * 0.2;
    } else {
      // Normal duruşta yayın pozisyonu
      handleX = size.x * 0.75;
      handleY = size.y * 0.4;
    }

    // Yay açısı
    double bowAngle = isSwinging ? armAngle : math.pi * 0.1; // Hafif eğimli

    // Başlangıç pozisyonunu ayarla
    canvas.save();
    canvas.translate(handleX, handleY);
    canvas.rotate(bowAngle);

    // Yay çerçevesi
    final bowPaint = Paint()
      ..color = Colors.brown.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.x * 0.02;

    // Yay yüksekliği ve genişliği
    final bowHeight = size.x * 0.4;
    final bowCurve =
        isSwinging ? size.x * 0.05 : size.x * 0.15; // Gerildiğinde daha düz

    // Yay çiz
    final bowPath = Path();
    bowPath.moveTo(0, -bowHeight / 2); // Üst uç
    bowPath.quadraticBezierTo(
        bowCurve, 0, 0, bowHeight / 2); // Alt uca kadar kavis
    canvas.drawPath(bowPath, bowPaint);

    // Yay ipi
    final stringPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    canvas.drawLine(
        Offset(0, -bowHeight / 2), Offset(0, bowHeight / 2), stringPaint);

    // Ok atma anında ok çiz
    if (isSwinging) {
      // Ok
      final arrowPaint = Paint()..color = Colors.brown.shade600;
      // Ok gövdesi
      canvas.drawRect(
          Rect.fromLTWH(0, -size.x * 0.01, size.x * 0.3, size.x * 0.02),
          arrowPaint);

      // Ok ucu
      final arrowTipPath = Path();
      arrowTipPath.moveTo(size.x * 0.3, -size.x * 0.03);
      arrowTipPath.lineTo(size.x * 0.4, 0);
      arrowTipPath.lineTo(size.x * 0.3, size.x * 0.03);
      arrowTipPath.close();
      canvas.drawPath(arrowTipPath, arrowPaint);

      // Ok tüyleri
      final featherPaint = Paint()..color = Colors.red.shade700;
      canvas.drawRect(
          Rect.fromLTWH(
              size.x * 0.05, -size.x * 0.04, size.x * 0.03, size.x * 0.08),
          featherPaint);
    }

    // Güçlendirilmiş yay için parıltı efekti
    if (isPoweredUp) {
      final glowPaint = Paint()
        ..color = Colors.green.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.x * 0.03
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0);

      canvas.drawPath(bowPath, glowPaint);
    }

    canvas.restore();
  }

  // Durumu güncelle ve animasyon için kullan
  void updateState() {
    // Durumlar önceliklendirilmiştir
    if (state == PlayerState.dead) {
      // Ölü durumu - değişmez
      return;
    } else if (hitAnimationTimer > 0) {
      state = PlayerState.hit;
    } else if (isDashing) {
      state = PlayerState.dashing;
    } else if (isSliding) {
      state = PlayerState.sliding;
    } else if (hasDoubleJumped) {
      state = PlayerState.doubleJumping;
    } else if (isJumping) {
      state = PlayerState.jumping;
    } else if (!isOnGround) {
      state = PlayerState.falling;
    } else {
      state = PlayerState.running;
    }
  }

  @override
  void render(Canvas canvas) {
    // Karakter ID'sine göre uygun render fonksiyonunu çağır
    final characterId = character.id;

    switch (characterId) {
      case 'ninja':
        _renderNinja(canvas);
        break;
      case 'janissary':
        _renderJanissary(canvas);
        break;
      case 'viking':
        _renderViking(canvas);
        break;
      case 'indian':
        _renderIndian(canvas);
        break;
      default:
        _renderNinja(canvas); // Varsayılan olarak ninja çiz
        break;
    }
  }

  // Ninja karakterini çizme fonksiyonu
  void _renderNinja(Canvas canvas) {
    canvas.save();

    // Koşma animasyonu için zaman hesaplama
    final runningTime = DateTime.now().millisecondsSinceEpoch / 150;
    final legOffset =
        state == PlayerState.running ? math.sin(runningTime) * 12 : 0;
    final armOffset =
        state == PlayerState.running ? math.cos(runningTime) * 10 : 0;
    final isJumpingOrFalling = state == PlayerState.jumping ||
        state == PlayerState.doubleJumping ||
        state == PlayerState.falling;

    // ------ NİNJA KARAKTERİ ÇİZİMİ ------

    // Gölge efekti
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.x * 0.5, size.y * 0.97),
            width: size.x * 0.6,
            height: size.y * 0.1),
        shadowPaint);

    // Renk şeması - karakter renklerini değişkenlere atayarak daha kolay güncelleme
    final ninjaMainColor = primaryColor; // Karakter rengini kullan
    final ninjaAccentColor = secondaryColor; // İkincil rengi kullan
    final ninjaSkinColor = Color(0xFFE6C8A9);

    // ---- VÜCUT BÖLÜMLERİ ----

    // Bacaklar - koşma animasyonlu
    final legPaint = Paint()..color = ninjaMainColor;

    // Sol bacak
    final leftLegPath = Path();
    final leftLegY = isJumpingOrFalling ? 10 : legOffset;
    leftLegPath.moveTo(size.x * 0.4, size.y * 0.6);
    leftLegPath.quadraticBezierTo(
        size.x * 0.35,
        size.y * (0.75 + leftLegY / 100),
        size.x * 0.3,
        size.y * (0.95 + leftLegY / 100));
    leftLegPath.lineTo(size.x * 0.4, size.y * (0.95 + leftLegY / 100));
    leftLegPath.quadraticBezierTo(size.x * 0.42,
        size.y * (0.75 + leftLegY / 100), size.x * 0.45, size.y * 0.6);
    leftLegPath.close();
    canvas.drawPath(leftLegPath, legPaint);

    // Sağ bacak
    final rightLegPath = Path();
    final rightLegY = isJumpingOrFalling ? 10 : -legOffset;
    rightLegPath.moveTo(size.x * 0.55, size.y * 0.6);
    rightLegPath.quadraticBezierTo(
        size.x * 0.6,
        size.y * (0.75 + rightLegY / 100),
        size.x * 0.65,
        size.y * (0.95 + rightLegY / 100));
    rightLegPath.lineTo(size.x * 0.55, size.y * (0.95 + rightLegY / 100));
    rightLegPath.quadraticBezierTo(size.x * 0.52,
        size.y * (0.75 + rightLegY / 100), size.x * 0.5, size.y * 0.6);
    rightLegPath.close();
    canvas.drawPath(rightLegPath, legPaint);

    // Vücut - siyah ninja giysisi
    final bodyPaint = Paint()..color = ninjaMainColor;
    final bodyPath = Path();
    bodyPath.moveTo(size.x * 0.4, size.y * 0.6);
    bodyPath.lineTo(size.x * 0.6, size.y * 0.6);
    bodyPath.lineTo(size.x * 0.65, size.y * 0.3);
    bodyPath.quadraticBezierTo(
        size.x * 0.5, size.y * 0.25, size.x * 0.35, size.y * 0.3);
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Kemeri çiz - aksesuar
    final beltPaint = Paint()..color = ninjaAccentColor;
    canvas.drawRect(
        Rect.fromLTWH(
            size.x * 0.38, size.y * 0.55, size.x * 0.24, size.y * 0.05),
        beltPaint);

    // Kafa - oval ninja maskesi
    final headPaint = Paint()..color = ninjaMainColor;
    canvas.drawCircle(
        Offset(size.x * 0.5, size.y * 0.2), size.x * 0.15, headPaint);

    // Yüz açıklığı - ten rengi görünen kısım
    final facePaint = Paint()..color = ninjaSkinColor;
    final facePath = Path();
    facePath.addOval(Rect.fromLTWH(
        size.x * 0.4, size.y * 0.14, size.x * 0.2, size.y * 0.12));
    canvas.drawPath(facePath, facePaint);

    // Gözler - keskin ninja bakışı
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawOval(
        Rect.fromLTWH(
            size.x * 0.42, size.y * 0.17, size.x * 0.06, size.y * 0.06),
        eyePaint);
    canvas.drawOval(
        Rect.fromLTWH(
            size.x * 0.52, size.y * 0.17, size.x * 0.06, size.y * 0.06),
        eyePaint);

    // Göz bebekleri - duruma göre hareket eden
    final lookDirection = state == PlayerState.dashing ? 0.02 : 0.0;
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(size.x * (0.45 + lookDirection), size.y * 0.2),
        size.x * 0.02, pupilPaint);
    canvas.drawCircle(Offset(size.x * (0.55 + lookDirection), size.y * 0.2),
        size.x * 0.02, pupilPaint);

    // Kafa bandı - ninja temaya uygun
    final headbandPaint = Paint()..color = ninjaAccentColor;
    canvas.drawRect(
        Rect.fromLTWH(
            size.x * 0.35, size.y * 0.13, size.x * 0.3, size.y * 0.04),
        headbandPaint);

    // Kafa bandı bağları - rüzgarda savrulan
    final bandTailPath = Path();
    final windEffect = math.sin(_getAnimationTime() * 2) * 5;
    bandTailPath.moveTo(size.x * 0.65, size.y * 0.15);
    bandTailPath.quadraticBezierTo(size.x * (0.7 + windEffect / 100),
        size.y * 0.18, size.x * (0.75 + windEffect / 100), size.y * 0.15);
    bandTailPath.lineTo(size.x * (0.75 + windEffect / 100), size.y * 0.13);
    bandTailPath.quadraticBezierTo(size.x * (0.7 + windEffect / 100),
        size.y * 0.16, size.x * 0.65, size.y * 0.13);
    bandTailPath.close();
    canvas.drawPath(bandTailPath, headbandPaint);

    // Kollar - koşma animasyonlu veya kılıç sallama
    final armPaint = Paint()..color = ninjaMainColor;

    // Sol kol - silah tutan
    final leftArmPath = Path();
    leftArmPath.moveTo(size.x * 0.4, size.y * 0.35);
    leftArmPath.quadraticBezierTo(
        size.x * (0.3 - armOffset / 100),
        size.y * (0.4 - armOffset / 100),
        size.x * (0.25 - armOffset / 100),
        size.y * (0.5 - armOffset / 100));
    leftArmPath.lineTo(
        size.x * (0.3 - armOffset / 100), size.y * (0.55 - armOffset / 100));
    leftArmPath.quadraticBezierTo(size.x * (0.35 - armOffset / 100),
        size.y * (0.45 - armOffset / 100), size.x * 0.4, size.y * 0.4);
    leftArmPath.close();
    canvas.drawPath(leftArmPath, armPaint);

    // Sağ kol - kılıç tutan
    final rightArmPath = Path();

    // Kılıç sallama durumunda kolun açısını değiştir
    double armAngle = 0.0;
    if (isSwingingBlade) {
      // Kılıç sallarken kolu yukarıdan aşağıya doğru hareket ettir
      armAngle = -math.pi * 0.5 + swingAngle;
    } else {
      // Normal kol pozisyonu
      armAngle = 0.0;
    }

    // Kola açı uygula - koşma animasyonu kaldırıldı
    double armX = size.x * 0.65; // armOffset kaldırıldı
    double armY = size.y * 0.40;

    if (isSwingingBlade) {
      // Sallama sırasında omuz bağlantısını sabit tut, dirsek ve bilek hareket etsin
      rightArmPath.moveTo(size.x * 0.6, size.y * 0.35);

      // Dirsek pozisyonu
      double elbowX =
          size.x * 0.6 + math.cos(armAngle - math.pi / 4) * size.x * 0.15;
      double elbowY =
          size.y * 0.35 + math.sin(armAngle - math.pi / 4) * size.x * 0.15;

      // Bilek pozisyonu
      double wristX = elbowX + math.cos(armAngle) * size.x * 0.2;
      double wristY = elbowY + math.sin(armAngle) * size.x * 0.2;

      rightArmPath.lineTo(elbowX, elbowY);
      rightArmPath.lineTo(wristX, wristY);
      rightArmPath.lineTo(wristX - 5, wristY + 5);
      rightArmPath.close();
    } else {
      // Normal kol çizimi - koşma animasyonu kaldırıldı
      rightArmPath.moveTo(size.x * 0.6, size.y * 0.35);
      rightArmPath.quadraticBezierTo(
          armX, armY, armX + size.x * 0.1, armY + size.y * 0.1);
      rightArmPath.lineTo(armX + size.x * 0.1, armY + size.y * 0.15);
      rightArmPath.quadraticBezierTo(
          armX, armY + size.y * 0.05, size.x * 0.6, size.y * 0.42);
      rightArmPath.close();
    }

    canvas.drawPath(rightArmPath, armPaint);

    // Katana kılıcı çiz
    _drawKatana(canvas, size, armAngle, isSwingingBlade);

    // Dokunulmazlık efekti
    if (isInvulnerable) {
      _renderInvulnerabilityEffect(canvas, size, invulnerabilityTimer);
    }

    // Vurulma efekti
    if (hitAnimationTimer > 0) {
      _renderHitEffect(canvas, size, hitAnimationTimer);
    }

    canvas.restore();
  }

  // Yeniçeri karakterini çizme fonksiyonu
  void _renderJanissary(Canvas canvas) {
    canvas.save();

    // Koşma animasyonu için zaman hesaplama
    final runningTime = DateTime.now().millisecondsSinceEpoch / 150;
    final legOffset =
        state == PlayerState.running ? math.sin(runningTime) * 12 : 0;
    final armOffset =
        state == PlayerState.running ? math.cos(runningTime) * 10 : 0;
    final isJumpingOrFalling = state == PlayerState.jumping ||
        state == PlayerState.doubleJumping ||
        state == PlayerState.falling;

    // ------ YENİÇERİ KARAKTERİ ÇİZİMİ ------

    // Gölge efekti
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.x * 0.5, size.y * 0.97),
            width: size.x * 0.6,
            height: size.y * 0.1),
        shadowPaint);

    // Renk şeması
    final bodyColor = Color(0xFF9E0B0F); // Yeniçeri kırmızı üniforma
    final accentColor = Color(0xFFFFD700); // Altın sarısı detaylar
    final skinColor = Color(0xFFE6C8A9); // Ten rengi

    // ---- VÜCUT BÖLÜMLERİ ----

    // Bacaklar - koşma animasyonlu
    final legPaint = Paint()..color = Colors.white; // Beyaz pantolon

    // Sol bacak
    final leftLegPath = Path();
    final leftLegY = isJumpingOrFalling ? 10 : legOffset;
    leftLegPath.moveTo(size.x * 0.4, size.y * 0.6);
    leftLegPath.quadraticBezierTo(
        size.x * 0.35,
        size.y * (0.75 + leftLegY / 100),
        size.x * 0.3,
        size.y * (0.95 + leftLegY / 100));
    leftLegPath.lineTo(size.x * 0.4, size.y * (0.95 + leftLegY / 100));
    leftLegPath.quadraticBezierTo(size.x * 0.42,
        size.y * (0.75 + leftLegY / 100), size.x * 0.45, size.y * 0.6);
    leftLegPath.close();
    canvas.drawPath(leftLegPath, legPaint);

    // Sağ bacak
    final rightLegPath = Path();
    final rightLegY = isJumpingOrFalling ? 10 : -legOffset;
    rightLegPath.moveTo(size.x * 0.55, size.y * 0.6);
    rightLegPath.quadraticBezierTo(
        size.x * 0.6,
        size.y * (0.75 + rightLegY / 100),
        size.x * 0.65,
        size.y * (0.95 + rightLegY / 100));
    rightLegPath.lineTo(size.x * 0.55, size.y * (0.95 + rightLegY / 100));
    rightLegPath.quadraticBezierTo(size.x * 0.52,
        size.y * (0.75 + rightLegY / 100), size.x * 0.5, size.y * 0.6);
    rightLegPath.close();
    canvas.drawPath(rightLegPath, legPaint);

    // Vücut - kırmızı yeniçeri üniforması
    final bodyPaint = Paint()..color = bodyColor;
    final bodyPath = Path();
    bodyPath.moveTo(size.x * 0.4, size.y * 0.6);
    bodyPath.lineTo(size.x * 0.6, size.y * 0.6);
    bodyPath.lineTo(size.x * 0.65, size.y * 0.3);
    bodyPath.quadraticBezierTo(
        size.x * 0.5, size.y * 0.25, size.x * 0.35, size.y * 0.3);
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Göğüs detayları - altın işlemeler
    final chestDetailPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Göğüs işlemeleri
    canvas.drawArc(
        Rect.fromLTWH(
            size.x * 0.42, size.y * 0.35, size.x * 0.16, size.y * 0.15),
        math.pi * 0.3,
        math.pi * 0.4,
        false,
        chestDetailPaint);

    canvas.drawArc(
        Rect.fromLTWH(
            size.x * 0.42, size.y * 0.4, size.x * 0.16, size.y * 0.15),
        math.pi * 0.3,
        math.pi * 0.4,
        false,
        chestDetailPaint);

    // Kemeri çiz - altın kemer
    final beltPaint = Paint()..color = accentColor;
    canvas.drawRect(
        Rect.fromLTWH(
            size.x * 0.38, size.y * 0.55, size.x * 0.24, size.y * 0.05),
        beltPaint);

    // Kafa - yeniçeri börkü (başlık)
    final headPaint = Paint()..color = Colors.white; // Beyaz börk
    canvas.drawCircle(
        Offset(size.x * 0.5, size.y * 0.2), size.x * 0.15, headPaint);

    // Börk tepe kısmı (kırmızı)
    final borkTopPaint = Paint()..color = bodyColor;
    canvas.drawCircle(
        Offset(size.x * 0.5, size.y * 0.15), size.x * 0.1, borkTopPaint);

    // Börk sorgucu (tüy)
    final featherPaint = Paint()..color = Colors.white;
    final featherPath = Path();
    final windEffect = math.sin(_getAnimationTime() * 2) * 5;
    featherPath.moveTo(size.x * 0.5, size.y * 0.05);
    featherPath.quadraticBezierTo(size.x * (0.55 + windEffect / 100),
        size.y * 0, size.x * (0.6 + windEffect / 100), size.y * 0.1);
    featherPath.quadraticBezierTo(
        size.x * 0.55, size.y * 0.12, size.x * 0.5, size.y * 0.05);
    canvas.drawPath(featherPath, featherPaint);

    // Yüz çizimi
    final facePaint = Paint()..color = skinColor;
    canvas.drawOval(
        Rect.fromLTWH(size.x * 0.4, size.y * 0.17, size.x * 0.2, size.y * 0.15),
        facePaint);

    // Gözler
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawOval(
        Rect.fromLTWH(
            size.x * 0.42, size.y * 0.19, size.x * 0.06, size.y * 0.06),
        eyePaint);
    canvas.drawOval(
        Rect.fromLTWH(
            size.x * 0.52, size.y * 0.19, size.x * 0.06, size.y * 0.06),
        eyePaint);

    // Göz bebekleri
    final lookDirection = state == PlayerState.dashing ? 0.02 : 0.0;
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(size.x * (0.45 + lookDirection), size.y * 0.22),
        size.x * 0.02, pupilPaint);
    canvas.drawCircle(Offset(size.x * (0.55 + lookDirection), size.y * 0.22),
        size.x * 0.02, pupilPaint);

    // Bıyık
    final mustachePaint = Paint()..color = Colors.black;
    canvas.drawLine(Offset(size.x * 0.45, size.y * 0.26),
        Offset(size.x * 0.4, size.y * 0.25), mustachePaint..strokeWidth = 2);
    canvas.drawLine(Offset(size.x * 0.55, size.y * 0.26),
        Offset(size.x * 0.6, size.y * 0.25), mustachePaint..strokeWidth = 2);

    // Kollar - koşma animasyonlu veya kılıç sallama
    final armPaint = Paint()..color = bodyColor;

    // Sol kol
    final leftArmPath = Path();
    leftArmPath.moveTo(size.x * 0.4, size.y * 0.35);
    leftArmPath.quadraticBezierTo(
        size.x * (0.3 - armOffset / 100),
        size.y * (0.4 - armOffset / 100),
        size.x * (0.25 - armOffset / 100),
        size.y * (0.5 - armOffset / 100));
    leftArmPath.lineTo(
        size.x * (0.3 - armOffset / 100), size.y * (0.55 - armOffset / 100));
    leftArmPath.quadraticBezierTo(size.x * (0.35 - armOffset / 100),
        size.y * (0.45 - armOffset / 100), size.x * 0.4, size.y * 0.4);
    leftArmPath.close();
    canvas.drawPath(leftArmPath, armPaint);

    // Sağ kol - kılıç tutan
    final rightArmPath = Path();

    // Kılıç sallama durumunda kolun açısını değiştir
    double armAngle = 0.0;
    if (isSwingingBlade) {
      // Kılıç sallarken kolu yukarıdan aşağıya doğru hareket ettir
      armAngle = -math.pi * 0.5 + swingAngle;
    } else {
      // Normal kol pozisyonu
      armAngle = 0.0;
    }

    // Kola açı uygula
    double armX = size.x * 0.65;
    double armY = size.y * 0.40;

    if (isSwingingBlade) {
      // Sallama sırasında omuz bağlantısını sabit tut, dirsek ve bilek hareket etsin
      rightArmPath.moveTo(size.x * 0.6, size.y * 0.35);

      // Dirsek pozisyonu
      double elbowX =
          size.x * 0.6 + math.cos(armAngle - math.pi / 4) * size.x * 0.15;
      double elbowY =
          size.y * 0.35 + math.sin(armAngle - math.pi / 4) * size.x * 0.15;

      // Bilek pozisyonu
      double wristX = elbowX + math.cos(armAngle) * size.x * 0.2;
      double wristY = elbowY + math.sin(armAngle) * size.x * 0.2;

      rightArmPath.lineTo(elbowX, elbowY);
      rightArmPath.lineTo(wristX, wristY);
      rightArmPath.lineTo(wristX - 5, wristY + 5);
      rightArmPath.close();
    } else {
      // Normal kol çizimi
      rightArmPath.moveTo(size.x * 0.6, size.y * 0.35);
      rightArmPath.quadraticBezierTo(
          armX, armY, armX + size.x * 0.1, armY + size.y * 0.1);
      rightArmPath.lineTo(armX + size.x * 0.1, armY + size.y * 0.15);
      rightArmPath.quadraticBezierTo(
          armX, armY + size.y * 0.05, size.x * 0.6, size.y * 0.42);
      rightArmPath.close();
    }

    canvas.drawPath(rightArmPath, armPaint);

    // Silah çizimi - varsayılan olarak kılıç
    final weaponType = character.attributes['weaponType'] as String? ?? 'sword';

    switch (weaponType) {
      case 'sword':
        _drawSword(canvas, size, armAngle, isSwingingBlade);
        break;
      case 'axe':
        _drawAxe(canvas, size, armAngle, isSwingingBlade);
        break;
      case 'bow':
        _drawBow(canvas, size, armAngle, isSwingingBlade);
        break;
    }

    // Dokunulmazlık efekti
    if (isInvulnerable) {
      _renderInvulnerabilityEffect(canvas, size, invulnerabilityTimer);
    }

    // Vurulma efekti
    if (hitAnimationTimer > 0) {
      _renderHitEffect(canvas, size, hitAnimationTimer);
    }

    canvas.restore();
  }

  // Viking karakterini çizme fonksiyonu
  void _renderViking(Canvas canvas) {
    canvas.save();

    // Koşma animasyonu için zaman hesaplama
    final runningTime = DateTime.now().millisecondsSinceEpoch / 150;
    final legOffset =
        state == PlayerState.running ? math.sin(runningTime) * 12 : 0;
    final armOffset =
        state == PlayerState.running ? math.cos(runningTime) * 10 : 0;
    final isJumpingOrFalling = state == PlayerState.jumping ||
        state == PlayerState.doubleJumping ||
        state == PlayerState.falling;

    // ------ VİKİNG KARAKTERİ ÇİZİMİ ------

    // Gölge efekti
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.x * 0.5, size.y * 0.97),
            width: size.x * 0.6,
            height: size.y * 0.1),
        shadowPaint);

    // Renk şeması
    final bodyColor = Color(0xFF546E7A); // Viking zırh rengi
    final accentColor = Color(0xFFD2B48C); // Deri detaylar
    final skinColor = Color(0xFFFFDBC0); // Viking ten rengi
    final hairColor = Color(0xFFD4AF37); // Sarı saç/sakal rengi

    // ---- VÜCUT BÖLÜMLERİ ----

    // Bacaklar - koşma animasyonlu
    final legPaint = Paint()..color = Color(0xFF5D4037); // Kahverengi pantolon

    // Sol bacak
    final leftLegPath = Path();
    final leftLegY = isJumpingOrFalling ? 10 : legOffset;
    leftLegPath.moveTo(size.x * 0.4, size.y * 0.6);
    leftLegPath.quadraticBezierTo(
        size.x * 0.35,
        size.y * (0.75 + leftLegY / 100),
        size.x * 0.3,
        size.y * (0.95 + leftLegY / 100));
    leftLegPath.lineTo(size.x * 0.4, size.y * (0.95 + leftLegY / 100));
    leftLegPath.quadraticBezierTo(size.x * 0.42,
        size.y * (0.75 + leftLegY / 100), size.x * 0.45, size.y * 0.6);
    leftLegPath.close();
    canvas.drawPath(leftLegPath, legPaint);

    // Sağ bacak
    final rightLegPath = Path();
    final rightLegY = isJumpingOrFalling ? 10 : -legOffset;
    rightLegPath.moveTo(size.x * 0.55, size.y * 0.6);
    rightLegPath.quadraticBezierTo(
        size.x * 0.6,
        size.y * (0.75 + rightLegY / 100),
        size.x * 0.65,
        size.y * (0.95 + rightLegY / 100));
    rightLegPath.lineTo(size.x * 0.55, size.y * (0.95 + rightLegY / 100));
    rightLegPath.quadraticBezierTo(size.x * 0.52,
        size.y * (0.75 + rightLegY / 100), size.x * 0.5, size.y * 0.6);
    rightLegPath.close();
    canvas.drawPath(rightLegPath, legPaint);

    // Vücut - Viking zırhı
    final bodyPaint = Paint()..color = bodyColor;
    final bodyPath = Path();
    bodyPath.moveTo(size.x * 0.4, size.y * 0.6);
    bodyPath.lineTo(size.x * 0.6, size.y * 0.6);
    bodyPath.lineTo(size.x * 0.65, size.y * 0.3);
    bodyPath.quadraticBezierTo(
        size.x * 0.5, size.y * 0.25, size.x * 0.35, size.y * 0.3);
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Zırh detayları
    final armorDetailPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Zırh üzerindeki deri kayışlar
    canvas.drawLine(Offset(size.x * 0.45, size.y * 0.35),
        Offset(size.x * 0.55, size.y * 0.35), armorDetailPaint);

    canvas.drawLine(Offset(size.x * 0.43, size.y * 0.42),
        Offset(size.x * 0.57, size.y * 0.42), armorDetailPaint);

    canvas.drawLine(Offset(size.x * 0.41, size.y * 0.49),
        Offset(size.x * 0.59, size.y * 0.49), armorDetailPaint);

    // Kemeri çiz
    final beltPaint = Paint()..color = accentColor;
    canvas.drawRect(
        Rect.fromLTWH(
            size.x * 0.38, size.y * 0.57, size.x * 0.24, size.y * 0.03),
        beltPaint);

    // Kafa - Viking yüzü
    final headPaint = Paint()..color = skinColor;
    canvas.drawCircle(
        Offset(size.x * 0.5, size.y * 0.2), size.x * 0.15, headPaint);

    // Viking miğferi
    final helmetPaint = Paint()..color = Color(0xFF78909C); // Metal miğfer
    final helmetPath = Path();

    // Miğfer gövdesi
    helmetPath.moveTo(size.x * 0.35, size.y * 0.2);
    helmetPath.lineTo(size.x * 0.35, size.y * 0.1);
    helmetPath.lineTo(size.x * 0.65, size.y * 0.1);
    helmetPath.lineTo(size.x * 0.65, size.y * 0.2);
    helmetPath.close();
    canvas.drawPath(helmetPath, helmetPaint);

    // Miğfer boynuzları
    final hornPaint = Paint()..color = Color(0xFFD7CCC8); // Boynuz rengi

    // Sol boynuz
    final leftHornPath = Path();
    leftHornPath.moveTo(size.x * 0.37, size.y * 0.11);
    leftHornPath.quadraticBezierTo(
        size.x * 0.3, size.y * 0.05, size.x * 0.25, size.y * 0.11);
    leftHornPath.lineTo(size.x * 0.28, size.y * 0.14);
    leftHornPath.quadraticBezierTo(
        size.x * 0.32, size.y * 0.08, size.x * 0.37, size.y * 0.13);
    leftHornPath.close();
    canvas.drawPath(leftHornPath, hornPaint);

    // Sağ boynuz
    final rightHornPath = Path();
    rightHornPath.moveTo(size.x * 0.63, size.y * 0.11);
    rightHornPath.quadraticBezierTo(
        size.x * 0.7, size.y * 0.05, size.x * 0.75, size.y * 0.11);
    rightHornPath.lineTo(size.x * 0.72, size.y * 0.14);
    rightHornPath.quadraticBezierTo(
        size.x * 0.68, size.y * 0.08, size.x * 0.63, size.y * 0.13);
    rightHornPath.close();
    canvas.drawPath(rightHornPath, hornPaint);

    // Yüz - sadece alt kısmı görünüyor
    // Sakal
    final beardPaint = Paint()..color = hairColor;
    final beardPath = Path();
    beardPath.moveTo(size.x * 0.4, size.y * 0.23);
    beardPath.lineTo(size.x * 0.37, size.y * 0.32);
    beardPath.lineTo(size.x * 0.5, size.y * 0.35);
    beardPath.lineTo(size.x * 0.63, size.y * 0.32);
    beardPath.lineTo(size.x * 0.6, size.y * 0.23);
    beardPath.close();
    canvas.drawPath(beardPath, beardPaint);

    // Gözler
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawOval(
        Rect.fromLTWH(
            size.x * 0.42, size.y * 0.14, size.x * 0.06, size.y * 0.04),
        eyePaint);
    canvas.drawOval(
        Rect.fromLTWH(
            size.x * 0.52, size.y * 0.14, size.x * 0.06, size.y * 0.04),
        eyePaint);

    // Göz bebekleri
    final lookDirection = state == PlayerState.dashing ? 0.02 : 0.0;
    final pupilPaint = Paint()..color = Colors.blue.shade800; // Mavi gözler
    canvas.drawCircle(Offset(size.x * (0.45 + lookDirection), size.y * 0.16),
        size.x * 0.015, pupilPaint);
    canvas.drawCircle(Offset(size.x * (0.55 + lookDirection), size.y * 0.16),
        size.x * 0.015, pupilPaint);

    // Bıyık
    final mustachePaint = Paint()
      ..color = hairColor
      ..strokeWidth = 2;
    canvas.drawLine(Offset(size.x * 0.46, size.y * 0.21),
        Offset(size.x * 0.40, size.y * 0.22), mustachePaint);
    canvas.drawLine(Offset(size.x * 0.54, size.y * 0.21),
        Offset(size.x * 0.60, size.y * 0.22), mustachePaint);

    // Kollar - koşma animasyonlu veya balta sallama
    final armPaint = Paint()..color = bodyColor;

    // Sol kol
    final leftArmPath = Path();
    leftArmPath.moveTo(size.x * 0.4, size.y * 0.35);
    leftArmPath.quadraticBezierTo(
        size.x * (0.3 - armOffset / 100),
        size.y * (0.4 - armOffset / 100),
        size.x * (0.25 - armOffset / 100),
        size.y * (0.5 - armOffset / 100));
    leftArmPath.lineTo(
        size.x * (0.3 - armOffset / 100), size.y * (0.55 - armOffset / 100));
    leftArmPath.quadraticBezierTo(size.x * (0.35 - armOffset / 100),
        size.y * (0.45 - armOffset / 100), size.x * 0.4, size.y * 0.4);
    leftArmPath.close();
    canvas.drawPath(leftArmPath, armPaint);

    // Sağ kol - balta tutan
    final rightArmPath = Path();

    // Balta sallama durumunda kolun açısını değiştir
    double armAngle = 0.0;
    if (isSwingingBlade) {
      // Balta sallarken kolu yukarıdan aşağıya doğru hareket ettir
      armAngle = -math.pi * 0.5 + swingAngle;
    } else {
      // Normal kol pozisyonu
      armAngle = 0.0;
    }

    // Kola açı uygula
    double armX = size.x * 0.65;
    double armY = size.y * 0.40;

    if (isSwingingBlade) {
      // Sallama sırasında omuz bağlantısını sabit tut, dirsek ve bilek hareket etsin
      rightArmPath.moveTo(size.x * 0.6, size.y * 0.35);

      // Dirsek pozisyonu
      double elbowX =
          size.x * 0.6 + math.cos(armAngle - math.pi / 4) * size.x * 0.15;
      double elbowY =
          size.y * 0.35 + math.sin(armAngle - math.pi / 4) * size.x * 0.15;

      // Bilek pozisyonu
      double wristX = elbowX + math.cos(armAngle) * size.x * 0.2;
      double wristY = elbowY + math.sin(armAngle) * size.x * 0.2;

      rightArmPath.lineTo(elbowX, elbowY);
      rightArmPath.lineTo(wristX, wristY);
      rightArmPath.lineTo(wristX - 5, wristY + 5);
      rightArmPath.close();
    } else {
      // Normal kol çizimi
      rightArmPath.moveTo(size.x * 0.6, size.y * 0.35);
      rightArmPath.quadraticBezierTo(
          armX, armY, armX + size.x * 0.1, armY + size.y * 0.1);
      rightArmPath.lineTo(armX + size.x * 0.1, armY + size.y * 0.15);
      rightArmPath.quadraticBezierTo(
          armX, armY + size.y * 0.05, size.x * 0.6, size.y * 0.42);
      rightArmPath.close();
    }

    canvas.drawPath(rightArmPath, armPaint);

    // Silah çizimi - varsayılan olarak balta
    final weaponType = character.attributes['weaponType'] as String? ?? 'axe';

    switch (weaponType) {
      case 'sword':
        _drawSword(canvas, size, armAngle, isSwingingBlade);
        break;
      case 'axe':
        _drawAxe(canvas, size, armAngle, isSwingingBlade);
        break;
      case 'bow':
        _drawBow(canvas, size, armAngle, isSwingingBlade);
        break;
    }

    // Dokunulmazlık efekti
    if (isInvulnerable) {
      _renderInvulnerabilityEffect(canvas, size, invulnerabilityTimer);
    }

    // Vurulma efekti
    if (hitAnimationTimer > 0) {
      _renderHitEffect(canvas, size, hitAnimationTimer);
    }

    canvas.restore();
  }

  // Kızılderili karakterini çizme fonksiyonu
  void _renderIndian(Canvas canvas) {
    canvas.save();

    // Koşma animasyonu için zaman hesaplama
    final runningTime = DateTime.now().millisecondsSinceEpoch / 150;
    final legOffset =
        state == PlayerState.running ? math.sin(runningTime) * 12 : 0;
    final armOffset =
        state == PlayerState.running ? math.cos(runningTime) * 10 : 0;
    final isJumpingOrFalling = state == PlayerState.jumping ||
        state == PlayerState.doubleJumping ||
        state == PlayerState.falling;

    // ------ KIZILDERILI KARAKTERİ ÇİZİMİ ------

    // Gölge efekti
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.x * 0.5, size.y * 0.97),
            width: size.x * 0.6,
            height: size.y * 0.1),
        shadowPaint);

    // Renk şeması
    final bodyColor = Color(0xFF8D6E63); // Kahverengi deri giysi
    final accentColor = Color(0xFFF44336); // Kırmızı vurgular
    final skinColor = Color(0xFFCD9B74); // Kızılderili ten rengi
    final featherColor = Color(0xFFFFFFFF); // Başlık tüyleri

    // ---- VÜCUT BÖLÜMLERİ ----

    // Bacaklar - koşma animasyonlu
    final legPaint = Paint()..color = bodyColor;

    // Sol bacak
    final leftLegPath = Path();
    final leftLegY = isJumpingOrFalling ? 10 : legOffset;
    leftLegPath.moveTo(size.x * 0.4, size.y * 0.6);
    leftLegPath.quadraticBezierTo(
        size.x * 0.35,
        size.y * (0.75 + leftLegY / 100),
        size.x * 0.3,
        size.y * (0.95 + leftLegY / 100));
    leftLegPath.lineTo(size.x * 0.4, size.y * (0.95 + leftLegY / 100));
    leftLegPath.quadraticBezierTo(size.x * 0.42,
        size.y * (0.75 + leftLegY / 100), size.x * 0.45, size.y * 0.6);
    leftLegPath.close();
    canvas.drawPath(leftLegPath, legPaint);

    // Sağ bacak
    final rightLegPath = Path();
    final rightLegY = isJumpingOrFalling ? 10 : -legOffset;
    rightLegPath.moveTo(size.x * 0.55, size.y * 0.6);
    rightLegPath.quadraticBezierTo(
        size.x * 0.6,
        size.y * (0.75 + rightLegY / 100),
        size.x * 0.65,
        size.y * (0.95 + rightLegY / 100));
    rightLegPath.lineTo(size.x * 0.55, size.y * (0.95 + rightLegY / 100));
    rightLegPath.quadraticBezierTo(size.x * 0.52,
        size.y * (0.75 + rightLegY / 100), size.x * 0.5, size.y * 0.6);
    rightLegPath.close();
    canvas.drawPath(rightLegPath, legPaint);

    // Vücut - Kızılderili kıyafeti
    final bodyPaint = Paint()..color = bodyColor; // Temel deri kıyafet
    final bodyPath = Path();
    bodyPath.moveTo(size.x * 0.4, size.y * 0.6);
    bodyPath.lineTo(size.x * 0.6, size.y * 0.6);
    bodyPath.lineTo(size.x * 0.65, size.y * 0.3);
    bodyPath.quadraticBezierTo(
        size.x * 0.5, size.y * 0.25, size.x * 0.35, size.y * 0.3);
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Kıyafet süslemeleri
    final decorPaint = Paint()..color = accentColor;

    // Göğüs süslemesi - şeritler
    for (int i = 0; i < 3; i++) {
      double y = size.y * (0.35 + i * 0.08);
      canvas.drawLine(Offset(size.x * 0.43, y), Offset(size.x * 0.57, y),
          decorPaint..strokeWidth = 2);
    }

    // Kolye
    final necklacePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.x * 0.5, size.y * 0.33),
            width: size.x * 0.3,
            height: size.y * 0.12),
        necklacePaint);

    // Kolye ucu - küçük mavi taş
    final stonePaint = Paint()..color = Colors.blue.shade600;
    canvas.drawCircle(
        Offset(size.x * 0.5, size.y * 0.39), size.x * 0.03, stonePaint);

    // Kafa - Kızılderili yüzü
    final headPaint = Paint()..color = skinColor;
    canvas.drawCircle(
        Offset(size.x * 0.5, size.y * 0.2), size.x * 0.15, headPaint);

    // Saç - siyah uzun saçlar
    final hairPaint = Paint()..color = Colors.black;
    final hairPath = Path();

    // Saç çizgisi
    hairPath.moveTo(size.x * 0.35, size.y * 0.15);
    hairPath.lineTo(size.x * 0.35, size.y * 0.4); // Sol omuz saçı
    hairPath.moveTo(size.x * 0.65, size.y * 0.15);
    hairPath.lineTo(size.x * 0.65, size.y * 0.4); // Sağ omuz saçı

    canvas.drawPath(hairPath, hairPaint..strokeWidth = 6);

    // Başlık bandı
    final headbandPaint = Paint()..color = accentColor;
    canvas.drawRect(
        Rect.fromLTWH(
            size.x * 0.35, size.y * 0.15, size.x * 0.3, size.y * 0.04),
        headbandPaint);

    // Tüy detayları
    final featherPath = Path();
    final windEffect = math.sin(_getAnimationTime() * 2) * 5;

    // Ana tüy
    featherPath.moveTo(size.x * 0.5, size.y * 0.15);
    featherPath.lineTo(size.x * (0.48 + windEffect / 100), size.y * 0.02);
    canvas.drawPath(
        featherPath,
        Paint()
          ..color = featherColor
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);

    // Tüy ucu
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.x * (0.48 + windEffect / 100), size.y * 0.02),
            width: size.x * 0.04,
            height: size.y * 0.05),
        Paint()..color = accentColor);

    // Yüz boyaları - savaş boyası
    final warPaintPath = Path();
    final warPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2;

    // Yüz boyaları - yatay çizgiler
    canvas.drawLine(Offset(size.x * 0.4, size.y * 0.22),
        Offset(size.x * 0.45, size.y * 0.22), warPaint);
    canvas.drawLine(Offset(size.x * 0.55, size.y * 0.22),
        Offset(size.x * 0.6, size.y * 0.22), warPaint);

    // Gözler
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawOval(
        Rect.fromLTWH(
            size.x * 0.42, size.y * 0.17, size.x * 0.06, size.y * 0.05),
        eyePaint);
    canvas.drawOval(
        Rect.fromLTWH(
            size.x * 0.52, size.y * 0.17, size.x * 0.06, size.y * 0.05),
        eyePaint);

    // Göz bebekleri
    final lookDirection = state == PlayerState.dashing ? 0.02 : 0.0;
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(size.x * (0.45 + lookDirection), size.y * 0.195),
        size.x * 0.02, pupilPaint);
    canvas.drawCircle(Offset(size.x * (0.55 + lookDirection), size.y * 0.195),
        size.x * 0.02, pupilPaint);

    // Ağız
    final mouthPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(size.x * 0.45, size.y * 0.27),
        Offset(size.x * 0.55, size.y * 0.27), mouthPaint);

    // Kollar - koşma animasyonlu veya ok atma
    final armPaint = Paint()..color = skinColor; // Çıplak kollar

    // Sol kol
    final leftArmPath = Path();
    leftArmPath.moveTo(size.x * 0.4, size.y * 0.35);
    leftArmPath.quadraticBezierTo(
        size.x * (0.3 - armOffset / 100),
        size.y * (0.4 - armOffset / 100),
        size.x * (0.25 - armOffset / 100),
        size.y * (0.5 - armOffset / 100));
    leftArmPath.lineTo(
        size.x * (0.3 - armOffset / 100), size.y * (0.55 - armOffset / 100));
    leftArmPath.quadraticBezierTo(size.x * (0.35 - armOffset / 100),
        size.y * (0.45 - armOffset / 100), size.x * 0.4, size.y * 0.4);
    leftArmPath.close();
    canvas.drawPath(leftArmPath, armPaint);

    // Kol bilekliği
    final braceletPaint = Paint()..color = accentColor;
    canvas.drawRect(
        Rect.fromLTWH(size.x * (0.25 - armOffset / 100),
            size.y * (0.45 - armOffset / 100), size.x * 0.05, size.y * 0.03),
        braceletPaint);

    // Sağ kol - ok tutan
    final rightArmPath = Path();

    // Yay çekme durumunda kolun açısını değiştir
    double armAngle = 0.0;
    if (isSwingingBlade) {
      // Ok atarken kolu yukarıdan aşağıya doğru hareket ettir
      armAngle = -math.pi * 0.5 + swingAngle;
    } else {
      // Normal kol pozisyonu
      armAngle = 0.0;
    }

    // Kola açı uygula
    double armX = size.x * 0.65;
    double armY = size.y * 0.40;

    if (isSwingingBlade) {
      // Sallama sırasında omuz bağlantısını sabit tut, dirsek ve bilek hareket etsin
      rightArmPath.moveTo(size.x * 0.6, size.y * 0.35);

      // Dirsek pozisyonu
      double elbowX =
          size.x * 0.6 + math.cos(armAngle - math.pi / 4) * size.x * 0.15;
      double elbowY =
          size.y * 0.35 + math.sin(armAngle - math.pi / 4) * size.x * 0.15;

      // Bilek pozisyonu
      double wristX = elbowX + math.cos(armAngle) * size.x * 0.2;
      double wristY = elbowY + math.sin(armAngle) * size.x * 0.2;

      rightArmPath.lineTo(elbowX, elbowY);
      rightArmPath.lineTo(wristX, wristY);
      rightArmPath.lineTo(wristX - 5, wristY + 5);
      rightArmPath.close();
    } else {
      // Normal kol çizimi
      rightArmPath.moveTo(size.x * 0.6, size.y * 0.35);
      rightArmPath.quadraticBezierTo(
          armX, armY, armX + size.x * 0.1, armY + size.y * 0.1);
      rightArmPath.lineTo(armX + size.x * 0.1, armY + size.y * 0.15);
      rightArmPath.quadraticBezierTo(
          armX, armY + size.y * 0.05, size.x * 0.6, size.y * 0.42);
      rightArmPath.close();
    }

    canvas.drawPath(rightArmPath, armPaint);

    // Sağ bileklik
    if (!isSwingingBlade) {
      canvas.drawRect(
          Rect.fromLTWH(armX + size.x * 0.05, armY + size.y * 0.1,
              size.x * 0.05, size.y * 0.03),
          braceletPaint);
    }

    // Silah çizimi - varsayılan olarak yay
    final weaponType = character.attributes['weaponType'] as String? ?? 'bow';

    switch (weaponType) {
      case 'sword':
        _drawSword(canvas, size, armAngle, isSwingingBlade);
        break;
      case 'axe':
        _drawAxe(canvas, size, armAngle, isSwingingBlade);
        break;
      case 'bow':
        _drawBow(canvas, size, armAngle, isSwingingBlade);
        break;
    }

    // Dokunulmazlık efekti
    if (isInvulnerable) {
      _renderInvulnerabilityEffect(canvas, size, invulnerabilityTimer);
    }

    // Vurulma efekti
    if (hitAnimationTimer > 0) {
      _renderHitEffect(canvas, size, hitAnimationTimer);
    }

    canvas.restore();
  }

  void _renderInvulnerabilityEffect(Canvas canvas, Vector2 size, double timer) {
    if ((timer * 10).floor() % 2 == 0) {
      final shieldPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      // Dalgalı kalkan efekti
      final shieldRadius = size.x * 0.6 + math.sin(_getAnimationTime() * 3) * 5;
      canvas.drawCircle(
          Offset(size.x * 0.5, size.y * 0.4), shieldRadius, shieldPaint);

      // Enerji dalgaları
      final energyPaint = Paint()
        ..color = Colors.blue.withOpacity(0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(
          Offset(size.x * 0.5, size.y * 0.4), shieldRadius * 0.8, energyPaint);
    }
  }

  void _renderHitEffect(Canvas canvas, Vector2 size, double timer) {
    final hitPaint = Paint()..color = Colors.red.withOpacity(0.3);

    // Darbe etkisi - dalga şeklinde yayılan
    final waveRadius = size.x * (1 - timer) * 2;
    canvas.drawCircle(Offset(size.x * 0.5, size.y * 0.4), waveRadius, hitPaint);

    // Tüm karakter üzerine kırmızı vurgu
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = Colors.red.withOpacity(0.2));
  }

  double _getAnimationTime() {
    return DateTime.now().millisecondsSinceEpoch / 300;
  }
}

// ArrowBulletComponent ekleyin, bu class dosyasının en altına ekleniyor
class ArrowBulletComponent extends BulletComponent {
  ArrowBulletComponent({
    required Bullet bullet,
    required Vector2 position,
    required Vector2 direction,
  }) : super(
          bullet: bullet,
          position: position,
          direction: direction,
        );

  @override
  void render(Canvas canvas) {
    // Ok çizimi - standart yuvarlaklardan farklı olarak gerçek bir ok şeklinde
    final arrowLength = bullet.size * 2.0;
    final arrowWidth = bullet.size * 0.4;

    // Ok gövdesi için boya
    final shaftPaint = Paint()
      ..color = Colors.brown.shade800
      ..style = PaintingStyle.fill;

    // Ok ucu için boya
    final headPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    // Ok tüyleri için boya
    final featherPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Çizim merkezi
    canvas.save();

    // Oku hareket yönüne doğru döndür
    final angle = math.atan2(direction.y, direction.x);
    canvas.rotate(angle);

    // Ok gövdesi (shaft)
    canvas.drawRect(
      Rect.fromLTWH(0, -arrowWidth / 2, arrowLength * 0.7, arrowWidth),
      shaftPaint,
    );

    // Ok ucu (arrowhead)
    final arrowHeadPath = Path();
    arrowHeadPath.moveTo(arrowLength * 0.7, -arrowWidth * 1.5);
    arrowHeadPath.lineTo(arrowLength, 0);
    arrowHeadPath.lineTo(arrowLength * 0.7, arrowWidth * 1.5);
    arrowHeadPath.close();
    canvas.drawPath(arrowHeadPath, headPaint);

    // Ok tüyleri (feathers)
    final featherPath = Path();
    featherPath.moveTo(0, -arrowWidth);
    featherPath.lineTo(arrowLength * 0.3, -arrowWidth * 2);
    featherPath.lineTo(arrowLength * 0.3, -arrowWidth / 2);
    featherPath.close();
    canvas.drawPath(featherPath, featherPaint);

    // Alt tüy
    final bottomFeatherPath = Path();
    bottomFeatherPath.moveTo(0, arrowWidth);
    bottomFeatherPath.lineTo(arrowLength * 0.3, arrowWidth * 2);
    bottomFeatherPath.lineTo(arrowLength * 0.3, arrowWidth / 2);
    bottomFeatherPath.close();
    canvas.drawPath(bottomFeatherPath, featherPaint);

    canvas.restore();
  }
}
