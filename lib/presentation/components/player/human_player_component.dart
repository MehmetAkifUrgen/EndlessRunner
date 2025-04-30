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
      _createMuzzleFlash(bulletPosition);
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
    // Daha detaylı insan figürü çiz
    canvas.save();

    // Cinsiyete göre değişik karakterler (rastgele atadık)
    final isMale = character.id == 'ninja' ||
        character.id == 'soldier' ||
        character.id == 'knight';

    // Gövde
    final bodyPaint = Paint()..color = primaryColor;
    final bodyRect =
        Rect.fromLTWH(size.x * 0.3, size.y * 0.3, size.x * 0.4, size.y * 0.38);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(size.x * 0.1)),
      bodyPaint,
    );

    // Kafa
    final headPaint = Paint()..color = Color(0xFFFAD7C0); // ten rengi
    final headCenter = Offset(size.x * 0.5, size.y * 0.18);
    final headRadius = size.x * 0.18;
    canvas.drawCircle(headCenter, headRadius, headPaint);

    // Saç
    final hairPaint = Paint()..color = Colors.brown.shade800;
    if (isMale) {
      // Erkek saç stili
      final hairPath = Path();
      hairPath.moveTo(
          headCenter.dx - headRadius, headCenter.dy - headRadius * 0.5);
      hairPath.lineTo(headCenter.dx - headRadius, headCenter.dy - headRadius);
      hairPath.lineTo(headCenter.dx + headRadius, headCenter.dy - headRadius);
      hairPath.lineTo(
          headCenter.dx + headRadius, headCenter.dy - headRadius * 0.5);
      hairPath.close();
      canvas.drawPath(hairPath, hairPaint);
    } else {
      // Kadın saç stili (daha uzun)
      final hairPath = Path();
      hairPath.moveTo(
          headCenter.dx - headRadius, headCenter.dy - headRadius * 0.2);
      hairPath.lineTo(headCenter.dx - headRadius, headCenter.dy - headRadius);
      hairPath.lineTo(headCenter.dx + headRadius, headCenter.dy - headRadius);
      hairPath.lineTo(
          headCenter.dx + headRadius, headCenter.dy - headRadius * 0.2);
      hairPath.close();
      canvas.drawPath(hairPath, hairPaint);

      // Saçın yan kısımları
      canvas.drawRect(
          Rect.fromLTWH(headCenter.dx - headRadius - 2,
              headCenter.dy - headRadius * 0.5, 4, headRadius * 1.2),
          hairPaint);
      canvas.drawRect(
          Rect.fromLTWH(headCenter.dx + headRadius - 2,
              headCenter.dy - headRadius * 0.5, 4, headRadius * 1.2),
          hairPaint);
    }

    // Gözler
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = Colors.black;

    // Sol göz
    canvas.drawCircle(
        Offset(
            headCenter.dx - headRadius * 0.4, headCenter.dy - headRadius * 0.1),
        headRadius * 0.18,
        eyePaint);
    canvas.drawCircle(
        Offset(
            headCenter.dx - headRadius * 0.4, headCenter.dy - headRadius * 0.1),
        headRadius * 0.08,
        pupilPaint);

    // Sağ göz
    canvas.drawCircle(
        Offset(
            headCenter.dx + headRadius * 0.4, headCenter.dy - headRadius * 0.1),
        headRadius * 0.18,
        eyePaint);
    canvas.drawCircle(
        Offset(
            headCenter.dx + headRadius * 0.4, headCenter.dy - headRadius * 0.1),
        headRadius * 0.08,
        pupilPaint);

    // Ağız
    final mouthPaint = Paint()
      ..color = Colors.red.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final mouthPath = Path();
    mouthPath.moveTo(
        headCenter.dx - headRadius * 0.3, headCenter.dy + headRadius * 0.3);
    mouthPath.quadraticBezierTo(headCenter.dx, headCenter.dy + headRadius * 0.5,
        headCenter.dx + headRadius * 0.3, headCenter.dy + headRadius * 0.3);
    canvas.drawPath(mouthPath, mouthPaint);

    // Kollar ve bacaklar
    final limbPaint = Paint()..color = secondaryColor;

    // Sol kol
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                size.x * 0.2, size.y * 0.35, size.x * 0.1, size.y * 0.25),
            Radius.circular(size.x * 0.05)),
        limbPaint);

    // Sağ kol - silah tutma pozisyonu
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                size.x * 0.7, size.y * 0.35, size.x * 0.1, size.y * 0.25),
            Radius.circular(size.x * 0.05)),
        limbPaint);

    // Sol bacak
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                size.x * 0.33, size.y * 0.68, size.x * 0.14, size.y * 0.32),
            Radius.circular(size.x * 0.05)),
        limbPaint);

    // Sağ bacak
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                size.x * 0.53, size.y * 0.68, size.x * 0.14, size.y * 0.32),
            Radius.circular(size.x * 0.05)),
        limbPaint);

    // Silah çizimi (sağ kolun ucunda)
    final weaponPaint = Paint()..color = Colors.grey.shade800;

    if (currentWeapon.type == WeaponType.pistol) {
      // Tabanca
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  size.x * 0.78, size.y * 0.4, size.x * 0.2, size.y * 0.08),
              Radius.circular(size.x * 0.02)),
          weaponPaint);
      // Tabanca sapı
      canvas.drawRect(
          Rect.fromLTWH(
              size.x * 0.82, size.y * 0.4, size.x * 0.06, size.y * 0.15),
          weaponPaint);
    } else if (currentWeapon.type == WeaponType.rifle) {
      // Tüfek
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  size.x * 0.78, size.y * 0.38, size.x * 0.35, size.y * 0.07),
              Radius.circular(size.x * 0.01)),
          weaponPaint);
      // Tüfek sapı
      canvas.drawRect(
          Rect.fromLTWH(
              size.x * 0.85, size.y * 0.38, size.x * 0.06, size.y * 0.15),
          weaponPaint);
    } else if (currentWeapon.type == WeaponType.shotgun) {
      // Pompalı
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  size.x * 0.78, size.y * 0.37, size.x * 0.3, size.y * 0.1),
              Radius.circular(size.x * 0.01)),
          weaponPaint);
      // Pompalı sapı
      canvas.drawRect(
          Rect.fromLTWH(
              size.x * 0.85, size.y * 0.37, size.x * 0.07, size.y * 0.18),
          weaponPaint);
    } else if (currentWeapon.type == WeaponType.laserGun) {
      // Lazer silahı
      final laserGunPaint = Paint()..color = Colors.blue.shade700;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  size.x * 0.78, size.y * 0.37, size.x * 0.25, size.y * 0.1),
              Radius.circular(size.x * 0.05)),
          laserGunPaint);
      // Lazer ucu
      final laserTipPaint = Paint()..color = Colors.blue.shade400;
      canvas.drawCircle(
          Offset(size.x * 1.03, size.y * 0.42), size.x * 0.04, laserTipPaint);
    }

    // Dokunulmazlık efekti
    if (isInvulnerable) {
      final shieldPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      if ((invulnerabilityTimer * 10).floor() % 2 == 0) {
        canvas.drawCircle(
            Offset(size.x * 0.5, size.y * 0.4), size.x * 0.6, shieldPaint);
      }
    }

    // Vurulma efekti
    if (hitAnimationTimer > 0) {
      final hitPaint = Paint()..color = Colors.red.withOpacity(0.3);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), hitPaint);
    }

    canvas.restore();
  }
}
