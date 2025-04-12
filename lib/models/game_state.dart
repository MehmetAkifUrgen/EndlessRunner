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

  GameState() {
    _initThemes();
    _loadHighScore();
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

  // Yüksek skoru yükle
  Future<void> _loadHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _highScore = prefs.getInt('highScore') ?? 0;
      _coins = prefs.getInt('coins') ?? 0;
      _currentThemeId = prefs.getString('currentTheme') ?? 'default';
      
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
      print("Loaded high score: $_highScore and theme: $_currentThemeId");
      notifyListeners();
    } catch (e) {
      print("Error loading high score: $e");
    }
  }

  // Yüksek skoru kaydet
  Future<void> _saveHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', _highScore);
      await prefs.setInt('coins', _coins);
      print("Saved high score: $_highScore");
    } catch (e) {
      print("Error saving high score: $e");
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
      _saveHighScore();
      print("Game ended with new high score: $_highScore");
    }

    notifyListeners();
  }

  // Skoru artır
  void addScore(int points) {
    _score += points;
    if (_score > _highScore) {
      _highScore = _score;
      _saveHighScore();
      print("Updated high score: $_highScore");
    }
    notifyListeners();
  }

  // Altın topla
  void collectCoin() {
    _coins++;
    _saveHighScore();
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

  void resetAdCounter() {
    _gamesSinceLastAd = 0;
    notifyListeners();
  }
  
  // Tema yönetimi metotları
  Future<bool> unlockTheme(String themeId) async {
    // Tema var mı ve kilitli mi kontrol et
    int themeIndex = _availableThemes.indexWhere((t) => t.id == themeId);
    if (themeIndex == -1 || _availableThemes[themeIndex].isUnlocked) {
      return false;
    }
    
    // Yeterli para var mı kontrol et
    int price = _availableThemes[themeIndex].price;
    if (_coins < price) {
      return false;
    }
    
    // Parayı harca ve temayı aç
    _coins -= price;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_$themeId', true);
    await prefs.setInt('coins', _coins);
    
    // Tema nesnesini güncelle
    _availableThemes[themeIndex] = GameTheme(
      id: _availableThemes[themeIndex].id,
      name: _availableThemes[themeIndex].name,
      price: _availableThemes[themeIndex].price,
      isUnlocked: true,
      primaryColor: _availableThemes[themeIndex].primaryColor,
      secondaryColor: _availableThemes[themeIndex].secondaryColor,
      backgroundGradient: _availableThemes[themeIndex].backgroundGradient,
      obstacleColor: _availableThemes[themeIndex].obstacleColor,
      groundColor: _availableThemes[themeIndex].groundColor,
      playerColor: _availableThemes[themeIndex].playerColor,
    );
    
    notifyListeners();
    return true;
  }
  
  Future<void> setCurrentTheme(String themeId) async {
    // Açık bir tema mı kontrol et
    int themeIndex = _availableThemes.indexWhere((t) => t.id == themeId);
    if (themeIndex == -1 || !_availableThemes[themeIndex].isUnlocked) {
      return;
    }
    
    _currentThemeId = themeId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentTheme', themeId);
    notifyListeners();
  }
  
  GameTheme get currentTheme {
    return _availableThemes.firstWhere(
      (theme) => theme.id == _currentThemeId,
      orElse: () => _availableThemes.first,
    );
  }
}
