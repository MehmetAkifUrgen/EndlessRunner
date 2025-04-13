import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _soundPlayer = AudioPlayer();

  final Map<SoundEffect, String> _soundPaths = {
    SoundEffect.jump: 'audio/jump.mp3',
    SoundEffect.doubleJump: 'audio/double_jump.mp3',
    SoundEffect.land: 'audio/land.mp3',
    SoundEffect.collect: 'audio/collect.mp3',
    SoundEffect.hit: 'audio/hit.mp3',
    SoundEffect.gameOver: 'audio/game_over.mp3',
    SoundEffect.powerUp: 'audio/power_up.mp3',
    SoundEffect.dash: 'audio/dash.mp3',
    SoundEffect.slide: 'audio/slide.mp3',
    SoundEffect.levelUp: 'audio/level_up.mp3',
  };

  final Map<MusicTrack, String> _musicPaths = {
    MusicTrack.menu: 'audio/menu_music.mp3',
    MusicTrack.game: 'audio/game_music.mp3',
    MusicTrack.gameOver: 'audio/game_over_music.mp3',
  };

  MusicTrack? _currentMusic;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isMusicEnabled = prefs.getBool('isMusicEnabled') ?? true;
    _isSoundEnabled = prefs.getBool('isSoundEnabled') ?? true;

    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _soundPlayer.setReleaseMode(ReleaseMode.release);
  }

  // Geriye dönük uyumluluk için initialize metodu
  Future<void> initialize() async {
    await init();
  }

  Future<void> playMusic(MusicTrack track) async {
    if (_isMusicEnabled) {
      try {
        final path = _musicPaths[track];
        if (path != null) {
          await _musicPlayer.stop();
          await _musicPlayer.play(AssetSource(path));
          _currentMusic = track;
        }
      } catch (e) {
        print('Müzik çalınamadı: $e');
      }
    }
  }

  Future<void> playSfx(SoundEffect effect) async {
    if (_isSoundEnabled) {
      try {
        final path = _soundPaths[effect];
        if (path != null) {
          await _soundPlayer.play(AssetSource(path));
        }
      } catch (e) {
        print('Ses efekti çalınamadı: $e');
      }
    }
  }

  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }

  Future<void> pauseMusic() async {
    await _musicPlayer.pause();
  }

  Future<void> resumeMusic() async {
    if (_isMusicEnabled) {
      await _musicPlayer.resume();
    }
  }

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSoundEnabled => _isSoundEnabled;

  Future<void> toggleMusic() async {
    _isMusicEnabled = !_isMusicEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMusicEnabled', _isMusicEnabled);

    if (_isMusicEnabled) {
      if (_currentMusic != null) {
        await playMusic(_currentMusic!);
      }
    } else {
      await _musicPlayer.pause();
    }
  }

  Future<void> toggleSound() async {
    _isSoundEnabled = !_isSoundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSoundEnabled', _isSoundEnabled);
  }

  void dispose() {
    _musicPlayer.dispose();
    _soundPlayer.dispose();
  }
}
