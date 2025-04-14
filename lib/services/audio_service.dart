import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

// Oyun içinde kullanılacak ses efektleri
enum SoundEffect {
  jump,
  doubleJump,
  land,
  collect,
  hit,
  gameOver,
  powerUp,
  dash,
  slide,
  levelUp
}

// Oyun içinde kullanılacak müzik parçaları
enum MusicTrack { menu, game, gameOver }

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal();

  bool _isMusicEnabled = true;
  bool _isSoundEnabled = true;
  double _soundVolume = 0.5;
  double _musicVolume = 0.3;

  AudioPlayer? _musicPlayer;
  AudioPlayer? _soundPlayer;
  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _isAndroid = false;

  // Ses efektleri için yollar - Android için uyumlu sesler
  final Map<SoundEffect, String> _soundEffects = {
    SoundEffect.jump: 'jump',
    SoundEffect.doubleJump: 'jump',
    SoundEffect.land: 'hit',
    SoundEffect.collect: 'collect',
    SoundEffect.hit: 'hit',
    SoundEffect.gameOver: 'gameover',
    SoundEffect.powerUp: 'powerup',
    SoundEffect.dash: 'dash',
    SoundEffect.slide: 'slide',
    SoundEffect.levelUp: 'levelup',
  };

  // Android için ses efektleri
  // Her ses için farklı bir kaynak kullanıyoruz
  final Map<String, String> _androidSounds = {
    'jump': 'https://www.fesliyanstudios.com/play-mp3/6',
    'hit': 'https://www.fesliyanstudios.com/play-mp3/5',
    'collect': 'https://www.fesliyanstudios.com/play-mp3/11',
    'gameover': 'https://www.fesliyanstudios.com/play-mp3/15',
    'powerup': 'https://www.fesliyanstudios.com/play-mp3/10',
    'dash': 'https://www.fesliyanstudios.com/play-mp3/7',
    'slide': 'https://www.fesliyanstudios.com/play-mp3/8',
    'levelup': 'https://www.fesliyanstudios.com/play-mp3/3',
  };

  // Android için müzik
  final Map<MusicTrack, String> _androidMusic = {
    MusicTrack.menu: 'https://www.fesliyanstudios.com/play-mp3/4',
    MusicTrack.game: 'https://www.fesliyanstudios.com/play-mp3/9',
    MusicTrack.gameOver: 'https://www.fesliyanstudios.com/play-mp3/14',
  };

  MusicTrack? _currentMusic;

  Future<void> init() async {
    if (_isInitialized || _isDisposed) return;

    // Platform kontrolü yap
    try {
      _isAndroid = !kIsWeb && Platform.isAndroid;
    } catch (e) {
      _isAndroid = false;
    }

    // Eğer Android değilse, oyun ses efektsiz çalışacak
    if (!_isAndroid) {
      print('Ses desteği sadece Android platformunda aktiftir');
      return;
    }

    try {
      _musicPlayer = AudioPlayer();
      _soundPlayer = AudioPlayer();

      final prefs = await SharedPreferences.getInstance();
      _isMusicEnabled = prefs.getBool('isMusicEnabled') ?? true;
      _isSoundEnabled = prefs.getBool('isSoundEnabled') ?? true;

      await _musicPlayer?.setVolume(_musicVolume);
      await _soundPlayer?.setVolume(_soundVolume);
      await _musicPlayer?.setReleaseMode(ReleaseMode.loop);
      await _soundPlayer?.setReleaseMode(ReleaseMode.release);
      _isInitialized = true;
    } catch (e) {
      print('Ses başlatılırken hata: $e');
    }
  }

  // Geriye dönük uyumluluk için initialize metodu
  Future<void> initialize() async {
    await init();
  }

  Future<void> playMusic(MusicTrack track) async {
    if (_isDisposed || !_isAndroid) return;
    if (!_isInitialized) await init();
    if (_isMusicEnabled && _musicPlayer != null) {
      try {
        await _musicPlayer?.stop();
        final url = _androidMusic[track] ?? _androidMusic[MusicTrack.menu]!;
        Source source = UrlSource(url);
        await _musicPlayer?.play(source);
        _currentMusic = track;
      } catch (e) {
        print('Müzik çalınamadı: $e');
        // Eğer player bozulduysa, yeniden oluştur
        await _recreateMusicPlayer();
      }
    }
  }

  Future<void> _recreateMusicPlayer() async {
    if (!_isAndroid) return;
    try {
      await _musicPlayer?.dispose();
      _musicPlayer = AudioPlayer();
      await _musicPlayer?.setVolume(_musicVolume);
      await _musicPlayer?.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      print('Müzik oynatıcı yenilenemedi: $e');
    }
  }

  Future<void> _recreateSoundPlayer() async {
    if (!_isAndroid) return;
    try {
      await _soundPlayer?.dispose();
      _soundPlayer = AudioPlayer();
      await _soundPlayer?.setVolume(_soundVolume);
      await _soundPlayer?.setReleaseMode(ReleaseMode.release);
    } catch (e) {
      print('Ses oynatıcı yenilenemedi: $e');
    }
  }

  Future<void> playSfx(SoundEffect effect) async {
    if (_isDisposed || !_isAndroid) return;
    if (!_isInitialized) await init();
    if (_isSoundEnabled && _soundPlayer != null) {
      try {
        final effectName = _soundEffects[effect];
        if (effectName != null) {
          final url = _androidSounds[effectName] ?? _androidSounds['hit']!;
          Source source = UrlSource(url);
          await _soundPlayer?.play(source);
        }
      } catch (e) {
        print('Ses efekti çalınamadı: $e');
        // Eğer player bozulduysa, yeniden oluştur
        await _recreateSoundPlayer();
      }
    }
  }

  Future<void> stopMusic() async {
    if (_isDisposed || !_isInitialized || _musicPlayer == null || !_isAndroid)
      return;
    try {
      await _musicPlayer?.stop();
    } catch (e) {
      print('Müzik durdurulamadı: $e');
      await _recreateMusicPlayer();
    }
  }

  Future<void> pauseMusic() async {
    if (_isDisposed || !_isInitialized || _musicPlayer == null || !_isAndroid)
      return;
    try {
      await _musicPlayer?.pause();
    } catch (e) {
      print('Müzik duraklatılamadı: $e');
    }
  }

  Future<void> resumeMusic() async {
    if (_isDisposed || !_isAndroid) return;
    if (!_isInitialized) await init();
    if (_isMusicEnabled && _musicPlayer != null) {
      try {
        await _musicPlayer?.resume();
      } catch (e) {
        print('Müzik devam ettirilemedi: $e');
        // Eğer devam etme başarısız olursa, müziği yeniden başlat
        if (_currentMusic != null) {
          await playMusic(_currentMusic!);
        }
      }
    }
  }

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSoundEnabled => _isSoundEnabled;

  Future<void> toggleMusic() async {
    _isMusicEnabled = !_isMusicEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMusicEnabled', _isMusicEnabled);

    if (_isDisposed || !_isAndroid) return;

    if (_isMusicEnabled) {
      if (_currentMusic != null && _musicPlayer != null) {
        await playMusic(_currentMusic!);
      }
    } else {
      if (_isInitialized && _musicPlayer != null) {
        try {
          await _musicPlayer?.pause();
        } catch (e) {
          print('Müzik kapatılamadı: $e');
        }
      }
    }
  }

  Future<void> toggleSound() async {
    _isSoundEnabled = !_isSoundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSoundEnabled', _isSoundEnabled);
  }

  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _isInitialized = false;

    try {
      _musicPlayer?.dispose();
      _soundPlayer?.dispose();
    } catch (e) {
      print('Ses servisi kapatılırken hata: $e');
    } finally {
      _musicPlayer = null;
      _soundPlayer = null;
    }
  }
}
