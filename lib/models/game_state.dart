import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GravityDirection { down, left, right, up }

class GameTheme {
  final String id;
  final String name;
  final int price;
  final bool isUnlocked;
  final Color primaryColor;
  final Color secondaryColor;
  final List<Color> backgroundGradient;
  final Color obstacleColor;
  final Color groundColor;
  final Color playerColor;

  GameTheme({
    required this.id,
    required this.name,
    required this.price,
    this.isUnlocked = false,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundGradient,
    required this.obstacleColor,
    required this.groundColor,
    required this.playerColor,
  });
}

// Seviye bilgisini tutacak sınıf
class Level {
  final int id;
  final String name;
  final String description;
  final int requiredXP;
  final double speedMultiplier;
  final double scoreMultiplier;
  final int obstacleFrequency;
  final bool isUnlocked;

  Level({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredXP,
    required this.speedMultiplier,
    required this.scoreMultiplier,
    required this.obstacleFrequency,
    this.isUnlocked = false,
  });
}

class GameState with ChangeNotifier {
  bool _isPlaying = false;
  int _score = 0;
  int _highScore = 0;
  int _coins = 0;
  int _lives = 3;
  int _gamesSinceLastAd = 0;
  bool _showRewardAd = false;
  GravityDirection _gravityDirection = GravityDirection.down;

  // Tema sistemi için eklemeler
  String _currentThemeId = 'default';
  List<GameTheme> _availableThemes = [];

  // Seviye sistemi için eklemeler
  int _playerLevel = 1;
  int _currentXP = 0;
  int _currentLevelId = 1;
  List<Level> _availableLevels = [];

  // Getters
  bool get isPlaying => _isPlaying;
  int get score => _score;
  int get highScore => _highScore;
  int get coins => _coins;
  int get lives => _lives;
  int get gamesSinceLastAd => _gamesSinceLastAd;
  bool get showRewardAd => _showRewardAd;
  GravityDirection get gravityDirection => _gravityDirection;
  String get currentThemeId => _currentThemeId;
  List<GameTheme> get availableThemes => _availableThemes;
  int get playerLevel => _playerLevel;
  int get currentXP => _currentXP;
  int get currentLevelId => _currentLevelId;
  List<Level> get availableLevels => _availableLevels;

  // Aktif seviyeyi döndür
  Level get currentLevel => _availableLevels.firstWhere(
        (level) => level.id == _currentLevelId,
        orElse: () => _availableLevels.first,
      );

  // Sonraki seviye için gereken XP
  int get xpForNextLevel {
    if (_playerLevel >= _availableLevels.length) {
      return _availableLevels.last.requiredXP;
    }
    return _availableLevels[_playerLevel].requiredXP;
  }

  // XP yüzdesi (seviye ilerleme çubuğu için)
  double get xpPercentage => _currentXP / xpForNextLevel;

  // Mevcut tema nesnesini döndür
  GameTheme get currentTheme {
    return _availableThemes.firstWhere(
      (theme) => theme.id == _currentThemeId,
      orElse: () => _availableThemes.first,
    );
  }

  GameState() {
    _initThemes();
    _initLevels();
    _loadSavedData();
  }

  // Temaları başlat
  void _initThemes() {
    _availableThemes = [
      GameTheme(
        id: 'default',
        name: 'Klasik',
        price: 0,
        isUnlocked: true,
        primaryColor: Colors.blue,
        secondaryColor: Colors.red,
        backgroundGradient: [Colors.lightBlue.shade300, Colors.blue.shade600],
        obstacleColor: Colors.redAccent,
        groundColor: Colors.green.shade800,
        playerColor: Colors.red,
      ),
      GameTheme(
        id: 'night',
        name: 'Gece Modu',
        price: 1000,
        primaryColor: Colors.deepPurple,
        secondaryColor: Colors.indigo,
        backgroundGradient: [Colors.indigo.shade900, Colors.black],
        obstacleColor: Colors.purple.shade300,
        groundColor: Colors.deepPurple.shade900,
        playerColor: Colors.deepPurple.shade200,
      ),
      GameTheme(
        id: 'jungle',
        name: 'Orman',
        price: 2000,
        primaryColor: Colors.green,
        secondaryColor: Colors.lightGreen,
        backgroundGradient: [Colors.green.shade300, Colors.green.shade900],
        obstacleColor: Colors.brown.shade700,
        groundColor: Colors.lightGreen.shade900,
        playerColor: Colors.lightGreen,
      ),
      GameTheme(
        id: 'lava',
        name: 'Lav Dünyası',
        price: 3000,
        primaryColor: Colors.orange,
        secondaryColor: Colors.red,
        backgroundGradient: [Colors.deepOrange, Colors.red.shade900],
        obstacleColor: Colors.grey.shade800,
        groundColor: Colors.orange.shade900,
        playerColor: Colors.amber,
      ),
      GameTheme(
        id: 'winter',
        name: 'Kış Manzarası',
        price: 2500,
        primaryColor: Colors.lightBlue,
        secondaryColor: Colors.white,
        backgroundGradient: [Colors.white, Colors.lightBlue.shade100],
        obstacleColor: Colors.blue.shade200,
        groundColor: Colors.white,
        playerColor: Colors.blue.shade800,
      ),
    ];
  }

  // Seviyeleri başlat
  void _initLevels() {
    _availableLevels = [
      Level(
        id: 1,
        name: "Acemi Koşucu",
        description: "Yarışa yeni başlayanlar için.",
        requiredXP: 0,
        speedMultiplier: 1.0,
        scoreMultiplier: 1.0,
        obstacleFrequency: 2,
        isUnlocked: true,
      ),
      Level(
        id: 2,
        name: "Amatör Atlet",
        description: "Engellere alışıyorsun, hızını artır!",
        requiredXP: 500,
        speedMultiplier: 1.2,
        scoreMultiplier: 1.2,
        obstacleFrequency: 2,
      ),
      Level(
        id: 3,
        name: "Hızlı Koşucu",
        description: "Daha hızlı ve daha yüksek puanlar!",
        requiredXP: 1500,
        speedMultiplier: 1.4,
        scoreMultiplier: 1.5,
        obstacleFrequency: 1,
      ),
      Level(
        id: 4,
        name: "Profesyonel Atlet",
        description: "Artık profesyonel bir koşucusun!",
        requiredXP: 3000,
        speedMultiplier: 1.6,
        scoreMultiplier: 1.8,
        obstacleFrequency: 1,
      ),
      Level(
        id: 5,
        name: "Engel Ustası",
        description: "Süper koşucu! Daha yüksek zorluk ve ödüller.",
        requiredXP: 5000,
        speedMultiplier: 1.8,
        scoreMultiplier: 2.0,
        obstacleFrequency: 1,
      ),
      Level(
        id: 6,
        name: "Efsane Koşucu",
        description: "Maksimum hız ve zorluk seviyesi!",
        requiredXP: 10000,
        speedMultiplier: 2.0,
        scoreMultiplier: 2.5,
        obstacleFrequency: 1,
      ),
    ];
  }

  // Yüksek skoru ve diğer verileri yükle
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _highScore = prefs.getInt('highScore') ?? 0;
      _coins = prefs.getInt('coins') ?? 0;
      _currentThemeId = prefs.getString('currentTheme') ?? 'default';
      _playerLevel = prefs.getInt('playerLevel') ?? 1;
      _currentXP = prefs.getInt('currentXP') ?? 0;
      _currentLevelId = prefs.getInt('currentLevelId') ?? 1;

      // Açılmış temaları yükle
      for (int i = 0; i < _availableThemes.length; i++) {
        String themeId = _availableThemes[i].id;
        if (prefs.getBool('theme_$themeId') == true) {
          _availableThemes[i] = GameTheme(
            id: _availableThemes[i].id,
            name: _availableThemes[i].name,
            price: _availableThemes[i].price,
            isUnlocked: true,
            primaryColor: _availableThemes[i].primaryColor,
            secondaryColor: _availableThemes[i].secondaryColor,
            backgroundGradient: _availableThemes[i].backgroundGradient,
            obstacleColor: _availableThemes[i].obstacleColor,
            groundColor: _availableThemes[i].groundColor,
            playerColor: _availableThemes[i].playerColor,
          );
        }
      }

      // Açılmış seviyeleri yükle
      for (int i = 0; i < _availableLevels.length; i++) {
        int levelId = _availableLevels[i].id;
        if (prefs.getBool('level_$levelId') == true) {
          _availableLevels[i] = Level(
            id: _availableLevels[i].id,
            name: _availableLevels[i].name,
            description: _availableLevels[i].description,
            requiredXP: _availableLevels[i].requiredXP,
            speedMultiplier: _availableLevels[i].speedMultiplier,
            scoreMultiplier: _availableLevels[i].scoreMultiplier,
            obstacleFrequency: _availableLevels[i].obstacleFrequency,
            isUnlocked: true,
          );
        }
      }

      print(
          "Loaded high score: $_highScore, theme: $_currentThemeId, level: $_playerLevel, XP: $_currentXP");
      notifyListeners();
    } catch (e) {
      print("Error loading saved data: $e");
    }
  }

  // Verileri kaydet
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', _highScore);
      await prefs.setInt('coins', _coins);
      await prefs.setString('currentTheme', _currentThemeId);
      await prefs.setInt('playerLevel', _playerLevel);
      await prefs.setInt('currentXP', _currentXP);
      await prefs.setInt('currentLevelId', _currentLevelId);
      print("Saved data - high score: $_highScore, level: $_playerLevel");
    } catch (e) {
      print("Error saving data: $e");
    }
  }

  // Oyunu başlat
  void startGame() {
    _isPlaying = true;
    _score = 0;
    _lives = 3;
    _gravityDirection = GravityDirection.down;
    notifyListeners();
  }

  // Oyunu durdur
  void stopGame() {
    _isPlaying = false;
    _gamesSinceLastAd++;

    if (_score > _highScore) {
      _highScore = _score;
      _saveData();
      print("Game ended with new high score: $_highScore");
    }

    notifyListeners();
  }

  // Skoru artır
  void addScore(int points) {
    // Aktif seviyenin skorunu uygula
    final adjustedPoints = (points * currentLevel.scoreMultiplier).floor();
    _score += adjustedPoints;

    // XP'yi de artır (skorun yarısı XP olarak eklenir)
    addXP(adjustedPoints ~/ 2);

    if (_score > _highScore) {
      _highScore = _score;
      _saveData();
      print("Updated high score: $_highScore");
    }
    notifyListeners();
  }

  // XP ekle ve seviye kontrol et
  void addXP(int xp) {
    _currentXP += xp;
    _checkLevelUp();
    notifyListeners();
  }

  // Seviye atlama kontrolü
  void _checkLevelUp() {
    if (_playerLevel >= _availableLevels.length) {
      return; // Son seviyedeyse daha fazla ilerleyemez
    }

    final nextLevel = _availableLevels[_playerLevel];
    if (_currentXP >= nextLevel.requiredXP) {
      // Seviye atla
      _playerLevel++;
      // Seviyeyi açık olarak işaretle
      final updatedLevel = Level(
        id: nextLevel.id,
        name: nextLevel.name,
        description: nextLevel.description,
        requiredXP: nextLevel.requiredXP,
        speedMultiplier: nextLevel.speedMultiplier,
        scoreMultiplier: nextLevel.scoreMultiplier,
        obstacleFrequency: nextLevel.obstacleFrequency,
        isUnlocked: true,
      );

      // Listeyi güncelle
      int index =
          _availableLevels.indexWhere((level) => level.id == nextLevel.id);
      if (index != -1) {
        _availableLevels[index] = updatedLevel;
      }

      // Kaydet
      _saveUnlockedLevel(nextLevel.id);
      print("Level up! New level: $_playerLevel");
    }
  }

  // Açılan seviyeyi kaydet
  Future<void> _saveUnlockedLevel(int levelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('level_$levelId', true);
      print("Saved unlocked level: $levelId");
    } catch (e) {
      print("Error saving unlocked level: $e");
    }
  }

  // Kullanıcının seviyesini belirle
  void setCurrentLevel(int levelId) {
    // Açık seviyelerden mi kontrol et
    final Level? level = _availableLevels.firstWhere(
      (level) => level.id == levelId && level.isUnlocked,
      orElse: () => _availableLevels.first,
    );

    if (level != null) {
      _currentLevelId = levelId;
      _saveData();
      notifyListeners();
      print("Set current level to: $levelId");
    } else {
      print("Cannot set level: Level $levelId is not unlocked");
    }
  }

  // Altın topla
  void collectCoin() {
    _coins++;
    _saveData();
    notifyListeners();
  }

  // Can kaybı
  bool loseLife() {
    _lives--;
    notifyListeners();
    return _lives <= 0;
  }

  // Ekstra can ekleme
  void addLife() {
    _lives++;
    notifyListeners();
  }

  // Yerçekimi yönünü değiştir
  void changeGravity(GravityDirection direction) {
    _gravityDirection = direction;
    notifyListeners();
  }

  // Reklam yönetimi
  void setShowRewardAd(bool show) {
    _showRewardAd = show;
    notifyListeners();
  }

  // Tema satın alma
  bool buyTheme(String themeId) {
    // İlgili temayı bul
    final theme = _availableThemes.firstWhere(
      (theme) => theme.id == themeId,
      orElse: () => GameTheme(
        id: '',
        name: '',
        price: 0,
        primaryColor: Colors.white,
        secondaryColor: Colors.white,
        backgroundGradient: [Colors.white, Colors.white],
        obstacleColor: Colors.white,
        groundColor: Colors.white,
        playerColor: Colors.white,
      ),
    );

    // Tema bulunamadı veya zaten açık
    if (theme.id.isEmpty || theme.isUnlocked) return false;

    // Yeterli para var mı kontrol et
    if (_coins >= theme.price) {
      // Parayı düş
      _coins -= theme.price;

      // Tema listesini güncelle
      int index = _availableThemes.indexWhere((t) => t.id == themeId);
      if (index != -1) {
        _availableThemes[index] = GameTheme(
          id: theme.id,
          name: theme.name,
          price: theme.price,
          isUnlocked: true,
          primaryColor: theme.primaryColor,
          secondaryColor: theme.secondaryColor,
          backgroundGradient: theme.backgroundGradient,
          obstacleColor: theme.obstacleColor,
          groundColor: theme.groundColor,
          playerColor: theme.playerColor,
        );
      }

      // Tema açılışını kaydet
      _saveUnlockedTheme(themeId);
      notifyListeners();
      return true;
    }

    return false;
  }

  // Açılan temayı kaydet
  Future<void> _saveUnlockedTheme(String themeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('theme_$themeId', true);
      await prefs.setInt('coins', _coins);
      print("Saved unlocked theme: $themeId");
    } catch (e) {
      print("Error saving unlocked theme: $e");
    }
  }

  // Mevcut temayı değiştir
  void setCurrentTheme(String themeId) {
    // Temanın açık olup olmadığını kontrol et
    final themeExists = _availableThemes.any(
      (theme) => theme.id == themeId && theme.isUnlocked,
    );

    if (themeExists) {
      _currentThemeId = themeId;
      _saveCurrentTheme();
      notifyListeners();
      print("Changed current theme to: $themeId");
    }
  }

  // Mevcut temayı kaydet
  Future<void> _saveCurrentTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentTheme', _currentThemeId);
      print("Saved current theme: $_currentThemeId");
    } catch (e) {
      print("Error saving current theme: $e");
    }
  }
}
