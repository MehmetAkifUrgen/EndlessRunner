import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import '../../services/ad_service.dart'; // Güncellendi
import 'game_screen.dart';
import 'theme_shop_screen.dart';
//import '../../services/audio_service.dart'; // Güncellendi
import 'character_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Ses servisi
  //final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    //_initAudio();
  }

  // Ses başlatma
  /*Future<void> _initAudio() async {
    //await _audioService.initialize();
    //_audioService.playMusic(MusicTrack.menu);
  }*/

  @override
  void dispose() {
    //_audioService.dispose();
    super.dispose();
  }

  // Buton tıklama sesi
  void _playButtonSound() {
    //_audioService.playSfx(SoundEffect.collect);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gameState.currentTheme.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: isLandscape
              ? _buildLandscapeLayout(context, gameState)
              : _buildPortraitLayout(context, gameState),
        ),
      ),
    );
  }

  // Yatay ekran düzeni
  Widget _buildLandscapeLayout(BuildContext context, GameState gameState) {
    return Row(
      children: [
        // Sol kısım: Başlık ve yüksek skor
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ENDLESS RUNNER',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black45,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'High Score: ${gameState.highScore}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 5,
                        color: Colors.black45,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${gameState.coins}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Seviye bilgisi göster
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Level ${gameState.playerLevel}: ${gameState.currentLevel.name}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // XP ilerleme çubuğu
                      SizedBox(
                        width: 150,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: gameState.xpPercentage,
                            backgroundColor: Colors.grey[700],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.amber,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${gameState.currentXP} / ${gameState.xpForNextLevel} XP",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Sağ kısım: Menü butonları
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Oyna butonu
                MenuButton(
                  text: 'PLAY',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const GameScreen(),
                      ),
                    );
                  },
                  width: double.infinity,
                  height: 50,
                  color: gameState.currentTheme.primaryColor,
                  onSoundCallback: _playButtonSound,
                ),
                const SizedBox(height: 10),

                // Seviye Seç butonu
                MenuButton(
                  text: 'LEVELS',
                  onPressed: () {
                    _playButtonSound();
                    _showLevelsDialog(context, gameState);
                  },
                  width: double.infinity,
                  height: 50,
                  color: Colors.orange,
                  onSoundCallback: _playButtonSound,
                ),
                const SizedBox(height: 10),

                // Tema Mağazası butonu
                MenuButton(
                  text: 'THEME SHOP',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ThemeShopScreen(),
                      ),
                    );
                  },
                  width: double.infinity,
                  height: 50,
                  color: Colors.purple,
                  onSoundCallback: _playButtonSound,
                ),
                const SizedBox(height: 10),

                // Karakter butonu
                MenuButton(
                  text: 'CHARACTERS',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CharacterScreen(),
                      ),
                    );
                  },
                  width: double.infinity,
                  height: 50,
                  color: Colors.teal,
                  onSoundCallback: _playButtonSound,
                ),

                const SizedBox(height: 20),

                // Ses ve Müzik Kontrolleri
                /* Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ses açma/kapama
                    IconButton(
                      icon: Icon(
                        //_audioService.isSoundEnabled
                        //    ? Icons.volume_up
                        //    : Icons.volume_off,
                        Icons.volume_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          //_audioService.toggleSound();
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    // Müzik açma/kapama
                    IconButton(
                      icon: Icon(
                        //_audioService.isMusicEnabled
                        //    ? Icons.music_note
                        //    : Icons.music_off,
                        Icons.music_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          //_audioService.toggleMusic();
                        });
                      },
                    ),
                  ],
                ), */
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Dikey ekran düzeni (mevcut düzen)
  Widget _buildPortraitLayout(BuildContext context, GameState gameState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Üst kısım: Başlık ve yüksek skor
        Expanded(
          flex: 2,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ENDLESS RUNNER',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black45,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'High Score: ${gameState.highScore}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 5,
                        color: Colors.black45,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${gameState.coins}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Seviye bilgisi göster
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Level ${gameState.playerLevel}: ${gameState.currentLevel.name}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // XP ilerleme çubuğu
                      SizedBox(
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: gameState.xpPercentage,
                            backgroundColor: Colors.grey[700],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.amber,
                            ),
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${gameState.currentXP} / ${gameState.xpForNextLevel} XP",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Orta kısım: Menü butonları
        Expanded(
          flex: 3,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ayarlar butonu
                    MenuButton(
                      text: 'SETTINGS',
                      onPressed: () {
                        // TODO: Ayarlar sayfasını göster
                      },
                      width: constraints.maxWidth * 0.7,
                      height: 60,
                      color: Colors.blueGrey,
                      onSoundCallback: _playButtonSound,
                    ),
                    const SizedBox(height: 20),
                    // Reklam izle ve ödül kazan butonu
                    MenuButton(
                      text: 'GET COINS (Watch Ad)',
                      onPressed: () {
                        // TODO: Reklam servisini çağır
                      },
                      width: constraints.maxWidth * 0.7,
                      height: 60,
                      color: Colors.green,
                      onSoundCallback: _playButtonSound,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Seviye seçim dialogu
  void _showLevelsDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Level'),
          content: Consumer<GameState>(builder: (context, gameState, child) {
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: gameState.availableLevels.length,
                itemBuilder: (BuildContext context, int index) {
                  final level = gameState.availableLevels[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text((index + 1).toString()),
                    ),
                    title: Text(level.name),
                    subtitle: Text(level.description),
                    trailing: level.isUnlocked
                        ? (gameState.currentLevelId == level.id
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null)
                        : const Icon(Icons.lock, color: Colors.grey),
                    onTap: level.isUnlocked
                        ? () {
                            //_playButtonSound();
                            print(
                                "Seviye seçildi (ID: ${level.id}) - GameState güncellemesi gerekli.");
                            Navigator.of(context).pop();
                          }
                        : null,
                    enabled: level.isUnlocked,
                  );
                },
              ),
            );
          }),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

// Ana menü butonu için özel widget
class MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final Color color;
  final VoidCallback? onSoundCallback;

  const MenuButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.width,
    required this.height,
    required this.color,
    this.onSoundCallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.5),
        ),
        onPressed: () {
          onSoundCallback?.call();
          onPressed();
        },
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
