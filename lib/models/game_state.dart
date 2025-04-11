import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GravityDirection { down, left, right, up }

class GameState with ChangeNotifier {
  bool _isPlaying = false;
  int _score = 0;
  int _highScore = 0;
  int _coins = 0;
  int _lives = 3;
  int _gamesSinceLastAd = 0;
  bool _showRewardAd = false;
  GravityDirection _gravityDirection = GravityDirection.down;

  // Getters
  bool get isPlaying => _isPlaying;
  int get score => _score;
  int get highScore => _highScore;
  int get coins => _coins;
  int get lives => _lives;
  int get gamesSinceLastAd => _gamesSinceLastAd;
  bool get showRewardAd => _showRewardAd;
  GravityDirection get gravityDirection => _gravityDirection;

  GameState() {
    _loadHighScore();
  }

  // Yüksek skoru yükle
  Future<void> _loadHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _highScore = prefs.getInt('highScore') ?? 0;
      _coins = prefs.getInt('coins') ?? 0;
      print("Loaded high score: $_highScore");
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
}
