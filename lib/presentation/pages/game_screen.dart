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
import '../../services/audio_service.dart';
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

class RunnerGame extends FlameGame
    with HasCollisionDetection, HasGameRef, TapCallbacks, KeyboardEvents {
  // Oyun değişkenleri
  double groundHeight = 80.0;
  double gameSpeed = 300.0;
  double initialGameSpeed = 300.0;
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
  late TextComponent scoreText;
  final List<ObstacleComponent> obstacles = [];
  final List<CollectibleComponent> collectibles = [];

  // Zamanlayıcılar
  late Timer obstacleSpawnTimer;
  late Timer collectibleSpawnTimer;

  // FPS hesaplama
  double _fps = 0;
  double _fpsUpdateTime = 0;
  final double _fpsUpdateInterval = 0.5;

  // Callback fonksiyonları
  Function()? onGameOver;
  Function()? onLifeLost;

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

  // Ses servisi
  final AudioService audioService = AudioService(); // Public yapıldı

  // Parçacık sistemi
  late ParticleSystem particleSystem;

  // Karakter sistemi
  final PlayerCharacter? selectedCharacter;
  final GameTheme? currentTheme;

  // Constructor güncellendi
  RunnerGame({
    required this.selectedCharacter,
    required this.currentTheme,
    required this.currentLevel,
    required this.highScore,
  });

  @override
  Future<void> onLoad() async {
    // GameState'i alalım
    // final gameState = context != null
    //     ? Provider.of<GameState>(context!, listen: false)
    //     : null;

    // Mevcut temayı al
    // final currentTheme = gameState?.currentTheme;

    // Mevcut karakteri al
    // selectedCharacter = gameState?.currentCharacter;

    // Mevcut seviyeyi al ve oyun değişkenlerini ayarla
    if (currentLevel != null) {
      // Seviye çarpanlarını ayarla
      levelSpeedMultiplier = currentLevel!.speedMultiplier;
      levelScoreMultiplier = currentLevel!.scoreMultiplier;
      levelObstacleFrequency = currentLevel!.obstacleFrequency;

      // Başlangıç hızını seviyeye göre ayarla
      initialGameSpeed = 300.0 * levelSpeedMultiplier;
      gameSpeed = initialGameSpeed;

      print("Seviye yüklendi: ${currentLevel!.name}, Hız: $gameSpeed");
    } else {
      print("UYARI: currentLevel null geldi!");
      // Varsayılan değerler zaten ayarlı
    }

    // Parçacık sistemi oluştur
    particleSystem = ParticleSystem(maxParticles: 300);
    add(particleSystem);

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

    // Bulutlar (dekortif elementler) - Daha fazla bulut ekliyoruz
    _addClouds(8);

    // Oyuncu - önceden oluşturulmamışsa oluştur
    if (player == null) {
      print(
          "RunnerGame.onLoad: PlayerComponent oluşturuluyor. Karakter ID: ${selectedCharacter?.id ?? 'PARAM NULL'}");
      player = PlayerComponent(
        // Anchor.bottomCenter olduğu için X konumu aynı kalabilir (ekranın %20'si)
        // Y konumu hala zeminde olmalı
        position: Vector2(size.x * 0.2, size.y - groundHeight),
        game: this,
        color: selectedCharacter?.primaryColor ??
            currentTheme?.playerColor ??
            Colors.red,
        secondaryColor: selectedCharacter?.secondaryColor,
        character: selectedCharacter,
      );
      add(player!);
    }

    // Skor metni - Geliştirilmiş tasarım
    scoreText = TextComponent(
      text: 'SCORE: $score',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 5, offset: Offset(2, 2)),
          ],
        ),
      ),
      position: Vector2(20, 20),
    );
    add(scoreText);

    // Engel oluşturma zamanlayıcısı - seviye bazlı frekans
    obstacleSpawnTimer = Timer(levelObstacleFrequency.toDouble(),
        onTick: _spawnObstacle, repeat: true);

    // Toplanabilir oluşturma zamanlayıcısı
    collectibleSpawnTimer = Timer(3, onTick: _spawnCollectible, repeat: true);

    // Ses servisini başlat
    await audioService.initialize(); // _audioService -> audioService

    // Oyun müziğini başlat
    audioService.playMusic(MusicTrack.game); // _audioService -> audioService

    // onGameReady callback'i çağır
    // onGameReady?.call(this);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    // FPS hesaplaması
    _updateFps(dt);

    // Toplam oyun süresini artır
    gameTime += dt;

    // Seviye atlandı mesajı gösteriliyorsa süresini azalt
    if (showLevelUpMessage) {
      levelUpMessageTimer -= dt;
      if (levelUpMessageTimer <= 0) {
        showLevelUpMessage = false;
      }
    }

    // Oyun durdurulmuşsa veya bitmişse güncelleme yapma
    if (isPaused || isGameOver) return;

    // Zamanlayıcıları güncelle
    obstacleSpawnTimer.update(dt);
    collectibleSpawnTimer.update(dt);

    // Zorluk seviyesini artır (oyun süresi ilerledikçe)
    if (gameSpeed < maxGameSpeed * levelSpeedMultiplier) {
      gameSpeed += gameSpeedIncreaseRate * levelSpeedMultiplier * dt;
    }

    // Güç yükseltmelerini yönet
    _updatePowerUps(dt);

    // Ekran dışına çıkan engelleri ve toplanabilirleri kaldır
    _removeOffScreenObjects();

    // Skor güncellemesi (zamanla artan skor)
    score += (10 * dt * difficultyMultiplier * levelScoreMultiplier).toInt();
    scoreText.text = 'SCORE: $score';

    super.update(dt);
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
          velocity: Vector2(20 + random.nextDouble() * 30, 0),
          gameWidth: size.x,
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
      final obstacle = ObstacleComponent(
        position: Vector2(size.x + 50, size.y - groundHeight),
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
      final type = CollectibleType.values[random.nextInt(
          CollectibleType.values.length)]; // Rastgele toplanabilir türü
      final collectible = CollectibleComponent(
        position: Vector2(
          size.x + 100 + random.nextDouble() * 200,
          size.y -
              groundHeight -
              50 -
              random.nextDouble() * 50, // Biraz yukarıda
        ),
        type: type,
        game: this,
      );
      collectibles.add(collectible);
      add(collectible);
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
    player?.jump(); // _player -> player
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
        // audioService.playSfx(SoundEffect.hit); // shieldBreak yerine hit?
        other.removeFromParent();
        obstacles.remove(other);
        // particleSystem.createExplosion(position: other.position, color: Colors.blue, count: 30); // explode yerine
        player?.startBlinking(
            duration: 1.0, color: Colors.blue); // _player -> player
      } else {
        loseLife();
        // audioService.playSfx(SoundEffect.hit); // collision yerine hit?
        other.removeFromParent();
        obstacles.remove(other);
      }
    } else if (other is CollectibleComponent) {
      collect(other);
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
        player?.activateMagnetEffect(); // _player -> player
        // audioService.playSfx(SoundEffect.powerUp);
        // particleSystem.createPowerUpEffect(position: collectible.position, color: Colors.grey);
        break;
      case CollectibleType.shield:
        hasShield = true;
        shieldTimer = 10.0;
        player?.activateShieldEffect(); // _player -> player
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
    scoreText.text = 'SCORE: $score';
  }

  void _updatePowerUps(double dt) {
    // Mıknatıs
    if (hasMagnet) {
      magnetTimer -= dt;
      if (magnetTimer <= 0) {
        hasMagnet = false;
        player?.deactivateMagnetEffect(); // _player -> player
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
        player?.deactivateShieldEffect(); // _player -> player
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
    if (player == null) return; // _player -> player
    const magnetRange = 150.0; // Mıknatıs etki alanı
    final playerCenter =
        player!.position + player!.size / 2; // _player -> player

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
    onLifeLost?.call(); // UI güncellemesi için callback
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
    // audioService.stopMusic(); // _audioService -> audioService
    // audioService.playSfx(SoundEffect.gameOver); // _audioService -> audioService

    onGameOver?.call();

    if (buildContext != null) {
      final gameState = Provider.of<GameState>(buildContext!, listen: false);
      if (score > gameState.highScore) {
        // gameState.setHighScore(score); // GameState'de setHighScore yok
        highScore = score;
        print("Yeni Yüksek Skor Ayarlandı (Yerel): $highScore");
        // gameState.saveHighScore(score); // varsayımsal kaydetme metodu
      }
      print(
          "Oyun Bitti! Skor: $score, En Yüksek Skor: ${gameState.highScore}, Max Combo: $maxCombo");
    } else {
      print(
          "Oyun Bitti! Skor: $score, En Yüksek Skor: $highScore (Context yok), Max Combo: $maxCombo");
    }
  }

  void restartGame() {
    // Oyun durumunu sıfırla
    score = 0;
    lives = 3;
    gameSpeed = initialGameSpeed; // Başlangıç hızına dön
    isGameOver = false;
    isPaused = false;
    obstacles.clear();
    collectibles.clear();
    children
        .whereType<ObstacleComponent>()
        .forEach((c) => c.removeFromParent());
    children
        .whereType<CollectibleComponent>()
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

    // Oyuncuyu sıfırla
    player?.reset(); // _player -> player

    // Zamanlayıcıları sıfırla ve başlat
    obstacleSpawnTimer.stop();
    obstacleSpawnTimer.start();
    collectibleSpawnTimer.stop();
    collectibleSpawnTimer.start();

    // Oyun müziğini tekrar başlat
    audioService.playMusic(MusicTrack.game); // _audioService -> audioService

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
    initialGameSpeed = 300.0 * levelSpeedMultiplier;
    // İsteğe bağlı: Mevcut hızı da biraz artırabiliriz
    gameSpeed = max(gameSpeed, initialGameSpeed);
    maxGameSpeed *= 1.05; // Max hızı da biraz artır

    // Engel zamanlayıcısını yeni frekansla güncelle
    obstacleSpawnTimer.stop();
    obstacleSpawnTimer = Timer(levelObstacleFrequency.toDouble(),
        onTick: _spawnObstacle, repeat: true);
    obstacleSpawnTimer.start();

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

  // BuildContext'i ayarla (Provider erişimi için)
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Yeniden boyutlandırmada context'i tekrar almak iyi olabilir ama widget ağacı içinde olmalı
    // if (buildContext == null && navigatorKey.currentContext != null) {
    //   buildContext = navigatorKey.currentContext;
    // }
  }

  // Klavye olaylarını dinle (Web/Desktop için)
  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isKeyDown = event is KeyDownEvent;
    final isSpace = keysPressed.contains(LogicalKeyboardKey.space);
    final isP = keysPressed.contains(LogicalKeyboardKey.keyP);
    final isR = keysPressed.contains(LogicalKeyboardKey.keyR);
    print(
        "onKeyEvent triggered! isKeyDown: $isKeyDown, isSpace: $isSpace, isP: $isP, isR: $isR, isGameOver: $isGameOver, isPaused: $isPaused");

    if (isKeyDown) {
      if (isSpace) {
        if (isGameOver) {
          restartGame();
        } else if (!isPaused) {
          print("Calling playerJump() from onKeyEvent (Space)...");
          playerJump();
        }
        return KeyEventResult.handled;
      }
      if (isP) {
        if (isPaused && !isGameOver) {
          resumeGame();
        } else if (!isPaused && !isGameOver) {
          pauseGame();
        }
        return KeyEventResult.handled;
      }
      if (isR && isGameOver) {
        restartGame();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
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
}

// -------- Oyun Ekranı Widget'ı --------

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  RunnerGame? _game; // Oyun nesnesi null olabilir
  bool _isLoading = true; // Başlangıçta yükleniyor durumu
  bool _showGameOverOverlay = false; // Oyun bitti overlay'i
  bool _showPauseOverlay = false; // Duraklatma overlay'i
  int _currentScore = 0;
  int _currentHighScore = 0;
  int _currentLives = 3;

  @override
  void initState() {
    super.initState();
    // initState içinde Provider.of kullanmak genellikle önerilmez,
    // ancak burada oyun nesnesini başlatmak için gerekli olabilir.
    // Alternatif olarak `didChangeDependencies` veya `Future.delayed` kullanılabilir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  void _initializeGame() {
    // Provider'dan gerekli verileri al
    final gameState = Provider.of<GameState>(context, listen: false);
    final selectedCharacter = gameState.currentCharacter;
    final currentTheme = gameState.currentTheme;
    final currentLevel = gameState.currentLevel; // GameState'den seviyeyi al
    final highScore = gameState.highScore; // Yüksek skoru al

    // Seviye null ise bir varsayılan oluştur (güvenlik önlemi)
    // final levelToUse = currentLevel ?? Level.defaultLevel(); // GameState içinde defaultLevel metodu eklenmeli
    // GameState'deki _initLevels'da varsayılan seviye zaten ekleniyor olmalı
    final levelToUse =
        currentLevel; // Direkt currentLevel kullanılıyor, null ise RunnerGame içinde kontrol edilir

    print(
        "GameScreen._initializeGame: Karakter: ${selectedCharacter?.id}, Tema: ${currentTheme.name}, Seviye: ${levelToUse?.name ?? 'Varsayılan'}, Yüksek Skor: $highScore");

    // Oyun nesnesini oluştur
    _game = RunnerGame(
      selectedCharacter: selectedCharacter,
      currentTheme: currentTheme,
      currentLevel:
          levelToUse, // Null olabilir, RunnerGame constructor'da null kontrolü var
      highScore: highScore,
    );

    // Callback'leri ayarla (oyun nesnesi oluşturulduktan sonra)
    _game!.setOnGameOverCallback(_handleGameOver);
    _game!.setOnLifeLostCallback(_handleLifeLost);
    _currentLives = _game!.lives; // Başlangıç canlarını al
    _currentHighScore = highScore; // Yüksek skoru başlat

    setState(() {
      _isLoading = false; // Yükleme bitti
    });

    print("GameScreen: Oyun başlatıldı!");
  }

  // Can kaybedildiğinde UI'ı güncelle
  void _handleLifeLost() {
    if (mounted && _game != null) {
      // Widget hala ağaçtaysa
      setState(() {
        _currentLives = _game!.lives;
      });
      print("GameScreen: Can kaybedildi UI güncellendi. Kalan: $_currentLives");
    }
  }

  // Oyun bittiğinde UI'ı güncelle
  void _handleGameOver() {
    if (mounted && _game != null && context.mounted) {
      // context.mounted check
      final gameState = Provider.of<GameState>(context,
          listen: false); // BuildContext'i kullan
      setState(() {
        _showGameOverOverlay = true;
        _currentScore = _game!.score; // Son skoru al
        _currentHighScore =
            gameState.highScore; // Güncel yüksek skoru Provider'dan al
      });
      print("GameScreen: Oyun bitti UI güncellendi.");
    }
  }

  @override
  Widget build(BuildContext context) {
    // print("GameScreen build çağrıldı. isLoading: $_isLoading, showGameOver: $_showGameOverOverlay, showPause: $_showPauseOverlay");

    return Scaffold(
      body: Stack(
        children: [
          // Oyun görünümü (eğer yüklenmişse)
          if (_game != null) GameWidget(game: _game!), // Null değilse göster

          // Yükleniyor göstergesi
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Oyun Yükleniyor...",
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),

          // Oyun Duraklatma Butonu (sağ üst köşe)
          if (!_isLoading &&
              !_showGameOverOverlay &&
              !_showPauseOverlay &&
              _game != null)
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.pause_circle_filled,
                    color: Colors.white, size: 40),
                onPressed: () {
                  _game?.pauseGame();
                  setState(() {
                    _showPauseOverlay = true;
                  });
                  print("GameScreen: Pause butonuna basıldı.");
                },
              ),
            ),

          // Duraklatma Menüsü Overlay'i
          if (_showPauseOverlay)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "OYUN DURDURULDU",
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Devam Et",
                          style: TextStyle(fontSize: 20)),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15)),
                      onPressed: () {
                        _game?.resumeGame();
                        setState(() {
                          _showPauseOverlay = false;
                        });
                        print("GameScreen: Devam et butonuna basıldı.");
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.home),
                      label: const Text("Ana Menü",
                          style: TextStyle(fontSize: 20)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15)),
                      onPressed: () {
                        // Oyun müziğini durdur ve ana menüye dön
                        _game?.audioService
                            .stopMusic(); // _audioService -> audioService
                        Navigator.of(context).pop(); // GameScreen'i kapat
                        print("GameScreen: Ana menü butonuna basıldı.");
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Oyun Bitti Overlay'i
          if (_showGameOverOverlay)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "OYUN BİTTİ!",
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      "Skor: $_currentScore",
                      style: const TextStyle(fontSize: 28, color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "En Yüksek Skor: $_currentHighScore",
                      style: const TextStyle(
                          fontSize: 22, color: Colors.yellowAccent),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Tekrar Oyna",
                          style: TextStyle(fontSize: 20)),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15)),
                      onPressed: () {
                        if (_game != null) {
                          _game!.restartGame();
                          setState(() {
                            _showGameOverOverlay = false;
                            _currentLives = _game!.lives; // Canları sıfırla
                            _currentScore = 0; // Skoru sıfırla
                          });
                          print("GameScreen: Tekrar oyna butonuna basıldı.");
                        } else {
                          print(
                              "GameScreen: Hata - Tekrar oyna denendi ama _game null.");
                          // Hata durumu veya yeniden başlatma mantığı
                          _initializeGame(); // Oyunu tekrar başlatmayı dene
                          setState(() {
                            _showGameOverOverlay = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.home),
                      label: const Text("Ana Menü",
                          style: TextStyle(fontSize: 20)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15)),
                      onPressed: () {
                        // Oyun müziğini durdur ve ana menüye dön
                        _game?.audioService
                            .stopMusic(); // _audioService -> audioService
                        Navigator.of(context).pop(); // GameScreen'i kapat
                        print(
                            "GameScreen: Ana menü butonuna basıldı (Oyun Bitti).");
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print("GameScreen dispose ediliyor.");
    _game?.audioService
        .dispose(); // _audioService -> audioService // dispose metodu çağrılabilir
    _game?.removeFromParent();
    _game = null;
    super.dispose();
  }
}
