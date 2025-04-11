import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/obstacle.dart';
import '../models/collectible.dart';
import 'dart:math';

class RunnerGame extends FlameGame with HasCollisionDetection {
  late PlayerComponent player;
  late TextComponent scoreText;
  late Timer obstacleSpawnTimer;
  late Timer collectibleSpawnTimer;

  int score = 0;
  int lives = 3;
  bool isGameOver = false;
  bool isPaused = false;
  double gameSpeed = 200; // pixel/saniye
  double groundHeight = 50;

  final List<ObstacleComponent> obstacles = [];
  final List<CollectibleComponent> collectibles = [];

  // State değişikliklerini bildirmek için callback
  VoidCallback? onLifeLost;
  VoidCallback? onGameOver;

  // Zorluk seviyeleri için ekstra değişkenler
  double gameTime = 0; // Toplam oyun süresi
  double gameSpeedIncreaseRate = 10; // Saniyede artış hızı
  double maxGameSpeed = 400; // Maksimum hız limiti
  double difficultyMultiplier = 1.0; // Zorluk çarpanı
  int combo = 0; // Combo sistemi
  int maxCombo = 0; // En yüksek combo

  // Güç-yükseltmeleri için değişkenler
  bool hasMagnet = false;
  double magnetTimer = 0;
  bool hasShield = false;
  double shieldTimer = 0;
  bool hasSlowMotion = false;
  double slowMotionTimer = 0;

  @override
  Future<void> onLoad() async {
    // Arkaplan - Gradient ile zenginleştirme
    add(
      RectangleComponent(
        size: Vector2(size.x, size.y),
        paint: Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.deepPurple],
          ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)),
      ),
    );

    // Yer zemini
    add(
      RectangleComponent(
        size: Vector2(size.x, groundHeight),
        position: Vector2(0, size.y - groundHeight),
        paint: Paint()..color = Colors.green.shade800,
      ),
    );

    // Bulutlar (dekortif elementler)
    _addClouds();

    // Oyuncu
    player = PlayerComponent(
      position: Vector2(size.x * 0.2, size.y - groundHeight - 30),
      game: this,
    );
    // Oyuncunun başlangıçta yerde olduğunu garantilemek için
    player.isOnGround = true;
    player.isJumping = false;
    add(player);

    print(
        "Player başlangıç konumu: ${player.position}, isOnGround: ${player.isOnGround}");

    // Skor metni - Gölgeli ve daha görünür
    scoreText = TextComponent(
      text: 'SCORE: $score',
      textRenderer: TextPaint(
        style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))
            ]),
      ),
      position: Vector2(20, 20),
    );
    add(scoreText);

    // Engel oluşturma zamanlayıcısı
    obstacleSpawnTimer = Timer(
      2,
      onTick: _spawnObstacle,
      repeat: true,
    );

    // Toplanabilir oluşturma zamanlayıcısı
    collectibleSpawnTimer = Timer(
      3,
      onTick: _spawnCollectible,
      repeat: true,
    );

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (isPaused || isGameOver) return;

    // Oyun süresini güncelle
    gameTime += dt;

    // Oyun hızını zamanla artır (zorluk arttırma)
    gameSpeed = math.min(
        gameSpeed + gameSpeedIncreaseRate * dt * difficultyMultiplier,
        maxGameSpeed);

    // Güç-yükseltmelerini güncelle
    _updatePowerUps(dt);

    obstacleSpawnTimer.update(dt);
    collectibleSpawnTimer.update(dt);

    // Engelleri hareket ettir
    for (var obstacle in [...obstacles]) {
      obstacle.position.x -= gameSpeed * dt;

      // Ekrandan çıkan engelleri kaldır
      if (obstacle.position.x < -obstacle.size.x) {
        obstacles.remove(obstacle);
        remove(obstacle);

        // Engeli geçince puan ekle
        increaseScore(5);
      }
    }

    // Toplanabilirleri hareket ettir
    for (var collectible in [...collectibles]) {
      collectible.position.x -= gameSpeed * dt;

      // Ekrandan çıkan toplanabilirleri kaldır
      if (collectible.position.x < -collectible.size.x) {
        collectibles.remove(collectible);
        remove(collectible);
      }
    }

    super.update(dt);
  }

  void _spawnObstacle() {
    if (isPaused || isGameOver) return;

    final rng = math.Random();
    final type = ObstacleType.values[rng.nextInt(ObstacleType.values.length)];

    // Engellerin çeşitliliğini arttır
    final obstacle = ObstacleComponent(
      position: Vector2(size.x + 50, size.y - groundHeight - 30),
      type: type,
    );

    add(obstacle);
    obstacles.add(obstacle);
  }

  void _spawnCollectible() {
    if (isPaused || isGameOver) return;

    // Rastgele yükseklik
    final rng = math.Random();
    final height = rng.nextDouble() * 150 + 50;

    // Farklı toplama öğeleri ekle - daha çeşitli
    CollectibleType type;
    double typeRoll = rng.nextDouble();

    if (typeRoll < 0.05) {
      type = CollectibleType.extraLife; // %5 şansla extra can
    } else if (typeRoll < 0.10) {
      type = CollectibleType.shield; // %5 şansla kalkan
    } else if (typeRoll < 0.15) {
      type = CollectibleType.magnet; // %5 şansla mıknatıs
    } else if (typeRoll < 0.18) {
      type = CollectibleType.slowMotion; // %3 şansla yavaş çekim
    } else if (typeRoll < 0.25) {
      type = CollectibleType.scoreBoost; // %7 şansla skor artışı
    } else {
      type = CollectibleType.coin; // %75 şansla altın
    }

    final collectible = CollectibleComponent(
      position: Vector2(size.x + 50, size.y - groundHeight - height),
      type: type,
    );

    add(collectible);
    collectibles.add(collectible);
  }

  // Combo sistemini güncelle
  void increaseCombo() {
    combo++;
    if (combo > maxCombo) {
      maxCombo = combo;
    }

    // Her 5 combo'da ekstra puan
    if (combo % 5 == 0) {
      increaseScore(combo * 2);
    }
  }

  // Combo'yu sıfırla
  void resetCombo() {
    combo = 0;
  }

  void increaseScore(int amount) {
    // Mevcut combo'ya göre puan artışını ayarla
    final int bonusAmount = (amount * (1 + combo * 0.1)).toInt();
    score += bonusAmount;
    scoreText.text = 'SCORE: $score';
  }

  void loseLife() {
    lives--;
    print("Life lost! Remaining lives: $lives");

    // Can kaybedilince combo sıfırla
    resetCombo();

    // Can kaybedildiğini bildir
    onLifeLost?.call();

    if (lives <= 0) {
      gameOver();
    }
  }

  void gameOver() {
    isGameOver = true;
    print("GAME OVER! Total score: $score");

    // Oyun bittiğini bildir
    onGameOver?.call();
  }

  // Doğrudan zıplama başlatmak için metod
  void startPlayerJumpCharge() {
    player.startJumpCharge();
  }

  // Doğrudan zıplama bitirmek için metod
  void executePlayerJump() {
    player.executeJump();
  }

  // Bulutlar ekle (dekorasyon)
  void _addClouds() {
    final rng = math.Random();
    for (int i = 0; i < 5; i++) {
      final cloudSize = 20.0 + rng.nextDouble() * 40;
      final cloud = CloudComponent(
        position: Vector2(
          rng.nextDouble() * size.x,
          rng.nextDouble() * size.y * 0.5,
        ),
        size: Vector2(cloudSize * 2, cloudSize),
      );
      add(cloud);
    }
  }

  // Hayat ekleme metodu
  void addLife() {
    if (lives < 3) {
      lives++;
    }
  }

  // Güç-yükseltmelerini güncelle
  void _updatePowerUps(double dt) {
    // Mıknatıs etkisini güncelle
    if (hasMagnet) {
      magnetTimer -= dt;
      if (magnetTimer <= 0) {
        hasMagnet = false;
      } else {
        _attractCollectibles();
      }
    }

    // Kalkan etkisini güncelle
    if (hasShield) {
      shieldTimer -= dt;
      if (shieldTimer <= 0) {
        hasShield = false;
        player.isInvincible = false;
      }
    }

    // Yavaş çekim etkisini güncelle
    if (hasSlowMotion) {
      slowMotionTimer -= dt;
      if (slowMotionTimer <= 0) {
        hasSlowMotion = false;
        difficultyMultiplier = 1.0; // Normal hıza dön
      }
    }
  }

  // Paraları mıknatıs gibi çek
  void _attractCollectibles() {
    for (var collectible in collectibles) {
      // Oyuncuya belirli mesafede olan paraları çek
      final distance = player.position.distanceTo(collectible.position);
      if (distance < 200 && collectible.type == CollectibleType.coin) {
        // Oyuncuya doğru hareket ettir
        final direction = (player.position - collectible.position).normalized();
        collectible.position += direction * 5;
      }
    }
  }

  // Mıknatıs etkisini aktifleştir
  void activateMagnet(double duration) {
    hasMagnet = true;
    magnetTimer = duration;
  }

  // Kalkan etkisini aktifleştir
  void activateShield(double duration) {
    hasShield = true;
    shieldTimer = duration;
    player.isInvincible = true;
  }

  // Yavaş çekim etkisini aktifleştir
  void activateSlowMotion(double duration) {
    hasSlowMotion = true;
    slowMotionTimer = duration;
    difficultyMultiplier = 0.5; // Yarı hıza düşür
  }
}

class PlayerComponent extends PositionComponent with CollisionCallbacks {
  final double minJumpVelocity = -400; // Minimum zıplama yüksekliği
  final double maxJumpVelocity = -800; // Maksimum zıplama yüksekliği
  final double gravity = 1500; // Yerçekimi
  double velocityY = 0;
  bool isJumping = false;
  bool isOnGround = true;
  bool isInvincible = false;
  double invincibleTimer = 0;
  final RunnerGame game;
  final Paint playerPaint = Paint()..color = Colors.red;

  // Zıplama için değişkenler
  double jumpChargeDuration = 0;
  double maxChargeTime = 0.8; // saniye cinsinden maksimum şarj süresi
  bool isChargingJump = false;

  // Yeni hareket mekanikleri için değişkenler
  bool canDoubleJump = true; // Çift zıplama yapabilir mi
  bool isSliding = false; // Kayma hareketi yapıyor mu
  double slideTimer = 0; // Kayma süresi
  final double maxSlideTime = 0.6; // Maksimum kayma süresi
  bool isDashing = false; // Dash yapıyor mu
  double dashTimer = 0; // Dash süresi
  final double maxDashTime = 0.4; // Maksimum dash süresi
  double dashSpeed = 600; // Dash hızı
  double dashCooldown = 0; // Dash bekleme süresi
  final double maxDashCooldown = 2.0; // Dash bekleme süresi

  PlayerComponent({required Vector2 position, required this.game})
      : super(
          position: position,
          size: Vector2(40, 60),
          anchor: Anchor.bottomLeft,
        ) {
    // Çarpışma kutusu ekle
    final hitbox = RectangleHitbox.relative(
      Vector2(0.8, 0.9), // 80% genişlik, 90% yükseklik
      parentSize: size,
      position: Vector2(size.x * 0.1, size.y * 0.1), // hizalama
    );
    add(hitbox);

    // Başlangıçta yerde olduğunu garantile
    isOnGround = true;
    isJumping = false;
    velocityY = 0;
  }

  @override
  void update(double dt) {
    // Zıplama şarj ediliyorsa zamanı artır
    if (isChargingJump && isOnGround) {
      // Şarj süresini artır
      jumpChargeDuration += dt;
      // Maksimum şarj süresini kontrol et
      jumpChargeDuration = math.min(jumpChargeDuration, maxChargeTime);

      double chargePercent = jumpChargeDuration / maxChargeTime;

      // Görsel geri bildirim - karakter basılı tutulduğunda şekil değiştirsin
      scale = Vector2(1.1 + chargePercent * 0.1, 0.9 - chargePercent * 0.1);
    }

    // Yerçekimi ve zıplama fiziği
    if (!isOnGround) {
      velocityY += gravity * dt;
      position.y += velocityY * dt;

      // Yere değme kontrolü
      if (position.y >=
          game.size.y - game.groundHeight - height + (size.y * 0.1)) {
        position.y = game.size.y - game.groundHeight - height + (size.y * 0.1);
        isJumping = false;
        isOnGround = true;
        canDoubleJump = true; // Yere değdiğinde çift zıplama hakkı yenilenir
        velocityY = 0;
        scale = Vector2.all(1); // Normal boyuta dön
        print("Yere indi! isOnGround: $isOnGround");
      }
    } else {
      // Oyuncu yerde ama pozisyonu zemin seviyesinde değilse düzelt
      if (position.y <
          game.size.y - game.groundHeight - height + (size.y * 0.1)) {
        position.y = game.size.y - game.groundHeight - height + (size.y * 0.1);
      }
    }

    // Dash bekleme süresini azalt
    if (dashCooldown > 0) {
      dashCooldown -= dt;
    }

    // Dash kontrolü
    if (isDashing) {
      dashTimer -= dt;
      if (dashTimer <= 0) {
        isDashing = false;
      } else {
        // Dash sırasında ileri hareket et
        position.x += dashSpeed * dt;

        // Ekran dışına çıkmasını önle
        if (position.x > game.size.x - width) {
          position.x = game.size.x - width;
          isDashing = false;
        }
      }
    }

    // Kayma kontrolü
    if (isSliding) {
      slideTimer -= dt;
      if (slideTimer <= 0) {
        isSliding = false;
        size = Vector2(40, 60); // Normal boyuta dön
        // Çarpışma kutusunu güncelle
        removeAll(children.whereType<RectangleHitbox>());
        final hitbox = RectangleHitbox.relative(
          Vector2(0.9, 0.7),
          parentSize: size,
          position: Vector2(size.x * 0.05, size.y * 0.15),
        );
        add(hitbox);
      }
    }

    // Çarpışmadan sonra yanıp sönme efekti için dokunulmazlık süresi
    if (isInvincible) {
      invincibleTimer -= dt;
      // Yanıp sönme efekti
      playerPaint.color = (invincibleTimer * 10).floor() % 2 == 0
          ? Colors.red.withOpacity(0.5)
          : Colors.red;

      if (invincibleTimer <= 0) {
        isInvincible = false;
        playerPaint.color = Colors.red;
      }
    }

    super.update(dt);
  }

  // Zıplama şarjını başlat
  void startJumpCharge() {
    print("startJumpCharge çağrıldı! isOnGround: $isOnGround");
    if (isOnGround && !isJumping && !isSliding) {
      print("Zıplama şarjı başlatılıyor");
      isChargingJump = true;
      jumpChargeDuration = 0; // Şarj süresini sıfırla

      // Basılı tutulduğunda bir görsel geri bildirim için boyutu değiştir
      scale = Vector2(1.1, 0.9); // Hafif basılmış görünüm
    } else if (!isOnGround && canDoubleJump && !isSliding) {
      // Havadayken çift zıplama
      print("Çift zıplama yapılıyor");
      doubleJump();
    }
  }

  // Zıplamayı gerçekleştir
  void executeJump() {
    print(
        "executeJump çağrıldı! isOnGround: $isOnGround, isChargingJump: $isChargingJump");
    if (isOnGround && !isSliding) {
      // Şarj süresine göre zıplama hızını hesapla
      double jumpVelocity = minJumpVelocity;

      if (isChargingJump) {
        double chargePercent = jumpChargeDuration / maxChargeTime;
        jumpVelocity = minJumpVelocity +
            (maxJumpVelocity - minJumpVelocity) * chargePercent;
      }

      print("Zıplama hızı: $jumpVelocity");
      isJumping = true;
      isOnGround = false;
      isChargingJump = false;
      velocityY = jumpVelocity;

      // Zıplama animasyonu için ölçeklendirme
      scale = Vector2.all(1);
    } else if (isChargingJump) {
      // Eğer zıplama şarjı başladıysa ama oyuncu yerde değilse
      isChargingJump = false;
      scale = Vector2.all(1); // Normal boyuta dön
    }
  }

  // Temel zıplama (isChargingJump kullanmadan)
  void jump() {
    print("jump çağrıldı! isOnGround: $isOnGround");
    if (isOnGround && !isSliding) {
      print("Zıplama gerçekleşiyor!");
      isJumping = true;
      isOnGround = false;
      velocityY = -500; // Sabit yüksek zıplama gücü kullan
      scale = Vector2.all(1);
    } else if (!isOnGround && canDoubleJump && !isSliding) {
      print("Çift zıplama gerçekleşiyor!");
      doubleJump();
    }
  }

  // Çift zıplama
  void doubleJump() {
    if (canDoubleJump && !isOnGround && !isSliding) {
      velocityY = minJumpVelocity * 0.8; // İlk zıplamadan biraz daha az güçlü
      canDoubleJump = false; // Çift zıplama hakkını kullan

      // Efekt için görsel geri bildirim
      scale = Vector2(1.2, 0.8); // Sıkışıp genişleme efekti
      Future.delayed(Duration(milliseconds: 100), () {
        if (!isRemoved) {
          scale = Vector2.all(1.0); // Normal boyuta dön
        }
      });
    }
  }

  // Kayma hareketi
  void slide() {
    if (isOnGround && !isSliding && !isChargingJump) {
      isSliding = true;
      slideTimer = maxSlideTime;

      // Kayarken boyutu değiştir (alçak ve uzun)
      size = Vector2(60, 30);

      // Çarpışma kutusunu güncelle
      removeAll(children.whereType<RectangleHitbox>());
      final hitbox = RectangleHitbox.relative(
        Vector2(0.9, 0.7),
        parentSize: size,
        position: Vector2(size.x * 0.05, size.y * 0.15),
      );
      add(hitbox);
    }
  }

  // Dash/ileri atılma hareketi
  void dash() {
    if (!isDashing && dashCooldown <= 0) {
      isDashing = true;
      dashTimer = maxDashTime;
      dashCooldown = maxDashCooldown;

      // Dash efekti için görsel geri bildirim
      playerPaint.color = Colors.blue; // Dash sırasında renk değişimi
      Future.delayed(Duration(milliseconds: 400), () {
        if (!isRemoved && !isInvincible) {
          playerPaint.color = Colors.red; // Normal renge dön
        }
      });
    }
  }

  @override
  void render(Canvas canvas) {
    // Oyuncu görsel efekti - koşan adam şekli
    final bodyRect = Rect.fromLTWH(5, 0, width - 10, height * 0.6);
    final headRadius = width * 0.3;
    final headCenter = Offset(width * 0.5, height * 0.25);

    // Gövde
    canvas.drawRect(bodyRect, playerPaint);
    // Kafa
    canvas.drawCircle(headCenter, headRadius, playerPaint);

    // Koşma animasyonu için bacaklar
    final legMovement = (game.score / 10).floor() % 2 == 0 ? 10.0 : -10.0;
    final leg1 = RRect.fromLTRBR(
        width * 0.3, height * 0.6, width * 0.45, height, Radius.circular(5));
    final leg2 = RRect.fromLTRBR(width * 0.55, height * 0.6, width * 0.7,
        height - legMovement, Radius.circular(5));

    canvas.drawRRect(leg1, playerPaint);
    canvas.drawRRect(leg2, playerPaint);

    super.render(canvas);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    // Çarpışma kontrollerini onCollisionStart'a taşıyalım
    if (other is ObstacleComponent && !isInvincible) {
      print("Engele çarpıldı: $other");
      game.loseLife();

      // Engeli gizle (silmek yerine)
      other.removeFromParent();
      game.obstacles.remove(other);

      // Çarpıştıktan sonra kısa bir süre dokunulmazlık
      isInvincible = true;
      invincibleTimer = 1.5; // 1.5 saniyelik dokunulmazlık
    }

    if (other is CollectibleComponent) {
      // Toplama öğesi tipine göre farklı bonuslar
      switch (other.type) {
        case CollectibleType.coin:
          game.increaseScore(10);
          game.increaseCombo(); // Altın topladıkça combo artar
          break;
        case CollectibleType.extraLife:
          game.addLife();
          break;
        case CollectibleType.shield:
          // Kalkan etkisi - geçici dokunulmazlık
          game.activateShield(5.0); // 5 saniyelik dokunulmazlık
          break;
        case CollectibleType.magnet:
          // Mıknatıs etkisi - para çekme özelliği
          game.activateMagnet(8.0); // 8 saniyelik mıknatıs etkisi
          break;
        case CollectibleType.slowMotion:
          // Yavaş çekim - engelleri yavaşlat
          game.activateSlowMotion(5.0); // 5 saniyelik yavaşlama
          break;
        case CollectibleType.scoreBoost:
          // Puan artışı
          game.increaseScore(50);
          game.increaseCombo();
          game.increaseCombo(); // Extra combo artışı
          break;
        default:
          game.increaseScore(5); // Bilinmeyen toplanabilirler için az puan
      }

      // Toplanan nesneyi gizle
      other.removeFromParent();
      game.collectibles.remove(other);
    }

    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    // Bu metodu boş bırakıyoruz, onCollisionStart kullanacağız
    super.onCollision(intersectionPoints, other);
  }
}

class ObstacleComponent extends PositionComponent with CollisionCallbacks {
  final Paint obstaclePaint = Paint();
  final ObstacleType type;

  ObstacleComponent({
    required Vector2 position,
    this.type = ObstacleType.cube,
  }) : super(position: position, anchor: Anchor.bottomLeft) {
    // Engel tipine göre farklı boyut ve renkler
    switch (type) {
      case ObstacleType.cube:
        size = Vector2(30, 30);
        obstaclePaint.color = Colors.orangeAccent;
        break;
      case ObstacleType.wall:
        size = Vector2(30, 60);
        obstaclePaint.color = Colors.redAccent;
        break;
      case ObstacleType.ramp:
        size = Vector2(40, 20);
        obstaclePaint.color = Colors.orangeAccent;
        break;
      case ObstacleType.hole:
        size = Vector2(40, 10);
        obstaclePaint.color = Colors.black;
        break;
    }

    // Çarpışma kutusu ekle
    final hitbox = RectangleHitbox.relative(
      Vector2.all(1.0),
      parentSize: size,
    );
    add(hitbox);
  }

  @override
  void render(Canvas canvas) {
    if (type == ObstacleType.ramp) {
      // Ramp özel çizim
      final path = Path();
      path.moveTo(0, size.y);
      path.lineTo(size.x, size.y);
      path.lineTo(size.x, 0);
      path.close();
      canvas.drawPath(path, obstaclePaint);
    } else {
      // Diğer engeller
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height),
        obstaclePaint,
      );
    }
    super.render(canvas);
  }
}

class CollectibleComponent extends PositionComponent with CollisionCallbacks {
  final Paint collectiblePaint = Paint();
  late Paint effectPaint;
  final CollectibleType type;
  double angle = 0;

  CollectibleComponent({
    required Vector2 position,
    this.type = CollectibleType.coin,
  }) : super(
          position: position,
          size: Vector2(25, 25),
          anchor: Anchor.center,
        ) {
    // Toplama öğesi tipine göre farklı renkler
    switch (type) {
      case CollectibleType.coin:
        collectiblePaint.color = Colors.amber;
        effectPaint = Paint()..color = Colors.amber.withOpacity(0.3);
        break;
      case CollectibleType.extraLife:
        collectiblePaint.color = Colors.red;
        effectPaint = Paint()..color = Colors.red.withOpacity(0.3);
        break;
      case CollectibleType.shield:
        collectiblePaint.color = Colors.blue;
        effectPaint = Paint()..color = Colors.blue.withOpacity(0.3);
        break;
      case CollectibleType.magnet:
        collectiblePaint.color = Colors.purple;
        effectPaint = Paint()..color = Colors.purple.withOpacity(0.3);
        break;
      case CollectibleType.slowMotion:
        collectiblePaint.color = Colors.lightBlue;
        effectPaint = Paint()..color = Colors.lightBlue.withOpacity(0.3);
        break;
      case CollectibleType.scoreBoost:
        collectiblePaint.color = Colors.green;
        effectPaint = Paint()..color = Colors.green.withOpacity(0.3);
        break;
      default:
        collectiblePaint.color = Colors.amber;
        effectPaint = Paint()..color = Colors.amber.withOpacity(0.3);
    }

    // Maske filtresini hepsinde kullanacağız
    effectPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Çarpışma kutusu ekle
    final hitbox = CircleHitbox.relative(
      0.8,
      parentSize: size,
      position: size / 2,
      anchor: Anchor.center,
    );
    add(hitbox);
  }

  @override
  void update(double dt) {
    // Dönme efekti
    angle += dt * 2;

    // Yukarı aşağı efekti
    position.y += math.sin(angle) * 0.5;

    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    // Parlak efekt
    canvas.drawCircle(
      Offset(width / 2, height / 2),
      width / 1.5,
      effectPaint,
    );

    if (type == CollectibleType.coin) {
      // Altın para
      canvas.drawCircle(
        Offset(width / 2, height / 2),
        width / 2,
        collectiblePaint,
      );

      // İç detaylar
      final innerPaint = Paint()..color = Colors.amber.shade300;
      canvas.drawCircle(
        Offset(width / 2, height / 2),
        width / 3,
        innerPaint,
      );
    } else if (type == CollectibleType.extraLife) {
      // Ekstra can (kalp)
      final heartPath = _createHeartPath();
      canvas.drawPath(heartPath, collectiblePaint);
    } else if (type == CollectibleType.shield) {
      // Kalkan
      canvas.drawCircle(
        Offset(width / 2, height / 2),
        width / 2,
        collectiblePaint,
      );

      // Kalkan detayı
      final shieldPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(
            center: Offset(width / 2, height / 2), radius: width / 2.5),
        math.pi * 0.25,
        math.pi * 1.5,
        false,
        shieldPaint,
      );
    } else if (type == CollectibleType.magnet) {
      // Mıknatıs
      final magnetPaint = Paint()..color = Colors.purple;

      // Mıknatıs U şekli
      final path = Path();
      path.moveTo(width * 0.3, height * 0.2);
      path.lineTo(width * 0.3, height * 0.6);
      path.lineTo(width * 0.5, height * 0.6);
      path.lineTo(width * 0.5, height * 0.8);
      path.lineTo(width * 0.7, height * 0.8);
      path.lineTo(width * 0.7, height * 0.2);
      path.lineTo(width * 0.6, height * 0.2);
      path.lineTo(width * 0.6, height * 0.7);
      path.lineTo(width * 0.55, height * 0.7);
      path.lineTo(width * 0.55, height * 0.5);
      path.lineTo(width * 0.45, height * 0.5);
      path.lineTo(width * 0.45, height * 0.7);
      path.lineTo(width * 0.4, height * 0.7);
      path.lineTo(width * 0.4, height * 0.2);
      path.close();

      canvas.drawPath(path, magnetPaint);
    } else {
      // Diğer power-up'lar
      final symbol = _getSymbolForType(type);

      // Ana daire
      canvas.drawCircle(
        Offset(width / 2, height / 2),
        width / 2,
        collectiblePaint,
      );

      // Sembol
      final textPainter = TextPainter(
        text: TextSpan(
          text: symbol,
          style: TextStyle(
            color: Colors.white,
            fontSize: width * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          width / 2 - textPainter.width / 2,
          height / 2 - textPainter.height / 2,
        ),
      );
    }

    super.render(canvas);
  }

  // Kalp şekli oluştur
  Path _createHeartPath() {
    final heartPath = Path();
    final center = Offset(width / 2, height / 2);
    final size = width * 0.4;

    heartPath.moveTo(center.dx, center.dy + size * 0.3);
    heartPath.cubicTo(center.dx + size, center.dy - size, center.dx + size * 2,
        center.dy + size, center.dx, center.dy + size * 1.5);
    heartPath.cubicTo(center.dx - size * 2, center.dy + size, center.dx - size,
        center.dy - size, center.dx, center.dy + size * 0.3);

    return heartPath;
  }

  // Toplama öğesi tipine göre sembol döndür
  String _getSymbolForType(CollectibleType type) {
    switch (type) {
      case CollectibleType.scoreBoost:
        return "2x";
      case CollectibleType.slowMotion:
        return "⏱️";
      case CollectibleType.coin:
        return "¢";
      case CollectibleType.extraLife:
        return "❤️";
      case CollectibleType.shield:
        return "🛡️";
      case CollectibleType.magnet:
        return "🧲";
      default:
        return "?";
    }
  }
}

class CloudComponent extends PositionComponent {
  CloudComponent({required Vector2 position, required Vector2 size})
      : super(position: position, size: size);

  final Paint _cloudPaint = Paint()..color = Colors.white.withOpacity(0.8);
  double moveSpeed = 10;

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, width, height);
    canvas.drawOval(rect, _cloudPaint);
    canvas.drawOval(
        Rect.fromLTWH(width * 0.2, -height * 0.2, width * 0.6, height * 0.8),
        _cloudPaint);
    canvas.drawOval(
        Rect.fromLTWH(width * 0.1, -height * 0.1, width * 0.4, height * 0.7),
        _cloudPaint);
  }

  @override
  void update(double dt) {
    position.x -= moveSpeed * dt;
    if (position.x < -width) {
      position.x = 800 + width; // ekran dışına çık
      position.y = math.Random().nextDouble() * 200;
    }
    super.update(dt);
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late RunnerGame _game;
  bool _isPaused = false;
  String _errorMessage = '';
  bool _showTutorial = true; // Tutorial gösterme durumu

  @override
  void initState() {
    super.initState();
    _game = RunnerGame();

    // İzleme listesi ekle
    WidgetsBinding.instance.addObserver(this);

    // Düzenli state kontrol timer'ı kur
    // Her frame'de oyunun durumunu kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGameState();
    });

    // 5 saniye sonra tutorial'ı gizle
    Future.delayed(Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showTutorial = false;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _checkGameState() {
    if (mounted) {
      setState(() {
        // UI güncelleniyor
      });

      // Sonraki frame'de kontrol et
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkGameState();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!_isPaused && !_game.isGameOver) {
                print("Basic tap jump!");
                _game.player.jump();
              }
            },
            onVerticalDragStart: (details) {
              if (!_isPaused && !_game.isGameOver) {
                print("Kayma!");
                _game.player.slide();
              }
            },
            onHorizontalDragEnd: (details) {
              if (!_isPaused &&
                  !_game.isGameOver &&
                  details.velocity.pixelsPerSecond.dx.abs() > 300) {
                print("Dash!");
                _game.player.dash();
              }
            },
            child: GameWidget(game: _game),
          ),

          // HUD Elemanları
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Kalpler
                      Row(
                        children: List.generate(
                          3,
                          (index) => Icon(
                            index < _game.lives
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                            size: isSmallScreen ? 24 : 30,
                          ),
                        ),
                      ),

                      // Zıplama animasyonu - enerji çubuğu
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: Colors.white70, width: 1),
                              color: Colors.black45,
                            ),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Container(
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green,
                                          Colors.yellow,
                                          Colors.red
                                        ],
                                      ),
                                    ),
                                    height: 8,
                                    width: 60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Coin counter ve Combo
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.monetization_on,
                                  color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${_game.score}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (_game.combo > 0)
                            Text(
                              'Combo: ${_game.combo}x',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getComboColor(_game.combo),
                              ),
                            ),
                        ],
                      ),

                      // Pause button
                      IconButton(
                        icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                        color: Colors.white,
                        onPressed: () {
                          setState(() {
                            _isPaused = !_isPaused;
                            _game.isPaused = _isPaused;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Aktif güçler göstergesi
                if (_game.hasMagnet || _game.hasShield || _game.hasSlowMotion)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_game.hasMagnet)
                          _buildPowerUpIndicator(
                            Icons.attractions,
                            Colors.purple,
                            _game.magnetTimer,
                          ),
                        if (_game.hasShield)
                          _buildPowerUpIndicator(
                            Icons.shield,
                            Colors.blue,
                            _game.shieldTimer,
                          ),
                        if (_game.hasSlowMotion)
                          _buildPowerUpIndicator(
                            Icons.hourglass_bottom,
                            Colors.lightBlue,
                            _game.slowMotionTimer,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Yeni oynanış mekanikleri için yardım metni
          if (_showTutorial)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'New Movement Controls:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Tap & Hold: Charge jump (longer hold = higher jump)\n'
                      '• Double Tap: Double jump when in air\n'
                      '• Swipe Down: Slide under obstacles\n'
                      '• Swipe Right fast: Dash forward',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          // Hata mesajı
          if (_errorMessage.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black54,
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),

          // Oyun duraklatıldığında
          if (_isPaused)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black54,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PAUSED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Tap to continue',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Oyun bitti ekranı
          if (_game.isGameOver)
            Center(
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'GAME OVER',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Score: ${_game.score}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _game = RunnerGame();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'PLAY AGAIN',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Aktif güç göstergesi widget'ı
  Widget _buildPowerUpIndicator(IconData icon, Color color, double timeLeft) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            '${timeLeft.toStringAsFixed(1)}s',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Combo sayısına göre renk değiştirme
  Color _getComboColor(int combo) {
    if (combo >= 20) return Colors.red;
    if (combo >= 15) return Colors.orange;
    if (combo >= 10) return Colors.amber;
    if (combo >= 5) return Colors.green;
    return Colors.white;
  }
}
