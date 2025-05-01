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

  // Oyun durumu
  PlayerState state = PlayerState.running;

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
    // Eğer yeniden dolduruyorsa ateş edemez
    if (isReloading) return;

    // Eğer ateş etme hızı zamanlayıcısı dolmuşsa ve mermi varsa ateş edebilir
    if (fireRateTimer <= 0 && ammoSystem.canShoot()) {
      // Mermi harca
      ammoSystem.shoot();

      // Ateş etme soğuma süresi
      fireRateTimer = 1.0 / currentWeapon.fireRate;

      // Mermisiz kaldıysa otomatik yeniden doldur
      if (!ammoSystem.canShoot()) {
        reload();
      }

      // gameRef null kontrolü ekleyelim
      if (gameRef == null) {
        print("HATA: gameRef null - ateş edilemiyor");
        return;
      }

      // Merminin çıkış konumunu hesapla (karakterin ön tarafından)
      final bulletPosition = Vector2(
        position.x + size.x * 0.3, // Silahın namlu pozisyonu
        position.y - size.y * 0.6, // Karakter boyunun üst kısmı (omuza yakın)
      );

      // Mermi yönünü belirle (sağa doğru)
      final bulletDirection = Vector2(1, 0);

      // Mermi oluştur
      final bullet = Bullet.fromWeapon(currentWeapon, isPowered: isPoweredUp);

      // Ateş etme durumu sırasında animasyon göster
      state = PlayerState.shooting;

      // Mermi component'i ekle
      gameRef.add(
        BulletComponent(
          bullet: bullet,
          position: bulletPosition,
          direction: bulletDirection,
        ),
      );

      // Ses efekti - kaldırıldı
      // gameRef.audioService.playSfx('shoot_${currentWeapon.type.toString().split('.').last}');

      // Ateş etme parçacık efekti (namlu parlaması vb.)
      // Parçacık sistemi null kontrolü ekleyelim
      if (gameRef.particleSystem != null) {
        _createMuzzleFlash(bulletPosition);
      }
    }
    // Mermi yoksa yeniden doldur
    else if (!ammoSystem.canShoot()) {
      reload();
    }
  }

  // Yeniden doldurma işlemi
  void reload() {
    if (!isReloading && ammoSystem.currentAmmo < currentWeapon.ammoCapacity) {
      isReloading = true;
      reloadTimer = currentWeapon.reloadTime;

      // Ses efekti - kaldırıldı
      // gameRef.audioService.playSfx('reload');
    }
  }

  // Güçlendirilmiş mermi modunu aç
  void powerUpWeapon(double duration) {
    isPoweredUp = true;
    poweredUpTimer = duration;
  }

  // Silahı değiştir
  void changeWeapon(WeaponType type) {
    currentWeapon = Weapon.fromType(type);

    // Ses efekti - kaldırıldı
    // gameRef.audioService.playSfx('weapon_change');
  }

  // Mermi ekle
  void addAmmo(int amount) {
    ammoSystem.reload(amount);

    // Ses efekti - kaldırıldı
    // gameRef.audioService.playSfx('ammo_pickup');
  }

  // Namlu parlaması efekti
  void _createMuzzleFlash(Vector2 position) {
    // Silah tipine göre renk ve büyüklük belirle
    Color muzzleColor;
    double muzzleSize;

    switch (currentWeapon.type) {
      case WeaponType.laserGun:
        muzzleColor = Colors.blue;
        muzzleSize = 15.0;
        break;
      case WeaponType.shotgun:
        muzzleColor = Colors.orange;
        muzzleSize = 12.0;
        break;
      case WeaponType.rifle:
        muzzleColor = Colors.red;
        muzzleSize = 10.0;
        break;
      case WeaponType.pistol:
      default:
        muzzleColor = Colors.yellow;
        muzzleSize = 8.0;
        break;
    }

    // Namlu parlaması parçacıklarını oluştur
    gameRef.particleSystem?.emit(
      count: 10,
      position: position,
      colors: [muzzleColor, Colors.white, Colors.yellow.shade600],
      size: Vector2(muzzleSize, muzzleSize),
      speed: 60,
      lifespan: 0.2,
    );
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
    final ninjaMainColor = Colors.black;
    final ninjaAccentColor = Colors.red.shade800;
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

    // Kollar - koşma animasyonlu
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

    // Sağ kol - silah tutan
    final rightArmPath = Path();
    rightArmPath.moveTo(size.x * 0.6, size.y * 0.35);
    rightArmPath.quadraticBezierTo(size.x * (0.65 + armOffset / 100),
        size.y * 0.4, size.x * (0.7 + armOffset / 100), size.y * 0.45);
    rightArmPath.lineTo(size.x * (0.7 + armOffset / 100), size.y * 0.5);
    rightArmPath.quadraticBezierTo(size.x * (0.65 + armOffset / 100),
        size.y * 0.45, size.x * 0.6, size.y * 0.42);
    rightArmPath.close();
    canvas.drawPath(rightArmPath, armPaint);

    // Silah çizimi - silah tipine göre farklı
    _renderWeapon(canvas, size, currentWeapon.type);

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

  // Silah çizim metodu - silah tipine göre farklı tasarımlar
  void _renderWeapon(Canvas canvas, Vector2 size, WeaponType type) {
    switch (type) {
      case WeaponType.pistol:
        _renderPistol(canvas, size);
        break;
      case WeaponType.rifle:
        _renderRifle(canvas, size);
        break;
      case WeaponType.shotgun:
        _renderShotgun(canvas, size);
        break;
      case WeaponType.laserGun:
        _renderLaserGun(canvas, size);
        break;
      default:
        _renderPistol(canvas, size);
    }
  }

  void _renderPistol(Canvas canvas, Vector2 size) {
    final gunPaint = Paint()..color = Colors.grey.shade800;

    // Tabanca gövdesi
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                size.x * 0.68, size.y * 0.44, size.x * 0.2, size.y * 0.08),
            Radius.circular(3)),
        gunPaint);

    // Kabza
    canvas.drawRect(
        Rect.fromLTWH(
            size.x * 0.7, size.y * 0.44, size.x * 0.04, size.y * 0.15),
        gunPaint);

    // Namlu
    canvas.drawRect(
        Rect.fromLTWH(
            size.x * 0.84, size.y * 0.42, size.x * 0.1, size.y * 0.05),
        gunPaint);
  }

  void _renderRifle(Canvas canvas, Vector2 size) {
    final gunPaint = Paint()..color = Colors.grey.shade700;

    // Tüfek gövdesi
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                size.x * 0.68, size.y * 0.43, size.x * 0.35, size.y * 0.07),
            Radius.circular(2)),
        gunPaint);

    // Namlu
    canvas.drawRect(
        Rect.fromLTWH(
            size.x * 0.97, size.y * 0.42, size.x * 0.15, size.y * 0.04),
        gunPaint);

    // Dipçik
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                size.x * 0.68, size.y * 0.45, size.x * 0.05, size.y * 0.15),
            Radius.circular(2)),
        gunPaint);

    // Şarjör
    canvas.drawRect(
        Rect.fromLTWH(size.x * 0.8, size.y * 0.5, size.x * 0.04, size.y * 0.1),
        Paint()..color = Colors.grey.shade600);
  }

  void _renderShotgun(Canvas canvas, Vector2 size) {
    final gunPaint = Paint()..color = Colors.brown.shade800;

    // Pompalı gövde
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                size.x * 0.68, size.y * 0.42, size.x * 0.3, size.y * 0.1),
            Radius.circular(3)),
        gunPaint);

    // Uzun namlu
    canvas.drawRect(
        Rect.fromLTWH(
            size.x * 0.94, size.y * 0.43, size.x * 0.2, size.y * 0.04),
        gunPaint);

    // Dipçik
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                size.x * 0.68, size.y * 0.47, size.x * 0.06, size.y * 0.12),
            Radius.circular(3)),
        gunPaint);

    // Metal detaylar
    canvas.drawRect(
        Rect.fromLTWH(
            size.x * 0.75, size.y * 0.42, size.x * 0.02, size.y * 0.1),
        Paint()..color = Colors.grey.shade700);
  }

  void _renderLaserGun(Canvas canvas, Vector2 size) {
    final gunPaint = Paint()..color = Colors.blue.shade800;

    // Lazer gövdesi
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                size.x * 0.68, size.y * 0.4, size.x * 0.25, size.y * 0.1),
            Radius.circular(5)),
        gunPaint);

    // Lazer namlu
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                size.x * 0.9, size.y * 0.43, size.x * 0.15, size.y * 0.04),
            Radius.circular(5)),
        Paint()..color = Colors.blue.shade500);

    // Enerji hücresi
    canvas.drawCircle(Offset(size.x * 0.75, size.y * 0.45), size.x * 0.05,
        Paint()..color = Colors.blue.shade300);

    // Enerji ışık efekti
    canvas.drawCircle(
        Offset(size.x * 1.05, size.y * 0.45),
        size.x * 0.03,
        Paint()
          ..color = Colors.lightBlue.shade100
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5));
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
