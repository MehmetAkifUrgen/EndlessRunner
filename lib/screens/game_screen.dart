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
  PlayerComponent? _player;
  // PlayerComponent'i getter üzerinden güvenli şekilde sağlayalım
  PlayerComponent get player {
    if (_player == null && hasLayout) {
      _player = PlayerComponent(
        position: Vector2(size.x * 0.2, size.y - groundHeight),
        game: this,
      );
      add(_player!);
    }

    return _player ?? PlayerComponent(position: Vector2(0, 0), game: this);
  }

  late TextComponent scoreText;
  late TextComponent fpsText;
  late Timer obstacleSpawnTimer;
  late Timer collectibleSpawnTimer;

  // FPS ölçümü için değişkenler
  double _fps = 0;
  double _fpsUpdateTime = 0;
  final double _fpsUpdateInterval = 0.5; // Yarım saniyede bir güncelle

  int score = 0;
  int highScore = 0;
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

  // GameState erişimi için context
  BuildContext? context;

  // onGameReady callback
  Function(RunnerGame game)? onGameReady;

  @override
  Future<void> onLoad() async {
    // GameState'i alalım
    final gameState = context != null
        ? Provider.of<GameState>(context!, listen: false)
        : null;

    // Mevcut temayı al
    final currentTheme = gameState?.currentTheme;

    // Arkaplan - Gradient ile zenginleştirme
    add(
      RectangleComponent(
        size: Vector2(size.x, size.y),
        paint: Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: currentTheme?.backgroundGradient ??
                [Colors.lightBlue.shade300, Colors.blue.shade600],
          ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)),
      ),
    );

    // Dağlar (arka plan)
    _addMountains(currentTheme);

    // Çimenli yer zemini
    add(
      GrassComponent(
        position: Vector2(0, size.y - groundHeight),
        size: Vector2(size.x, groundHeight),
        groundColor: currentTheme?.groundColor,
      ),
    );

    // Bulutlar (dekortif elementler)
    _addClouds();

    // Oyuncu - önceden oluşturulmamışsa oluştur
    if (_player == null) {
      _player = PlayerComponent(
        position: Vector2(size.x * 0.2, size.y - groundHeight),
        game: this,
        color: currentTheme?.playerColor,
      );
      _player!.isOnGround = true;
      _player!.isJumping = false;
      _player!.position.y = size.y - groundHeight;
      add(_player!);
    }

    // Skor metni - Gölgeli ve daha görünür
    scoreText = TextComponent(
      text: 'SCORE: $score',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
          ],
        ),
      ),
      position: Vector2(20, 20),
    );
    add(scoreText);

    // Engel oluşturma zamanlayıcısı
    obstacleSpawnTimer = Timer(2, onTick: _spawnObstacle, repeat: true);

    // Toplanabilir oluşturma zamanlayıcısı
    collectibleSpawnTimer = Timer(3, onTick: _spawnCollectible, repeat: true);

    // onGameReady callback'i çağır
    onGameReady?.call(this);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (isPaused || isGameOver) return;

    // FPS hesapla ve güncelle
    _updateFps(dt);

    // Oyun süresini güncelle
    gameTime += dt;

    // Oyun hızını zamanla artır (zorluk arttırma)
    gameSpeed = math.min(
      gameSpeed + gameSpeedIncreaseRate * dt * difficultyMultiplier,
      maxGameSpeed,
    );

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
    double yPosition = size.y - groundHeight;

    // Engel tipine göre zemine oturmasını sağla
    if (type == ObstacleType.hole) {
      yPosition = size.y - groundHeight + 5; // Çukur yere gömülü görünsün
    }

    // Tema bilgisini al
    final gameState = context != null
        ? Provider.of<GameState>(context!, listen: false)
        : null;
    final obstacleColor = gameState?.currentTheme.obstacleColor;

    // Engellerin çeşitliliğini arttır
    final obstacle = ObstacleComponent(
      position: Vector2(size.x + 50, yPosition),
      type: type,
      color: obstacleColor,
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

    // High score kontrolü ve güncelleme
    if (score > highScore) {
      highScore = score;

      // GameState güncelleme
      if (context != null) {
        try {
          Provider.of<GameState>(context!, listen: false).addScore(score);
        } catch (e) {
          print("GameState update error: $e");
        }
      }
    }

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
    final random = math.Random();
    // Daha az bulut kullan
    final cloudCount = math.min(3, (size.x / 300).ceil());

    for (int i = 0; i < cloudCount; i++) {
      final cloudWidth = 80 + random.nextDouble() * 100;
      final cloudHeight = 30 + random.nextDouble() * 20;
      final y = 50 + random.nextDouble() * 100;

      // Bulut y pozisyonunu ekran içinde tut
      final actualY = math.min(y, size.y - groundHeight - 150);

      final cloud = CloudComponent(
        position: Vector2(random.nextDouble() * size.x, actualY),
        size: Vector2(cloudWidth, cloudHeight),
        speed: 10 + random.nextDouble() * 5,
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

  // Dağlar ekle (arka plan için)
  void _addMountains([GameTheme? theme]) {
    final rng = math.Random();

    // Arka plandaki dağlar - doğal renkler
    final mountainColors = [
      theme?.secondaryColor.withOpacity(0.8) ?? Colors.blueGrey.shade700,
      theme?.secondaryColor.withOpacity(0.9) ?? Colors.blueGrey.shade800,
      theme?.secondaryColor.withOpacity(0.7) ?? Colors.blueGrey.shade600,
    ];

    // Doğal dağ renkleri - yeşil-kahverengi tonları
    if (theme == null || theme.secondaryColor == null) {
      mountainColors[0] = Colors.blueGrey.shade700;
      mountainColors[1] = Colors.blueGrey.shade800;
      mountainColors[2] = Colors.blueGrey.shade600;
    }

    // Dağ sayısını azalt - performans için
    for (int i = 0; i < 2; i++) {
      final mountainWidth = 200 + rng.nextDouble() * 250;
      final mountainHeight = 80 + rng.nextDouble() * 120;
      final colorIndex = rng.nextInt(mountainColors.length);

      final mountain = MountainComponent(
        position: Vector2(
          rng.nextDouble() * size.x -
              mountainWidth * 0.3, // Ekran dışına da taşabilir
          size.y -
              groundHeight -
              mountainHeight +
              15, // Biraz çimene gömülü görünsün
        ),
        size: Vector2(mountainWidth, mountainHeight),
        color: mountainColors[colorIndex],
      );
      add(mountain);
    }

    // Ön plandaki dağlar - daha koyusu
    // Sadece 1 dağ ekle - performans için
    final mountainWidth = 250 + rng.nextDouble() * 200;
    final mountainHeight = 100 + rng.nextDouble() * 150;
    final mountain = MountainComponent(
      position: Vector2(
        rng.nextDouble() * size.x -
            mountainWidth * 0.2, // Ekran dışına da taşabilir
        size.y -
            groundHeight -
            mountainHeight +
            20, // Biraz çimene gömülü görünsün
      ),
      size: Vector2(mountainWidth, mountainHeight),
      color: theme?.secondaryColor ?? Colors.blueGrey.shade900,
    );
    add(mountain);
  }

  // FPS hesaplama ve güncelleme
  void _updateFps(double dt) {
    // FPS'i hesapla ama ekranda gösterme
    if (dt > 0) {
      _fps = 1.0 / dt;
    }
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
  final Paint playerPaint;

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

  PlayerComponent({
    required Vector2 position,
    required this.game,
    Color? color,
  })  : playerPaint = Paint()..color = color ?? Colors.red,
        super(
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
      if (position.y >= game.size.y - game.groundHeight) {
        position.y = game.size.y - game.groundHeight;
        isJumping = false;
        isOnGround = true;
        canDoubleJump = true; // Yere değdiğinde çift zıplama hakkı yenilenir
        velocityY = 0;
        scale = Vector2.all(1); // Normal boyuta dön
        print("Yere indi! isOnGround: $isOnGround");
      }
    } else {
      // Oyuncu yerde ama pozisyonu zemin seviyesinde değilse düzelt
      if (position.y != game.size.y - game.groundHeight) {
        position.y = game.size.y - game.groundHeight;
      }

      // Koşma animasyonu için bacak hareketi
      if (!isSliding && !isChargingJump) {
        final runningTime = game.gameTime % 0.5;
        if (runningTime < 0.25) {
          scale = Vector2(1.0, 1.0 + runningTime * 0.1);
        } else {
          scale = Vector2(1.0, 1.0 + (0.5 - runningTime) * 0.1);
        }
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
      "executeJump çağrıldı! isOnGround: $isOnGround, isChargingJump: $isChargingJump",
    );
    if (isOnGround && !isSliding) {
      // Şarj süresine göre zıplama hızını hesapla
      double jumpVelocity = -400; // Varsayılan zıplama gücü

      if (isChargingJump) {
        double chargePercent = jumpChargeDuration / maxChargeTime;
        // Basılı tutma süresine göre -400 ile -800 arasında değer
        jumpVelocity = -400 - (chargePercent * 400);
        print("Basılı tutma süresi: $jumpChargeDuration, Güç: $jumpVelocity");
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
    // Oyuncuyu insan şeklinde çiz
    final bodyRect = Rect.fromLTWH(
      width * 0.25,
      height * 0.3,
      width * 0.5,
      height * 0.4,
    );
    final headRadius = width * 0.2;
    final headCenter = Offset(width * 0.5, height * 0.2);

    // Gövde
    canvas.drawRect(bodyRect, playerPaint);
    // Kafa
    canvas.drawCircle(headCenter, headRadius, playerPaint);

    // Koşma animasyonu için bacaklar
    final legOffset = isSliding ? 0.0 : math.sin(game.gameTime * 10) * 5.0;

    // Sol bacak
    final leftLeg = RRect.fromLTRBR(
      width * 0.3,
      height * 0.7,
      width * 0.4,
      height - legOffset,
      Radius.circular(5),
    );

    // Sağ bacak
    final rightLeg = RRect.fromLTRBR(
      width * 0.6,
      height * 0.7,
      width * 0.7,
      height + legOffset,
      Radius.circular(5),
    );

    // Kollar
    final leftArm = RRect.fromLTRBR(
      width * 0.15,
      height * 0.35,
      width * 0.25,
      height * 0.6 - legOffset * 0.5,
      Radius.circular(5),
    );

    final rightArm = RRect.fromLTRBR(
      width * 0.75,
      height * 0.35,
      width * 0.85,
      height * 0.6 + legOffset * 0.5,
      Radius.circular(5),
    );

    canvas.drawRRect(leftLeg, playerPaint);
    canvas.drawRRect(rightLeg, playerPaint);
    canvas.drawRRect(leftArm, playerPaint);
    canvas.drawRRect(rightArm, playerPaint);

    // Yüz detayları (gözler)
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(
        headCenter.dx - headRadius * 0.3,
        headCenter.dy - headRadius * 0.1,
      ),
      headRadius * 0.15,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(
        headCenter.dx + headRadius * 0.3,
        headCenter.dy - headRadius * 0.1,
      ),
      headRadius * 0.15,
      eyePaint,
    );

    // Göz bebekleri
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(
      Offset(
        headCenter.dx - headRadius * 0.3,
        headCenter.dy - headRadius * 0.1,
      ),
      headRadius * 0.05,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(
        headCenter.dx + headRadius * 0.3,
        headCenter.dy - headRadius * 0.1,
      ),
      headRadius * 0.05,
      pupilPaint,
    );

    // Ağız
    if (isChargingJump) {
      // Zıplama sırasında stresli yüz
      final mouthPath = Path();
      mouthPath.moveTo(
        headCenter.dx - headRadius * 0.2,
        headCenter.dy + headRadius * 0.3,
      );
      mouthPath.lineTo(
        headCenter.dx + headRadius * 0.2,
        headCenter.dy + headRadius * 0.3,
      );
      canvas.drawPath(
        mouthPath,
        pupilPaint
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );
    } else {
      // Normal gülümseyen yüz
      final mouthRect = Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.2),
        width: headRadius * 0.6,
        height: headRadius * 0.3,
      );
      canvas.drawArc(
        mouthRect,
        0,
        math.pi,
        false,
        pupilPaint
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );
    }

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
  final Paint obstaclePaint;
  final ObstacleType type;

  // Engel tipleri için önişlenmiş Path'ler
  late final Path? _topFacePath;
  late final Path? _rightFacePath;
  late final Path? _crackPath;
  late final Paint? _topFacePaint;
  late final Paint? _rightFacePaint;
  late final Paint? _linePaint;
  late final Paint? _crackPaint;
  final bool isSpecial;
  final math.Random random = math.Random();

  ObstacleComponent({
    required Vector2 position,
    this.type = ObstacleType.cube,
    Color? color,
  })  : obstaclePaint = Paint()..color = color ?? Colors.redAccent,
        isSpecial = math.Random().nextDouble() < 0.15, // %15 şansla özel engel
        super(position: position, anchor: Anchor.bottomLeft) {
    // Engel tipine göre farklı boyut ve renkler
    switch (type) {
      case ObstacleType.cube:
        size = Vector2(30, 30);
        break;
      case ObstacleType.wall:
        size = Vector2(30, 60);
        if (color == null) {
          obstaclePaint.color = Colors.redAccent.shade700;
        }
        break;
      case ObstacleType.ramp:
        size = Vector2(40, 20);
        if (color == null) {
          obstaclePaint.color = Colors.brown.shade600;
        }
        break;
      case ObstacleType.hole:
        size = Vector2(40, 10);
        if (color == null) {
          obstaclePaint.color = Colors.black;
        }
        break;
    }

    // Çarpışma kutusu ekle - daha doğru çarpışma tespiti için
    if (type == ObstacleType.ramp) {
      // Rampa için özel çarpışma kutusu (üçgen için)
      final hitbox = PolygonHitbox([
        Vector2(0, size.y), // Sol alt
        Vector2(size.x, size.y), // Sağ alt
        Vector2(size.x, 0), // Sağ üst
      ]);
      add(hitbox);
    } else {
      // Diğer engeller için normal çarpışma kutusu
      final hitbox = RectangleHitbox.relative(
        Vector2.all(type == ObstacleType.hole ? 0.8 : 0.95),
        parentSize: size,
        position: Vector2(size.x * 0.025, size.y * 0.025),
      );
      add(hitbox);
    }

    // Detay çizimlerini önişle
    _initPrerenderedPaths();
  }

  void _initPrerenderedPaths() {
    if (type == ObstacleType.cube) {
      _topFacePath = Path();
      _topFacePath!.moveTo(0, 0);
      _topFacePath!.lineTo(width, 0);
      _topFacePath!.lineTo(width - 5, 5);
      _topFacePath!.lineTo(5, 5);
      _topFacePath!.close();

      _topFacePaint = Paint()
        ..color = obstaclePaint.color.withRed(obstaclePaint.color.red + 30);

      _rightFacePath = Path();
      _rightFacePath!.moveTo(width, 0);
      _rightFacePath!.lineTo(width, height);
      _rightFacePath!.lineTo(width - 5, height - 5);
      _rightFacePath!.lineTo(width - 5, 5);
      _rightFacePath!.close();

      _rightFacePaint = Paint()
        ..color = obstaclePaint.color.withBlue(obstaclePaint.color.blue + 20);

      _crackPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;

      final random = math.Random(42);
      _crackPath = Path();
      _crackPath!.moveTo(random.nextDouble() * width * 0.3,
          random.nextDouble() * height * 0.3);
      for (int i = 0; i < 3; i++) {
        _crackPath!.lineTo(
          random.nextDouble() * width * 0.8,
          random.nextDouble() * height * 0.8,
        );
      }
    } else if (type == ObstacleType.ramp) {
      _linePaint = Paint()
        ..color = Colors.brown.shade800
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
    } else {
      _topFacePath = null;
      _rightFacePath = null;
      _crackPath = null;
      _topFacePaint = null;
      _rightFacePaint = null;
      _linePaint = null;
      _crackPaint = null;
    }
  }

  @override
  void render(Canvas canvas) {
    if (type == ObstacleType.ramp) {
      // Ramp (rampa) özel çizim
      final path = Path();
      path.moveTo(0, size.y);
      path.lineTo(size.x, size.y);
      path.lineTo(size.x, 0);
      path.close();

      // Özel engeller için parıltı veya farklı stil ekle
      if (isSpecial) {
        canvas.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
              colors: [
                obstaclePaint.color,
                obstaclePaint.color.withOpacity(0.7),
                Colors.white.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)),
        );

        // Işıltı efekti ekle
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white.withOpacity(0.8),
        );
      } else {
        // Daha estetik rampa
        canvas.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
              colors: [
                obstaclePaint.color,
                obstaclePaint.color.withOpacity(0.6),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)),
        );
      }

      // Daha az çizgi çizerek performans artışı
      if (_linePaint != null) {
        for (int i = 1; i < 2; i++) {
          final y = i * size.y / 2;
          final x = size.x * (1 - y / size.y);
          canvas.drawLine(
            Offset(0, y),
            Offset(x, y),
            _linePaint!,
          );
        }
      }
    } else if (type == ObstacleType.wall) {
      // Duvar engeli (tuğla duvar görünümü), daha şık
      // Temel duvar
      final wallGradient = LinearGradient(
        colors: [
          obstaclePaint.color,
          obstaclePaint.color.withRed(obstaclePaint.color.red - 40),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));

      canvas.drawRect(
          Rect.fromLTWH(0, 0, width, height), Paint()..shader = wallGradient);

      // Özel engeller için efekt ekle
      if (isSpecial) {
        // Parlayan kenarlar
        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.amber.withOpacity(0.8);

        canvas.drawRect(
            Rect.fromLTWH(1, 1, width - 2, height - 2), borderPaint);

        // Parıltılı efekt
        canvas.drawRect(
          Rect.fromLTWH(0, 0, width, height),
          Paint()
            ..shader = RadialGradient(
              colors: [
                Colors.white.withOpacity(0.4),
                Colors.transparent,
              ],
              radius: 0.8,
              center: Alignment.topLeft,
            ).createShader(Rect.fromLTWH(0, 0, width, height)),
        );
      }

      // Daha güzel tuğla çizgileri çiz
      final brickLines = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      // Yatay tuğla çizgileri
      for (int i = 1; i < 3; i++) {
        canvas.drawLine(
          Offset(0, i * height / 3),
          Offset(width, i * height / 3),
          brickLines,
        );
      }

      // Dikey tuğla çizgileri
      canvas.drawLine(
        Offset(width / 2, 0),
        Offset(width / 2, height / 3),
        brickLines,
      );
      canvas.drawLine(
        Offset(width / 2, height / 3 * 2),
        Offset(width / 2, height),
        brickLines,
      );
    } else if (type == ObstacleType.hole) {
      // Çukur engeli, daha görsel
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), obstaclePaint);

      // Çukura derinlik efekti ekle
      final innerRect =
          Rect.fromLTWH(width * 0.15, height * 0.3, width * 0.7, height * 0.7);

      // Gölgeli çukur efekti
      final holeShadow = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.3),
          ],
          radius: 0.8,
        ).createShader(innerRect);

      canvas.drawRect(innerRect, holeShadow);

      // Özel efektler
      if (isSpecial) {
        // Daha dikkat çekici çukur
        canvas.drawRect(
          innerRect,
          Paint()
            ..shader = LinearGradient(
              colors: [
                Colors.red.withOpacity(0.3),
                Colors.black.withOpacity(0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(innerRect),
        );

        // Tehlike işareti
        final warningPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.amber;

        // Tehlike çizgileri
        for (int i = 0; i < 2; i++) {
          final offset = i * 5.0;
          canvas.drawLine(Offset(width * 0.3 + offset, height * 0.2),
              Offset(width * 0.7 - offset, height * 0.2), warningPaint);
        }
      }
    } else {
      // Küp engeli (taş küp görünümü)
      final cubeGradient = LinearGradient(
        colors: [
          obstaclePaint.color.withRed(obstaclePaint.color.red + 20),
          obstaclePaint.color.withRed(obstaclePaint.color.red - 20),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, width, height));

      canvas.drawRect(
          Rect.fromLTWH(0, 0, width, height), Paint()..shader = cubeGradient);

      // Özel küpler için parlama efekti
      if (isSpecial) {
        // Parlayan kenarlık
        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withOpacity(0.8);

        canvas.drawRect(
            Rect.fromLTWH(1, 1, width - 2, height - 2), borderPaint);

        // Parıltı efekti
        final shimmerPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.4),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, width, height));

        canvas.drawRect(Rect.fromLTWH(0, 0, width, height), shimmerPaint);
      }

      // 3D efekti için üst ve sağ yüzler
      if (_topFacePath != null && _topFacePaint != null) {
        canvas.drawPath(_topFacePath!, _topFacePaint!);
      }

      if (_rightFacePath != null && _rightFacePaint != null) {
        canvas.drawPath(_rightFacePath!, _rightFacePaint!);
      }

      // Detaylar için çatlak çizim
      if (_crackPath != null && _crackPaint != null) {
        canvas.drawPath(_crackPath!, _crackPaint!);
      }
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
  }) : super(position: position, size: Vector2(25, 25), anchor: Anchor.center) {
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
    canvas.drawCircle(Offset(width / 2, height / 2), width / 1.5, effectPaint);

    if (type == CollectibleType.coin) {
      // Altın para
      canvas.drawCircle(
        Offset(width / 2, height / 2),
        width / 2,
        collectiblePaint,
      );

      // İç detaylar
      final innerPaint = Paint()..color = Colors.amber.shade300;
      canvas.drawCircle(Offset(width / 2, height / 2), width / 3, innerPaint);
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
          center: Offset(width / 2, height / 2),
          radius: width / 2.5,
        ),
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
    heartPath.cubicTo(
      center.dx + size,
      center.dy - size,
      center.dx + size * 2,
      center.dy + size,
      center.dx,
      center.dy + size * 1.5,
    );
    heartPath.cubicTo(
      center.dx - size * 2,
      center.dy + size,
      center.dx - size,
      center.dy - size,
      center.dx,
      center.dy + size * 0.3,
    );

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
  final double speed;
  final Paint _cloudPaint = Paint()..color = Colors.white.withOpacity(0.7);
  final List<Offset> _cloudPoints = [];
  bool _isOnScreen = true;
  bool _isRendered = false;

  CloudComponent({
    required Vector2 position,
    required Vector2 size,
    required this.speed,
  }) : super(position: position, size: size);

  void _preCalculateCloudShape() {
    if (_isRendered) return;

    // Cloudpoints'i temizle, yeniden oluştur
    _cloudPoints.clear();
    final random = math.Random(position.x.toInt() * 10 + position.y.toInt());

    // Rastgele bulut şekilleri oluştur ama daha az nokta kullan
    final pointCount = 4;
    for (int i = 0; i < pointCount; i++) {
      final double x = (i * size.x / (pointCount - 1));
      final double y =
          (size.y * 0.5 + (random.nextDouble() - 0.5) * size.y * 0.7);
      _cloudPoints.add(Offset(x, y));
    }

    _isRendered = true;
  }

  @override
  void update(double dt) {
    position.x += speed * dt;

    // Ekran dışına çıktığında sola geri getir
    if (parent is RunnerGame) {
      final RunnerGame runnerGame = parent as RunnerGame;

      // Ekran dışında mı kontrol et
      _isOnScreen = position.x >= -size.x && position.x <= runnerGame.size.x;

      if (position.x > runnerGame.size.x) {
        position.x = -size.x;
      }
    }

    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    // Sadece ekranda görünür olduğunda çiz
    if (_isOnScreen) {
      // Lazy olarak bulut şeklini hesapla
      _preCalculateCloudShape();

      // Bulutları basitleştir - sadece oval şekiller kullan
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.x / 2, size.y / 2),
          width: size.x,
          height: size.y * 0.7,
        ),
        _cloudPaint,
      );
    }

    super.render(canvas);
  }
}

class GrassComponent extends PositionComponent {
  // Çimen için önişlenmiş Paint nesneleri
  final Paint _groundPaint;
  final Paint _grassPaint;
  final Paint _detailPaint;

  // Çimen sapları için önişlenmiş yollar
  late final List<Path> _grassBlades;
  bool _isPrerendered = false;

  GrassComponent(
      {required Vector2 position, required Vector2 size, Color? groundColor})
      : _groundPaint = Paint()..color = groundColor ?? Colors.brown.shade700,
        _grassPaint = Paint()..color = Colors.green.shade800,
        _detailPaint = Paint()..color = Colors.green.shade600,
        super(position: position, size: size) {
    // Lazy initialization için boş başlat
    _grassBlades = [];
  }

  void _prerenderGrass() {
    if (_isPrerendered) return;

    // Sabit tohum ile rastgele değerler üretme
    final random = math.Random(42);

    // Çimen saplarını önişle - sayıyı azalt
    final grassBladesCount = 5; // Çok daha az çimen sapı - performans için

    for (int i = 0; i < grassBladesCount; i++) {
      final x = i * (size.x / grassBladesCount) + random.nextDouble() * 10;
      final height = 2 + random.nextDouble() * 4;

      // Çimen sapı
      final grassBlade = Path();
      grassBlade.moveTo(x, 0);
      grassBlade.lineTo(x + (random.nextBool() ? 3 : -3), -height);
      grassBlade.lineTo(x, 0);

      _grassBlades.add(grassBlade);
    }

    _isPrerendered = true;
  }

  @override
  void render(Canvas canvas) {
    // Zemin rengi
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _groundPaint);

    // Çimen üst kısmı
    final grassTopHeight = size.y * 0.3;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, grassTopHeight), _grassPaint);

    // Lazy olarak çimenleri hazırla
    _prerenderGrass();

    // Çimen ayrıntıları - optimize edilmiş
    if (_grassBlades.isNotEmpty) {
      canvas.save();
      canvas.translate(0, grassTopHeight);

      // Performans için sadece birkaç çimen sapı göster
      for (int i = 0; i < math.min(5, _grassBlades.length); i++) {
        canvas.drawPath(_grassBlades[i], _detailPaint);
      }

      canvas.restore();
    }
  }
}

class MountainComponent extends PositionComponent {
  final Paint _mountainPaint;
  final Paint _snowPaint = Paint()..color = Colors.white.withOpacity(0.8);
  final Paint _detailPaint;
  final Path _mountainPath = Path();
  final Path _snowPath = Path();
  final List<Path> _detailPaths = [];
  bool _isPrerendered = false;

  MountainComponent(
      {required Vector2 position, required Vector2 size, required Color color})
      : _mountainPaint = Paint()..color = color,
        _detailPaint = Paint()
          ..color = color.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
        super(position: position, size: size) {
    // Dağ şeklini hazırla ama render'da kullan
  }

  // Dağı hazırlama - lazy initialization için
  void _prerenderMountain() {
    if (_isPrerendered) return;

    final random = math.Random(position.x.toInt());

    // Dağ silüeti için 3-4 tepe oluştur (sayıyı azalt)
    final peakCount = 3;
    final points = <Offset>[];

    // Başlangıç ve bitiş noktaları (zemin)
    points.add(Offset(0, size.y));

    // Dağ tepeleri
    for (int i = 0; i < peakCount; i++) {
      final peakX = size.x * (i + 1) / (peakCount + 1);
      final peakHeight = random.nextDouble() * size.y * 0.7 + size.y * 0.2;
      points.add(Offset(peakX, size.y - peakHeight));
    }

    // Son nokta (zemin)
    points.add(Offset(size.x, size.y));

    // Dağ şeklini oluştur
    _mountainPath.moveTo(points.first.dx, points.first.dy);

    // Basitleştirilmiş dağ çizimi - performans için
    for (int i = 1; i < points.length; i++) {
      _mountainPath.lineTo(points[i].dx, points[i].dy);
    }

    _mountainPath.close();

    // Kar - sadece en yüksek tepeye ekle (performans için)
    int highestPeakIndex = 0;
    double highestPoint = size.y;

    for (int i = 1; i < points.length - 1; i++) {
      if (points[i].dy < highestPoint) {
        highestPoint = points[i].dy;
        highestPeakIndex = i;
      }
    }

    // Sadece en yüksek tepeye kar ekle
    if (highestPeakIndex > 0) {
      final peakPoint = points[highestPeakIndex];
      final snowPath = Path();
      final snowWidth = size.x * 0.05 + random.nextDouble() * size.x * 0.05;

      snowPath.moveTo(peakPoint.dx, peakPoint.dy);
      snowPath.lineTo(peakPoint.dx - snowWidth, peakPoint.dy + snowWidth * 1.5);
      snowPath.lineTo(peakPoint.dx + snowWidth, peakPoint.dy + snowWidth * 1.5);
      snowPath.close();

      // Ana kar path'ine ekle
      _snowPath.addPath(snowPath, Offset.zero);
    }

    // Sadece bir detay çizgisi ekle (performans için)
    final startX = random.nextDouble() * size.x * 0.8 + size.x * 0.1;
    final startY = random.nextDouble() * size.y * 0.3 + size.y * 0.1;

    final detailPath = Path();
    detailPath.moveTo(startX, startY);

    // Son nokta aşağıya doğru
    final endX = startX + (random.nextDouble() * size.x * 0.2 - size.x * 0.1);
    detailPath.lineTo(
        endX, startY + size.y * (0.3 + random.nextDouble() * 0.4));

    _detailPaths.add(detailPath);

    _isPrerendered = true;
  }

  @override
  void render(Canvas canvas) {
    // Lazy olarak dağı hazırla
    _prerenderMountain();

    // Ana dağ şeklini çiz
    canvas.drawPath(_mountainPath, _mountainPaint);

    // Kar tepelerini çiz
    canvas.drawPath(_snowPath, _snowPaint);

    // Sadece bir detay çizgisi çiz
    if (_detailPaths.isNotEmpty) {
      canvas.drawPath(_detailPaths.first, _detailPaint);
    }
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

    // 3 saniye sonra tutorial'ı gizle
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showTutorial = false;
        });
      }
    });

    // Ekstra özellikleri onGameReady içinde ayarlayalım
    _game.onGameReady = (game) {
      // GameState'ten yüksek skoru al
      final gameState = Provider.of<GameState>(context, listen: false);
      _game.highScore = gameState.highScore;
      _game.context = context;
    };
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

    // Responsive değerler
    final iconSize = isSmallScreen ? 20.0 : 28.0;
    final fontSize = isSmallScreen ? 12.0 : 16.0;
    final paddingSize = isSmallScreen ? 8.0 : 12.0;
    final containerHeight = isSmallScreen ? 10.0 : 12.0;

    return Scaffold(
      body: Stack(
        children: [
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (PointerDownEvent event) {
              if (!_isPaused && !_game.isGameOver && _game.hasLayout) {
                print("Listener: Zıplama başlatılıyor!");
                _game.player.startJumpCharge();
              }
            },
            onPointerUp: (PointerUpEvent event) {
              if (!_isPaused && !_game.isGameOver && _game.hasLayout) {
                print("Listener: Zıplama gerçekleştiriliyor!");
                _game.player.executeJump();
              }
            },
            onPointerCancel: (PointerCancelEvent event) {
              if (!_isPaused && !_game.isGameOver && _game.hasLayout) {
                print("Listener: Zıplama iptal ediliyor!");
                _game.player.executeJump();
              }
            },
            child: GestureDetector(
              // Kayma hareketi için aşağı kaydırma
              onVerticalDragStart: (details) {
                if (!_isPaused && !_game.isGameOver && _game.hasLayout) {
                  print("Kayma!");
                  _game.player.slide();
                }
              },
              // Dash hareketi için hızlı yatay kaydırma
              onHorizontalDragEnd: (details) {
                if (!_isPaused &&
                    !_game.isGameOver &&
                    _game.hasLayout &&
                    details.velocity.pixelsPerSecond.dx.abs() > 300) {
                  print("Dash!");
                  _game.player.dash();
                }
              },
              child: GameWidget(game: _game),
            ),
          ),

          // HUD Elemanları
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(paddingSize),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Kalpler
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: paddingSize,
                          vertical: paddingSize / 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            3,
                            (index) => Icon(
                              index < _game.lives
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                              size: iconSize,
                            ),
                          ),
                        ),
                      ),

                      // Zıplama animasyonu - enerji çubuğu
                      Expanded(
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: paddingSize),
                          child: Container(
                            height: containerHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white70,
                                width: 1,
                              ),
                              color: Colors.black54,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LayoutBuilder(
                                  builder: (context, constraints) {
                                return Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: Duration(milliseconds: 50),
                                      margin: EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green,
                                            Colors.yellow,
                                            Colors.red,
                                          ],
                                        ),
                                      ),
                                      height: containerHeight - 4,
                                      width: _game.hasLayout &&
                                              _game.player.isChargingJump
                                          ? math.min(
                                              (_game.player.jumpChargeDuration /
                                                      _game.player
                                                          .maxChargeTime) *
                                                  constraints.maxWidth,
                                              constraints.maxWidth - 4)
                                          : 0,
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ),

                      // Coin counter ve Combo
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: paddingSize * 1.5,
                          vertical: paddingSize / 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  color: Colors.amber,
                                  size: iconSize,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${_game.score}',
                                  style: TextStyle(
                                    fontSize: fontSize,
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
                                  fontSize: fontSize - 2,
                                  fontWeight: FontWeight.bold,
                                  color: _getComboColor(_game.combo),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Pause button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon:
                              Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                          color: Colors.white,
                          iconSize: iconSize,
                          padding: EdgeInsets.all(paddingSize / 2),
                          constraints: BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _isPaused = !_isPaused;
                              _game.isPaused = _isPaused;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Aktif güçler göstergesi
                if (_game.hasMagnet || _game.hasShield || _game.hasSlowMotion)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: paddingSize),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: paddingSize,
                        vertical: paddingSize / 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_game.hasMagnet)
                              _buildPowerUpIndicator(
                                Icons.attractions,
                                Colors.purple,
                                _game.magnetTimer,
                                fontSize,
                                iconSize * 0.8,
                              ),
                            if (_game.hasShield)
                              _buildPowerUpIndicator(
                                Icons.shield,
                                Colors.blue,
                                _game.shieldTimer,
                                fontSize,
                                iconSize * 0.8,
                              ),
                            if (_game.hasSlowMotion)
                              _buildPowerUpIndicator(
                                Icons.hourglass_bottom,
                                Colors.lightBlue,
                                _game.slowMotionTimer,
                                fontSize,
                                iconSize * 0.8,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Tutorial yukarıda gösterilsin
                if (_showTutorial)
                  Container(
                    margin: EdgeInsets.all(paddingSize),
                    padding: EdgeInsets.all(paddingSize),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white30, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Controls:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '• Press & Hold: Jump higher\n'
                          '• Swipe Down: Slide\n'
                          '• Swipe Right fast: Dash',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize - 2,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Hata mesajı
          if (_errorMessage.isNotEmpty)
            Center(
              child: Container(
                padding: EdgeInsets.all(paddingSize * 2),
                color: Colors.black54,
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                  ),
                ),
              ),
            ),

          // Oyun duraklatıldığında
          if (_isPaused)
            Center(
              child: Container(
                padding: EdgeInsets.all(paddingSize * 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PAUSED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize * 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: paddingSize * 2),
                    Text(
                      'Tap to continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Oyun bitti ekranı
          if (_game.isGameOver)
            Center(
              child: Container(
                width: isSmallScreen ? screenSize.width * 0.9 : 350,
                padding: EdgeInsets.all(paddingSize * 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black87, Colors.blueGrey.shade900],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade800],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: Text(
                        'GAME OVER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize * 2,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    SizedBox(height: paddingSize * 1.5),

                    // Puanlar
                    Container(
                      padding: EdgeInsets.all(paddingSize * 1.5),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stars,
                                  color: Colors.amber, size: iconSize),
                              SizedBox(width: paddingSize),
                              Text(
                                'Score: ${_game.score}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize * 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          SizedBox(height: paddingSize),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                                size: iconSize,
                              ),
                              SizedBox(width: paddingSize),
                              Text(
                                'High Score: ${_game.highScore}',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: fontSize * 1.2,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: paddingSize * 2),

                    // Butonlar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.refresh, color: Colors.white),
                            label: Text(
                              'PLAY AGAIN',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              // High score'u kaydet
                              if (_game.score > _game.highScore) {
                                Provider.of<GameState>(
                                  context,
                                  listen: false,
                                ).addScore(_game.score);
                              }
                              setState(() {
                                _game = RunnerGame();
                                // GameState'ten yüksek skoru al
                                final gameState = Provider.of<GameState>(
                                  context,
                                  listen: false,
                                );
                                _game.highScore = gameState.highScore;
                                _game.context = context;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.symmetric(
                                vertical: paddingSize,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: paddingSize),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.home, color: Colors.white),
                            label: Text(
                              'MAIN MENU',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              // High score'u kaydet
                              if (_game.score > _game.highScore) {
                                Provider.of<GameState>(
                                  context,
                                  listen: false,
                                ).addScore(_game.score);
                              }
                              Navigator.of(context).pop(); // Ana ekrana dön
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(
                                vertical: paddingSize,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
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
  Widget _buildPowerUpIndicator(
    IconData icon,
    Color color,
    double timeLeft,
    double fontSize,
    double iconSize,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: iconSize),
          SizedBox(width: 4),
          Text(
            '${timeLeft.toStringAsFixed(1)}s',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: fontSize - 2,
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
