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
import '../../models/game_state.dart';
import '../../domain/entities/obstacle.dart';
import '../../domain/entities/collectible.dart';
import 'dart:math';
//import '../../services/audio_service.dart';
import 'package:flutter/painting.dart';
import '../components/particles/particle_system.dart';
import '../../domain/entities/character.dart';

// Component importları
import '../components/player/player_component.dart';
import '../components/obstacles/obstacle_component.dart';
import '../components/collectibles/collectible_component.dart';
import '../components/background/grass_component.dart';
import '../components/background/mountain_component.dart';
import '../components/background/cloud_component.dart';
import '../components/player/human_player_component.dart';
import '../components/enemies/enemy_component.dart';
import '../components/platforms/platform_component.dart';
import '../components/collectibles/ammo_collectible_component.dart';
import '../../../domain/entities/enemy.dart';
import '../../../domain/entities/platform.dart';
import '../../../domain/entities/weapon.dart';

class RunnerGame extends FlameGame
    with HasCollisionDetection, HasGameRef, TapCallbacks, KeyboardEvents {
  // Oyun değişkenleri
  double groundHeight = 40.0;
  double gameSpeed = 200.0;
  double initialGameSpeed = 200.0;
  int score = 0;
  int highScore = 0;
  int lives = 3;
  bool isPaused = false;
  bool isGameOver = false;

  // Seviye sistemi için değişkenler
  Level? currentLevel;
  double levelSpeedMultiplier = 1.0;
  double levelScoreMultiplier = 1.0;
  int levelObstacleFrequency = 2;
  bool showLevelUpMessage = false;
  String levelUpMessage = "";
  double levelUpMessageTimer = 0;

  // Oyun öğeleri
  PlayerComponent? player; // Public yapıldı
  TextComponent? scoreText; // Nullable hale getirildi
  final List<ObstacleComponent> obstacles = [];
  final List<CollectibleComponent> collectibles = [];

  // Zamanlayıcılar
  Timer? obstacleSpawnTimer;
  Timer? collectibleSpawnTimer;
  Timer? enemySpawnTimer;
  Timer? platformSpawnTimer;

  // FPS hesaplama
  double _fps = 0;
  double _fpsUpdateTime = 0;
  final double _fpsUpdateInterval = 0.5;

  // Callback fonksiyonları
  Function()? onGameOver;
  Function()? onLifeLost;

  // Zorluk seviyeleri için ekstra değişkenler
  double gameTime = 0; // Toplam oyun süresi
  double gameSpeedIncreaseRate = 5; // Saniyede artış hızı düşürüldü
  double maxGameSpeed = 350; // Maksimum hız limiti düşürüldü
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

  // Ses servisi
  //final AudioService audioService = AudioService(); // Public yapıldı

  // Parçacık sistemi
  late ParticleSystem particleSystem;

  // Karakter sistemi
  final PlayerCharacter? selectedCharacter;
  final GameTheme? currentTheme;

  // Düşman ve platform sistemi için değişkenler
  final List<EnemyComponent> enemies = [];
  final List<PlatformComponent> platforms = [];
  double lastPlatformY = 0; // Son oluşturulan platformun Y konumu
  double lastPlatformX = 0; // Son oluşturulan platformun X konumu
  int currentLayerLevel =
      0; // Mevcut katman seviyesi (0=zemin, 1,2,3...=üst katmanlar)

  // Silah ve mermi sistemi için değişkenler
  bool hasPoweredWeapon = false;
  double poweredWeaponTimer = 0;
  HumanPlayerComponent? humanPlayer;

  // Constructor güncellendi
  RunnerGame({
    required this.selectedCharacter,
    required this.currentTheme,
    required this.currentLevel,
    required this.highScore,
  });

  @override
  Future<void> onLoad() async {
    try {
      // Mevcut seviyeyi al ve oyun değişkenlerini ayarla
      if (currentLevel != null) {
        // Seviye çarpanlarını ayarla
        levelSpeedMultiplier = currentLevel!.speedMultiplier;
        levelScoreMultiplier = currentLevel!.scoreMultiplier;
        levelObstacleFrequency = currentLevel!.obstacleFrequency;

        // Başlangıç hızını seviyeye göre ayarla
        initialGameSpeed = 200.0 * levelSpeedMultiplier;
        gameSpeed = initialGameSpeed;

        print("Seviye yüklendi: ${currentLevel!.name}, Hız: $gameSpeed");
      } else {
        print("UYARI: currentLevel null geldi!");
        // Varsayılan değerler zaten ayarlı
      }

      // Parçacık sistemi oluştur
      particleSystem = ParticleSystem(maxParticles: 50);
      add(particleSystem);

      // Timer'ları initialize etmek için metod
      _initializeTimers();

      // Arkaplan - Geliştirilmiş gradient ile zenginleştirme
      add(
        RectangleComponent(
          size: Vector2(size.x, size.y),
          paint: Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.7, 1.0],
              // Parametreden gelen temayı kullan
              colors: _getBackgroundColors(currentTheme),
            ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)),
        ),
      );

      // Güneş efekti
      final sunPosition = Vector2(size.x * 0.8, size.y * 0.2);
      final sunSize = size.y * 0.15;

      // Güneş çevresi parlaklık halkası
      add(
        CircleComponent(
          position: sunPosition,
          radius: sunSize * 1.3,
          paint: Paint()
            ..color = Colors.yellow.withOpacity(0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30.0),
        ),
      );

      // Güneş
      add(
        CircleComponent(
          position: sunPosition,
          radius: sunSize,
          paint: Paint()..color = Colors.yellow.shade600,
        ),
      );

      // Dağlar (arka plan) - Parametreden gelen temayı kullan
      _addMountains(currentTheme);

      // Çimenli yer zemini - Parametreden gelen temayı kullan
      add(
        GrassComponent(
          position: Vector2(0, size.y - groundHeight),
          size: Vector2(size.x, groundHeight),
          groundColor: currentTheme?.groundColor,
        ),
      );

      // Skor metni
      scoreText = TextComponent(
        text: 'SCORE: 0',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        position: Vector2(10, 10),
        anchor: Anchor.topLeft,
      );
      add(scoreText!);

      // Mermi sayısı metni
      final ammoText = TextComponent(
        text: 'AMMO: 0',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 16,
            color: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
        position: Vector2(10, 35),
        anchor: Anchor.topLeft,
      );
      add(ammoText);

      // Silah ismi metni
      final weaponText = TextComponent(
        text: 'WEAPON: Pistol',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 16,
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        position: Vector2(10, 55),
        anchor: Anchor.topLeft,
      );
      add(weaponText);

      // Zemin seviyesini kaydet
      lastPlatformY = size.y - groundHeight;

      // İnsan karakteri oluştur
      // Varsayılan bir karakter oluştur
      final defaultCharacter = selectedCharacter ??
          PlayerCharacter(
            id: 'default_human',
            name: 'Default Human',
            price: 0,
            isUnlocked: true,
            primaryColor: Colors.blue,
            secondaryColor: Colors.lightBlue,
            attributes: {
              'jumpPower': 1.0,
              'speed': 1.0,
              'dashPower': 1.0,
              'coinMultiplier': 1.0,
            },
          );

      // Her zaman insan oyuncuyu oluştur
      humanPlayer = HumanPlayerComponent(
        position: Vector2(size.x * 0.2, size.y - groundHeight),
        character: defaultCharacter,
        primaryColor: defaultCharacter.primaryColor,
        secondaryColor: defaultCharacter.secondaryColor,
        groundHeight: groundHeight,
        weapon: Weapon.fromType(WeaponType.pistol),
      );
      add(humanPlayer!);

      // Ses servisini başlatmıyoruz, tamamen devre dışı bırakıyoruz
      // await audioService.initialize();
    } catch (e) {
      print("HATA: onLoad sırasında hata oluştu - $e");
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    // Ekstra erken kontrol - oyun durmuşsa veya bitmişse hiçbir güncelleme yapma
    if (isPaused || isGameOver) {
      super.update(0); // Minimum update ile çağır
      return;
    }

    // scoreText başlatılmamışsa güncelleme yapma
    if (scoreText == null) {
      super.update(0);
      return;
    }

    // dt değerini sınırla - aşırı yüksek değerler ani hareketlere sebep olabilir
    // Önceki 0.05 yerine 0.03'e düşürdük, daha stabil performans için
    final cappedDt = dt > 0.03 ? 0.03 : dt;

    // FPS hesaplama - her zaman gerekli değil, sadece arada bir güncelle
    _fpsUpdateTime += cappedDt;
    if (_fpsUpdateTime >= _fpsUpdateInterval) {
      _fps = 1.0 / cappedDt;
      _fpsUpdateTime = 0;
    }

    // Performans için gameTime güncelleme sıklığını azalt
    gameTime += cappedDt;

    // Zamanlayıcıları güncelle - bu kritik olduğu için her frame'de yapılmalı
    try {
      obstacleSpawnTimer?.update(cappedDt);
      collectibleSpawnTimer?.update(cappedDt);
      enemySpawnTimer?.update(cappedDt);
      platformSpawnTimer?.update(cappedDt);
    } catch (e) {
      print("HATA: Timer güncellenirken hata oluştu: $e");
      _initializeTimers(); // Hata durumunda yeniden initialize et
    }

    // Skor güncellemesi (zamanla artan skor)
    // Skor hesaplama basitleştirildi
    score +=
        (5 * cappedDt * difficultyMultiplier * levelScoreMultiplier).toInt();
    scoreText!.text = 'SCORE: $score';

    // Güç-yükseltmelerini güncelle
    _updatePowerUps(cappedDt);

    // Güçlendirilmiş silah zamanlayıcısını güncelle
    if (hasPoweredWeapon) {
      poweredWeaponTimer -= cappedDt;
      if (poweredWeaponTimer <= 0) {
        hasPoweredWeapon = false;
        // Silah güç efektini kapat
        humanPlayer?.powerUpWeapon(0);
      }
    }

    // Mermi sayısı ve silah bilgisi güncelleme
    if (humanPlayer != null) {
      final ammoText = children.whereType<TextComponent>().firstWhere(
            (text) => text.text.startsWith('AMMO:'),
            orElse: () => TextComponent(text: ''),
          );

      final weaponText = children.whereType<TextComponent>().firstWhere(
            (text) => text.text.startsWith('WEAPON:'),
            orElse: () => TextComponent(text: ''),
          );

      if (ammoText.text.isNotEmpty) {
        ammoText.text = 'AMMO: ${humanPlayer!.ammoSystem.currentAmmo}';
      }

      if (weaponText.text.isNotEmpty) {
        final weaponName = humanPlayer!.currentWeapon.name;
        weaponText.text = 'WEAPON: $weaponName';

        // Silah yeniden dolduruluyorsa bunu belirt
        if (humanPlayer!.isReloading) {
          weaponText.text += ' (Reloading)';
        }
      }
    }

    // Seviye atlama mesaj süresini güncelle
    if (showLevelUpMessage) {
      levelUpMessageTimer -= cappedDt;
      if (levelUpMessageTimer <= 0) {
        showLevelUpMessage = false;
      }
    }

    // Performans optimizasyonu: Sadece ekranda görünür bileşenleri güncelle

    // Sadece ekranda veya yakın olan engelleri güncelle - Optimize edilmiş döngü
    for (int i = obstacles.length - 1; i >= 0; i--) {
      final obstacle = obstacles[i];
      if (obstacle.position.x < -obstacle.size.x) {
        // Ekrandan tamamen çıkmış engeli kaldır
        obstacles.removeAt(i);
        obstacle.removeFromParent();
      } else if (obstacle.position.x < size.x + 100) {
        // Sadece ekranda veya yakında olan engelleri güncelle
        obstacle.update(cappedDt);
      }
    }

    // Sadece ekranda veya yakın olan toplanabilir öğeleri güncelle - Optimize edilmiş döngü
    for (int i = collectibles.length - 1; i >= 0; i--) {
      final collectible = collectibles[i];
      if (collectible.position.x < -collectible.size.x) {
        // Ekrandan tamamen çıkmış öğeyi kaldır
        collectibles.removeAt(i);
        collectible.removeFromParent();
      } else if (collectible.position.x < size.x + 100) {
        // Sadece ekranda veya yakında olan öğeleri güncelle
        collectible.update(cappedDt);
      }
    }

    // Sadece ekranda veya yakın olan düşmanları güncelle - Optimize edilmiş döngü
    for (int i = enemies.length - 1; i >= 0; i--) {
      final enemy = enemies[i];
      if (enemy.position.x < -enemy.size.x) {
        // Ekrandan tamamen çıkmış düşmanı kaldır
        enemies.removeAt(i);
        enemy.removeFromParent();
      } else if (enemy.position.x < size.x + 100) {
        // Sadece ekranda veya yakında olan düşmanları güncelle
        enemy.update(cappedDt);
      }
    }

    // Sadece ekranda veya yakın olan platformları güncelle - Optimize edilmiş döngü
    for (int i = platforms.length - 1; i >= 0; i--) {
      final platform = platforms[i];
      if (platform.position.x < -platform.size.x) {
        // Ekrandan tamamen çıkmış platformu kaldır
        platforms.removeAt(i);
        platform.removeFromParent();
      } else if (platform.position.x < size.x + 100) {
        // Sadece ekranda veya yakında olan platformları güncelle
        platform.update(cappedDt);
      }
    }

    // Oyun zorluğunu artır - zamanla oyun hızı artsın
    if (gameSpeed < maxGameSpeed && !hasSlowMotion) {
      gameSpeed += gameSpeedIncreaseRate * cappedDt * difficultyMultiplier;
    }

    super.update(cappedDt); // Component.update çağrısı
  }

  void _updateFps(double dt) {
    _fpsUpdateTime += dt;
    if (_fpsUpdateTime >= _fpsUpdateInterval) {
      _fps = 1 / dt;
      _fpsUpdateTime = 0;
    }
  }

  // Dağları ekle
  void _addMountains(GameTheme? theme) {
    const mountainCount = 5;
    final random = math.Random();
    for (int i = 0; i < mountainCount; i++) {
      add(
        MountainComponent(
          position: Vector2(
            random.nextDouble() * size.x,
            size.y - groundHeight - random.nextDouble() * 100,
          ),
          size: Vector2(
            100 + random.nextDouble() * 100,
            80 + random.nextDouble() * 120,
          ),
          mountainColor: theme?.primaryColor ?? Colors.blueGrey.shade700,
          game: this,
        ),
      );
    }
  }

  // Bulutları ekle - Bulut sayısını parametre olarak alıyoruz
  void _addClouds(int cloudCount) {
    final random = math.Random();
    for (int i = 0; i < cloudCount; i++) {
      add(
        CloudComponent(
          position: Vector2(
            random.nextDouble() * size.x,
            random.nextDouble() * size.y * 0.4,
          ),
          size: Vector2(
            80 + random.nextDouble() * 80,
            40 + random.nextDouble() * 30,
          ),
        ),
      );
    }
  }

  void _spawnObstacle() {
    if (obstacles.length < 5) {
      // Ekranda en fazla 5 engel olsun
      final random = math.Random();
      final obstacleType = ObstacleType.values[
          random.nextInt(ObstacleType.values.length)]; // Rastgele engel türü

      // Rastgele Y pozisyonu belirle
      double obstacleY;
      if (random.nextBool()) {
        // %50 ihtimalle zeminde
        obstacleY = size.y - groundHeight;
      } else {
        // %50 ihtimalle biraz yukarıda (kayarak geçilebilir?)
        obstacleY = size.y - groundHeight - 60;
      }

      final obstacle = ObstacleComponent(
        position: Vector2(size.x + 50, obstacleY), // Güncellenmiş Y pozisyonu
        type: obstacleType,
        color: currentTheme?.obstacleColor ?? Colors.brown, // Tema rengi
        game: this,
      );
      obstacles.add(obstacle);
      add(obstacle);
    }
  }

  void _spawnCollectible() {
    if (collectibles.length < 3) {
      // Ekranda en fazla 3 toplanabilir olsun
      final random = math.Random();

      // Toplanabilir türünü belirle - %70 ihtimalle altın olsun
      CollectibleType type;
      final typeRoll = random.nextDouble();

      if (typeRoll < 0.70) {
        type = CollectibleType.coin; // Çoğunlukla altın
      } else if (typeRoll < 0.80) {
        type = CollectibleType.extraLife; // %10 ihtimalle can
      } else if (typeRoll < 0.85) {
        type = CollectibleType.shield; // %5 ihtimalle kalkan
      } else if (typeRoll < 0.90) {
        type = CollectibleType.magnet; // %5 ihtimalle mıknatıs
      } else if (typeRoll < 0.95) {
        type = CollectibleType.slowMotion; // %5 ihtimalle yavaş çekim
      } else {
        type = CollectibleType.scoreBoost; // %5 ihtimalle skor artırıcı
      }

      // Toplanabilirin konumunu belirle
      final collectible = CollectibleComponent(
        position: Vector2(
          size.x + 100 + random.nextDouble() * 200,
          size.y -
              groundHeight -
              50 -
              random.nextDouble() * 100, // Daha yukarıda olabilsin
        ),
        type: type,
        game: this,
      );

      collectibles.add(collectible);
      add(collectible);

      // Debug amaçlı
      print("Toplanabilir oluşturuldu: ${type.toString()}");
    }
  }

  void _removeOffScreenObjects() {
    obstacles.removeWhere((obstacle) {
      final shouldRemove = obstacle.position.x < -obstacle.size.x;
      if (shouldRemove) {
        obstacle.removeFromParent();
      }
      return shouldRemove;
    });

    collectibles.removeWhere((collectible) {
      final shouldRemove = collectible.position.x < -collectible.size.x;
      if (shouldRemove) {
        collectible.removeFromParent();
      }
      return shouldRemove;
    });
  }

  void playerJump() {
    // Eskiden playerComponent'i çağırırdı, şimdi sadece humanPlayer'ı çağır
    // player?.jump();
    humanPlayer?.jump();
  }

  @override
  void onTapDown(TapDownEvent event) {
    print("onTapDown triggered! isGameOver: $isGameOver, isPaused: $isPaused");
    if (isGameOver) {
      restartGame();
    } else if (isPaused) {
      resumeGame();
    } else {
      print("Calling playerJump() from onTapDown...");
      playerJump();
    }
  }

  void handleCollision(PositionComponent other) {
    if (other is ObstacleComponent) {
      if (hasShield) {
        hasShield = false;
        // Ses kapatıldı
        // audioService.playSfx(SoundEffect.hit);
        other.removeFromParent();
        obstacles.remove(other);
        // particleSystem.createExplosion(position: other.position, color: Colors.blue, count: 30);
      } else {
        loseLife();
        // Ses kapatıldı
        // audioService.playSfx(SoundEffect.hit);
        other.removeFromParent();
        obstacles.remove(other);
      }
    } else if (other is CollectibleComponent) {
      collect(other);
      // Ses kapatıldı
      // audioService.playSfx(SoundEffect.collect);
      other.removeFromParent();
      collectibles.remove(other);
    }
  }

  void collect(CollectibleComponent collectible) {
    // particleSystem.createExplosion(position: collectible.position, color: collectible.color, count: 20);
    switch (collectible.type) {
      case CollectibleType.coin:
        score += (50 * difficultyMultiplier * levelScoreMultiplier).toInt();
        combo++;
        maxCombo = max(maxCombo, combo);
        break;
      case CollectibleType.magnet:
        hasMagnet = true;
        magnetTimer = 5.0;
        // Eski player component kaldırıldı
        // player?.activateMagnetEffect();
        // audioService.playSfx(SoundEffect.powerUp);
        // particleSystem.createPowerUpEffect(position: collectible.position, color: Colors.grey);
        break;
      case CollectibleType.shield:
        hasShield = true;
        shieldTimer = 10.0;
        // Eski player component kaldırıldı
        // player?.activateShieldEffect();
        // audioService.playSfx(SoundEffect.powerUp);
        // particleSystem.createPowerUpEffect(position: collectible.position, color: Colors.lightBlueAccent);
        break;
      case CollectibleType.slowMotion:
        hasSlowMotion = true;
        slowMotionTimer = 3.0;
        gameSpeed *= 0.5;
        // audioService.playSfx(SoundEffect.powerUp);
        // particleSystem.createPowerUpEffect(position: collectible.position, color: Colors.cyanAccent);
        break;
      case CollectibleType.extraLife:
        if (lives < 3) {
          lives++;
          onLifeLost?.call(); // Can UI'ını güncelle
          // audioService.playSfx(SoundEffect.powerUp); // veya farklı bir ses?
          // particleSystem.createStars(position: collectible.position, color: Colors.redAccent);
        } else {
          score += (100 * difficultyMultiplier * levelScoreMultiplier).toInt();
          // audioService.playSfx(SoundEffect.collect); // Can full ise coin sesi?
          // particleSystem.createExplosion(position: collectible.position, color: Colors.redAccent, count: 10);
        }
        break;
      case CollectibleType.scoreBoost:
        score += (250 * difficultyMultiplier * levelScoreMultiplier).toInt();
        combo += 3;
        maxCombo = max(maxCombo, combo);
        // audioService.playSfx(SoundEffect.levelUp); // veya powerUp?
        // particleSystem.createConfetti(position: collectible.position);
        break;
      case CollectibleType.speedBoost:
        gameSpeed *= 1.5;
        // audioService.playSfx(SoundEffect.dash); // veya powerUp?
        // particleSystem.createStars(position: collectible.position, color: Colors.orangeAccent);
        Future.delayed(const Duration(seconds: 5), () {
          if (!isGameOver && !isPaused) {
            gameSpeed /= 1.5;
            gameSpeed = max(gameSpeed, initialGameSpeed);
          }
        });
        break;
    }
    scoreText!.text = 'SCORE: $score';
  }

  void _updatePowerUps(double dt) {
    // Mıknatıs
    if (hasMagnet) {
      magnetTimer -= dt;
      if (magnetTimer <= 0) {
        hasMagnet = false;
        // player?.deactivateMagnetEffect();
      } else {
        // Mıknatıs etkinken yakındaki toplanabilirleri çek
        _attractCollectibles(dt);
      }
    }

    // Kalkan
    if (hasShield) {
      shieldTimer -= dt;
      if (shieldTimer <= 0) {
        hasShield = false;
        // player?.deactivateShieldEffect();
      }
    }

    // Yavaş Çekim
    if (hasSlowMotion) {
      slowMotionTimer -= dt;
      if (slowMotionTimer <= 0) {
        hasSlowMotion = false;
        gameSpeed = gameSpeed * 2; // Hızı normale döndür
        // Hızın maximum hızı geçmediğinden emin ol
        gameSpeed = min(gameSpeed, maxGameSpeed * levelSpeedMultiplier);
      }
    }
  }

  void _attractCollectibles(double dt) {
    if (humanPlayer == null) return;
    const magnetRange = 150.0; // Mıknatıs etki alanı
    final playerCenter = humanPlayer!.position + humanPlayer!.size / 2;

    for (final collectible in collectibles) {
      final distance =
          playerCenter.distanceTo(collectible.position + collectible.size / 2);
      if (distance < magnetRange) {
        final direction =
            (playerCenter - (collectible.position + collectible.size / 2))
                .normalized();
        // Mesafeye göre çekim gücünü ayarla (yaklaştıkça hızlanır)
        final speed = (magnetRange - distance) * 5;
        collectible.position += direction * speed * dt; // dt kullanılıyor
      }
    }
  }

  void loseLife() {
    if (isGameOver) return; // Oyun bittiyse tekrar can kaybetme
    print(
        "loseLife called! Current lives: $lives"); // Metodun çağrıldığını logla

    combo = 0; // Combo sıfırlanır
    lives--;
    print("Lives decremented. New lives: $lives"); // Azaltma sonrası logla

    // Callback'i çağır (null değilse)
    if (onLifeLost != null) {
      onLifeLost!();
    }

    player?.startBlinking(); // Oyuncuyu yanıp söndür

    if (lives <= 0) {
      print("Lives are zero or less. Calling gameOver().");
      gameOver();
    } else {
      print("Player has $lives lives remaining.");
    }
  }

  void gameOver() {
    isGameOver = true;
    isPaused = true;
    gameSpeed = 0;
    // Ses kapatıldı
    // audioService.stopMusic();
    // audioService.playSfx(SoundEffect.gameOver);

    // Game over overlay'ini etkinleştir
    overlays.add('game_over');
    overlays.remove('pause_button');
    // overlays.remove('game_controls'); // Kontroller görünür kalsın

    // Callback'i çağır (null değilse)
    if (onGameOver != null) {
      onGameOver!();
    }

    // Yüksek skoru kontrol et ve güncelle (artık context olmadan)
    if (score > highScore) {
      highScore = score; // Oyunun kendi içindeki yüksek skor bilgisini güncelle
      print("Yeni Yüksek Skor Ayarlandı (Oyun İçi): $highScore");
      // TODO: Bu yüksek skoru Provider veya başka bir state management ile globale kaydetmek gerekebilir.
      // Bu işlem GameScreen widget'ı içinde veya overlay'de yapılabilir.
    }
    print(
        "Oyun Bitti! Skor: $score, En Yüksek Skor: $highScore, Max Combo: $maxCombo");
  }

  void restartGame() {
    // Overlay'leri güncelle
    overlays.remove('game_over');
    overlays.add('pause_button');
    overlays.add('game_controls');

    // Oyun durumunu sıfırla
    score = 0;
    lives = 3;
    gameSpeed = initialGameSpeed; // Başlangıç hızına dön
    isGameOver = false;
    isPaused = false;
    obstacles.clear();
    collectibles.clear();
    enemies.clear();
    platforms.clear();
    children
        .whereType<ObstacleComponent>()
        .forEach((c) => c.removeFromParent());
    children
        .whereType<CollectibleComponent>()
        .forEach((c) => c.removeFromParent());
    children.whereType<EnemyComponent>().forEach((c) => c.removeFromParent());
    children
        .whereType<PlatformComponent>()
        .forEach((c) => c.removeFromParent());
    gameTime = 0;
    combo = 0;
    maxCombo = 0;
    difficultyMultiplier = 1.0; // Zorluk çarpanını sıfırla
    hasMagnet = false;
    hasShield = false;
    hasSlowMotion = false;
    magnetTimer = 0;
    shieldTimer = 0;
    slowMotionTimer = 0;
    showLevelUpMessage = false; // Seviye mesajını gizle

    // Karakteri yeniden oluştur
    // Mevcut humanPlayer'ı kaldır
    if (humanPlayer != null) {
      humanPlayer!.removeFromParent();
      humanPlayer = null;
    }

    // Yeni humanPlayer oluştur
    final defaultCharacter = selectedCharacter ??
        PlayerCharacter(
          id: 'default_human',
          name: 'Default Human',
          price: 0,
          isUnlocked: true,
          primaryColor: Colors.blue,
          secondaryColor: Colors.lightBlue,
          attributes: {
            'jumpPower': 1.0,
            'speed': 1.0,
            'dashPower': 1.0,
            'coinMultiplier': 1.0,
          },
        );

    humanPlayer = HumanPlayerComponent(
      position: Vector2(size.x * 0.2, size.y - groundHeight),
      character: defaultCharacter,
      primaryColor: defaultCharacter.primaryColor,
      secondaryColor: defaultCharacter.secondaryColor,
      groundHeight: groundHeight,
      weapon: Weapon.fromType(WeaponType.pistol),
    );
    add(humanPlayer!);

    // Zamanlayıcıları sıfırla ve başlat
    obstacleSpawnTimer?.stop();
    obstacleSpawnTimer?.start();
    collectibleSpawnTimer?.stop();
    collectibleSpawnTimer?.start();
    enemySpawnTimer?.stop();
    enemySpawnTimer?.start();
    platformSpawnTimer?.stop();
    platformSpawnTimer?.start();

    // Ses kapatıldı
    // audioService.playMusic(MusicTrack.game);

    print("Oyun Yeniden Başlatıldı!");
  }

  void pauseGame() {
    if (!isGameOver) {
      isPaused = true;
      pauseEngine();
      // audioService.pauseMusic(); // _audioService -> audioService
      print("Oyun Durduruldu");
    }
  }

  void resumeGame() {
    if (isPaused && !isGameOver) {
      isPaused = false;
      resumeEngine();
      // audioService.resumeMusic(); // _audioService -> audioService
      print("Oyuna Devam Ediliyor");
    }
  }

  // Seviye atlama fonksiyonu (örnek)
  void levelUp() {
    // Bu fonksiyon dışarıdan çağrılabilir (örneğin belirli bir skora ulaşınca)
    // Veya oyun içindeki bir event ile tetiklenebilir
    // Yeni seviye bilgilerini al (varsayımsal)
    final currentLevelId = currentLevel?.id ?? 1;
    final nextLevelId = currentLevelId + 1;
    //TODO: Get next level data from a level service or list
    Level nextLevel = Level(
      id: nextLevelId, // id eklendi
      name: "Seviye $nextLevelId",
      description: "Yeni seviye", // Açıklama eklendi
      requiredXP: (currentLevel?.requiredXP ?? 1000) * 2, // requiredXP eklendi
      speedMultiplier: levelSpeedMultiplier * 1.1,
      scoreMultiplier: levelScoreMultiplier * 1.2,
      obstacleFrequency: max(1, levelObstacleFrequency - 1), // Daha sık engel
      // targetScore: (currentLevel?.targetScore ?? 1000) * 2 // Level modelinde targetScore yok, kaldırıldı
    );

    print("SEVİYE ATLANDI! Yeni Seviye: ${nextLevel.name}");

    currentLevel = nextLevel;
    levelSpeedMultiplier = nextLevel.speedMultiplier;
    levelScoreMultiplier = nextLevel.scoreMultiplier;
    levelObstacleFrequency = nextLevel.obstacleFrequency;

    // Oyun hızını yeni seviyeye göre ayarla
    initialGameSpeed = 200.0 * levelSpeedMultiplier;
    // İsteğe bağlı: Mevcut hızı da biraz artırabiliriz
    gameSpeed = max(gameSpeed, initialGameSpeed);
    maxGameSpeed *= 1.05; // Max hızı da biraz artır

    // Engel zamanlayıcısını yeni frekansla güncelle
    obstacleSpawnTimer?.stop();
    obstacleSpawnTimer = Timer(levelObstacleFrequency.toDouble(),
        onTick: _spawnObstacle, repeat: true);
    obstacleSpawnTimer?.start();

    // Seviye atlama mesajını göster
    showLevelUpMessage = true;
    levelUpMessage = "Seviye Atlandı: ${nextLevel.name}!";
    levelUpMessageTimer = 3.0; // 3 saniye göster
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Canları göster (kalp ikonları)
    final paint = Paint()..color = Colors.red;
    const heartSize = 20.0;
    const spacing = 5.0;
    for (int i = 0; i < lives; i++) {
      final path = Path();
      path.moveTo(size.x - 30 - (i * (heartSize + spacing)), 30);
      path.arcToPoint(
        Offset(size.x - 30 - (i * (heartSize + spacing)) + heartSize / 2, 25),
        radius: const Radius.circular(heartSize / 4),
        clockwise: false,
      );
      path.arcToPoint(
        Offset(size.x - 30 - (i * (heartSize + spacing)) + heartSize, 30),
        radius: const Radius.circular(heartSize / 4),
        clockwise: false,
      );
      path.cubicTo(
          size.x - 30 - (i * (heartSize + spacing)) + heartSize,
          35,
          size.x - 30 - (i * (heartSize + spacing)) + heartSize / 2,
          40,
          size.x - 30 - (i * (heartSize + spacing)) + heartSize / 2,
          45);
      path.cubicTo(
          size.x - 30 - (i * (heartSize + spacing)) + heartSize / 2,
          40,
          size.x - 30 - (i * (heartSize + spacing)),
          35,
          size.x - 30 - (i * (heartSize + spacing)),
          30);
      canvas.drawPath(path, paint);
    }

    // FPS göstergesi (isteğe bağlı, debug için)
    final fpsPaint = TextPaint(
      style: const TextStyle(color: Colors.white, fontSize: 12),
    );
    fpsPaint.render(canvas, 'FPS: ${_fps.toStringAsFixed(1)}', Vector2(20, 50));

    // Combo göstergesi
    if (combo > 1) {
      final comboPaint = TextPaint(
        style: TextStyle(
          color: Colors.orangeAccent,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 3,
                offset: const Offset(1, 1)),
          ],
        ),
      );
      comboPaint.render(canvas, 'Combo: x$combo', Vector2(size.x / 2 - 50, 30));
    }

    // Güç-yükseltme durumları (ikonlar veya zamanlayıcılar)
    _renderPowerUpTimers(canvas);

    // Seviye atlama mesajı
    if (showLevelUpMessage) {
      final levelUpPaint = TextPaint(
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.yellowAccent,
          shadows: [
            Shadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 4,
                offset: const Offset(2, 2)),
          ],
        ),
      );
      // Mesajı ekranın ortasında göster
      final textSize = levelUpPaint.getLineMetrics(levelUpMessage).size;
      levelUpPaint.render(canvas, levelUpMessage, size / 2 - textSize / 2);
    }
  }

  void _renderPowerUpTimers(Canvas canvas) {
    double startY = 80; // İkonların başlayacağı Y konumu
    const iconSize = 25.0;
    const padding = 10.0;
    final textStyle = const TextStyle(
        color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold);
    final textPaint = TextPaint(style: textStyle);

    // Mıknatıs
    if (hasMagnet && magnetTimer > 0) {
      // Basit bir mıknatıs ikonu çizimi (dikdörtgen + yarım daireler)
      final magnetPaint = Paint()..color = Colors.grey.shade400;
      final polePaint = Paint()..color = Colors.red.shade700;
      final bluePolePaint = Paint()
        ..color = Colors.blue.shade700; // Ayrı Paint nesnesi
      final rect = Rect.fromLTWH(20, startY, iconSize * 0.8, iconSize * 0.5);
      final rrect = RRect.fromRectAndCorners(rect,
          topLeft: Radius.circular(iconSize * 0.2),
          topRight: Radius.circular(iconSize * 0.2));
      canvas.drawRRect(rrect, magnetPaint);
      canvas.drawRect(
          Rect.fromLTWH(
              20, startY + iconSize * 0.5, iconSize * 0.2, iconSize * 0.5),
          polePaint); // Sol kutup
      canvas.drawRect(
          Rect.fromLTWH(20 + iconSize * 0.6, startY + iconSize * 0.5,
              iconSize * 0.2, iconSize * 0.5),
          bluePolePaint); // Sağ kutup (Doğru Paint nesnesi)

      // Kalan süreyi göster
      textPaint.render(canvas, magnetTimer.toStringAsFixed(1) + 's',
          Vector2(20 + iconSize + padding, startY + 5));
      startY += iconSize + padding; // Sonraki ikon için Y konumunu güncelle
    }

    // Kalkan
    if (hasShield && shieldTimer > 0) {
      // Basit bir kalkan ikonu çizimi
      final shieldPaint = Paint()
        ..color = Colors.blue.shade300
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final path = Path();
      path.moveTo(20 + iconSize / 2, startY); // Üst orta nokta
      path.lineTo(20, startY + iconSize * 0.3); // Sol üst köşe
      path.quadraticBezierTo(20, startY + iconSize, 20 + iconSize / 2,
          startY + iconSize); // Alt sol kavis
      path.quadraticBezierTo(20 + iconSize, startY + iconSize, 20 + iconSize,
          startY + iconSize * 0.3); // Alt sağ kavis
      path.lineTo(
          20 + iconSize / 2, startY); // Sağ üst köşe -> Üst orta noktaya kapat
      path.close();
      canvas.drawPath(path, shieldPaint);
      canvas.drawPath(path, borderPaint);

      // Kalan süreyi göster
      textPaint.render(canvas, shieldTimer.toStringAsFixed(1) + 's',
          Vector2(20 + iconSize + padding, startY + 5));
      startY += iconSize + padding;
    }

    // Yavaş Çekim
    if (hasSlowMotion && slowMotionTimer > 0) {
      // Basit bir saat ikonu çizimi
      final clockPaint = Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final handPaint = Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(20 + iconSize / 2, startY + iconSize / 2),
          iconSize / 2, clockPaint);
      // Akrep ve yelkovan (basit çizgiler)
      canvas.drawLine(
          Offset(20 + iconSize / 2, startY + iconSize / 2),
          Offset(20 + iconSize / 2, startY + iconSize * 0.2),
          handPaint..strokeWidth = 2); // Yelkovan (yukarı)
      canvas.drawLine(
          Offset(20 + iconSize / 2, startY + iconSize / 2),
          Offset(20 + iconSize * 0.8, startY + iconSize / 2),
          handPaint..strokeWidth = 1); // Akrep (sağa)

      // Kalan süreyi göster
      textPaint.render(canvas, slowMotionTimer.toStringAsFixed(1) + 's',
          Vector2(20 + iconSize + padding, startY + 5));
      startY += iconSize + padding;
    }
  }

  // Oyun dışından çağrılacak metodlar
  void setOnGameOverCallback(Function() callback) {
    onGameOver = callback;
  }

  void setOnLifeLostCallback(Function() callback) {
    onLifeLost = callback;
  }

  // Mermi eklemek için yeni metod
  void addAmmo(int amount) {
    humanPlayer?.ammoSystem.reload(amount);
  }

  // Düşmandan mermi kutusu düşürme metodu
  void spawnAmmoDrop(Vector2 position) {
    final ammoBox = AmmoCollectibleComponent(
      position: position,
      size: Vector2(30, 20),
      ammoAmount: 10,
    );
    add(ammoBox);
  }

  // Arkaplan renkleri için yardımcı metod
  List<Color> _getBackgroundColors(GameTheme? theme) {
    if (theme != null && theme.backgroundGradient.length >= 3) {
      return theme.backgroundGradient;
    }

    // Tema null veya tema gradyanı 3'ten az renk içeriyorsa varsayılan renkler
    return [
      Colors.lightBlue.shade200,
      Colors.lightBlue.shade400,
      Colors.blue.shade600
    ];
  }

  // Düşman oluştur
  void _spawnEnemy() {
    // Oyun durmuşsa veya bittiyse düşman oluşturma
    if (isPaused || isGameOver) return;

    // Seviyeye göre rastgele düşman oluştur
    final enemy = Enemy.createRandomEnemy(currentLevel?.id ?? 1);

    // Düşmanın başlangıç pozisyonu - Ekranın sağından
    final random = Random();
    final enemyX = size.x +
        300 +
        random.nextDouble() * 200; // Daha uzaktan ve rastgele başlat

    // Eğer uçan düşmansa, yüksekte olsun
    double enemyY;
    if (enemy.canFly) {
      // Rastgele bir yükseklik - zemin seviyesinden yukarıda
      enemyY = size.y - groundHeight - random.nextDouble() * 200 - 50;
    } else {
      // Yerde olan düşman
      enemyY = size.y - groundHeight;
    }

    final enemyPosition = Vector2(enemyX, enemyY);
    final enemySize = Vector2(enemy.size, enemy.size);

    final enemyComponent = EnemyComponent(
      enemy: enemy,
      position: enemyPosition,
      size: enemySize,
    );

    enemies.add(enemyComponent);
    add(enemyComponent);
  }

  // Timer'ları initialize etmek için metod
  void _initializeTimers() {
    print("Timer'lar initialize ediliyor...");

    // Eğer daha önce initialize edilmediyse
    obstacleSpawnTimer = Timer(
      levelObstacleFrequency.toDouble(),
      onTick: _spawnObstacle,
      repeat: true,
    );

    collectibleSpawnTimer = Timer(
      3,
      onTick: _spawnCollectible,
      repeat: true,
    );

    enemySpawnTimer = Timer(
      2.0,
      onTick: _spawnEnemy,
      repeat: true,
    );

    platformSpawnTimer = Timer(
      3.0,
      onTick: _spawnPlatform,
      repeat: true,
    );

    print("Timer'lar başarıyla initialize edildi");
  }

  // Platform oluştur
  void _spawnPlatform() {
    // Oyun durmuşsa veya bittiyse platform oluşturma
    if (isPaused || isGameOver) return;

    // Rastgele platform oluştur (seviyeye göre)
    final platform = GamePlatform.randomPlatform(currentLevel?.id ?? 1);

    // Başlangıç X pozisyonu - Ekranın sağından
    var platformX = size.x + 50; // Ekranın biraz dışından başlat

    // Başlangıç Y pozisyonu - Bir önceki platformun yüksekliğine göre
    double platformY;

    // Katman seviyesini rastgele değiştir (zemin veya üst katmanlar)
    final random = Random();
    final shouldChangeLayer =
        random.nextDouble() < 0.3; // %30 ihtimalle katman değiştir

    if (shouldChangeLayer) {
      // Mevcut katman seviyesini rastgele değiştir (0=zemin, 1,2,3=üst katmanlar)
      final newLayerLevel = random.nextInt(4); // 0-3 arası katmanlar

      if (newLayerLevel == 0) {
        // Zemin seviyesi
        platformY = size.y - groundHeight;
      } else {
        // Üst katmanlar - her katman için daha yukarı
        platformY = size.y - groundHeight - (newLayerLevel * 120);
      }

      currentLayerLevel = newLayerLevel;
    } else {
      // Mevcut katmanda devam et
      if (currentLayerLevel == 0) {
        // Zemin seviyesi
        platformY = size.y - groundHeight;
      } else {
        // Üst katmanlar - mevcut katman seviyesindeki yükseklik
        platformY = size.y - groundHeight - (currentLayerLevel * 120);
      }
    }

    // Platformlar arası mesafe
    final distanceBetweenPlatforms =
        platform.width + random.nextDouble() * 200 + 100;

    // Eğer son platformdan belirli bir mesafede değilse, mesafeyi ayarla
    if (lastPlatformX > 0 &&
        platformX - lastPlatformX < distanceBetweenPlatforms) {
      platformX = lastPlatformX + distanceBetweenPlatforms;
    }

    // Son platform konumunu güncelle
    lastPlatformX = platformX;
    lastPlatformY = platformY;

    final platformPosition = Vector2(platformX, platformY);

    final platformComponent = PlatformComponent(
      platform: platform,
      position: platformPosition,
    );

    platforms.add(platformComponent);
    add(platformComponent);
  }
}

// Yeni bir GameScreen widget sınıfı ekleniyor
class GameScreen extends StatelessWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return Scaffold(
      body: GameWidget.controlled(
        initialActiveOverlays: const ['pause_button', 'game_controls'],
        gameFactory: () => RunnerGame(
          selectedCharacter: gameState.currentCharacter,
          currentTheme: gameState.currentTheme,
          currentLevel: gameState.currentLevel,
          highScore: gameState.highScore,
        ),
        loadingBuilder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
        overlayBuilderMap: {
          'pause_button': (context, RunnerGame runnerGame) {
            return Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.pause, color: Colors.white),
                onPressed: () {
                  runnerGame.isPaused
                      ? runnerGame.resumeGame()
                      : runnerGame.pauseGame();
                },
              ),
            );
          },
          'game_over': (context, RunnerGame runnerGame) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'GAME OVER',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      shadows: [
                        Shadow(
                          blurRadius: 5,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Score: ${runnerGame.score}',
                    style: const TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'High Score: ${runnerGame.highScore}',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      runnerGame.restartGame();
                    },
                    child: const Text(
                      'PLAY AGAIN',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'BACK TO MENU',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
            );
          },
          'game_controls': (context, RunnerGame runnerGame) {
            final screenSize = MediaQuery.of(context).size;
            return Stack(
              children: [
                // Zıplama için sol yarıya tıklama algılayıcı
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: screenSize.width / 2,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      runnerGame.playerJump();
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),

                // Ateş etme butonu (sağ alt köşede)
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: FloatingActionButton(
                    heroTag: "fireButton",
                    backgroundColor: Colors.red,
                    onPressed: () {
                      runnerGame.humanPlayer?.shoot();
                    },
                    child: const Icon(Icons.flash_on),
                  ),
                ),
              ],
            );
          },
        },
      ),
    );
  }
}
