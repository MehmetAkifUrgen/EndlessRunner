import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../services/ad_service.dart';
import 'game_screen.dart';
import 'theme_shop_screen.dart';
import '../services/audio_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Ses servisi
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  // Ses başlatma
  Future<void> _initAudio() async {
    await _audioService.initialize();
    _audioService.playMusic(MusicTrack.menu);
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  // Buton tıklama sesi
  void _playButtonSound() {
    _audioService.playSfx(SoundEffect.collect);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

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
          child: Column(
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
                        'En Yüksek Skor: ${gameState.highScore}',
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
                              "Seviye ${gameState.playerLevel}: ${gameState.currentLevel.name}",
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
                          // Oyna butonu
                          MenuButton(
                            text: 'OYNA',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const GameScreen(),
                                ),
                              );
                            },
                            width: constraints.maxWidth * 0.7,
                            height: 60,
                            color: gameState.currentTheme.primaryColor,
                            onSoundCallback: _playButtonSound,
                          ),
                          const SizedBox(height: 20),

                          // Seviye Seç butonu
                          MenuButton(
                            text: 'SEVİYE SEÇ',
                            onPressed: () {
                              _showLevelSelectDialog(context);
                            },
                            width: constraints.maxWidth * 0.7,
                            height: 60,
                            color: Colors.orangeAccent,
                            onSoundCallback: _playButtonSound,
                          ),
                          const SizedBox(height: 20),

                          // Tema Mağazası butonu
                          MenuButton(
                            text: 'TEMA MAĞAZASI',
                            onPressed: () {
                              _showThemeShopDialog(context);
                            },
                            width: constraints.maxWidth * 0.7,
                            height: 60,
                            color: Colors.purpleAccent,
                            onSoundCallback: _playButtonSound,
                          ),
                          const SizedBox(height: 20),

                          // Ayarlar butonu
                          MenuButton(
                            text: 'AYARLAR',
                            onPressed: () {
                              // TODO: Ayarlar sayfasını göster
                            },
                            width: constraints.maxWidth * 0.7,
                            height: 60,
                            color: Colors.blueGrey,
                            onSoundCallback: _playButtonSound,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Alt kısım: Telif hakkı bilgisi
              Expanded(
                flex: 1,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '© 2023 Endless Runner',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Made with Flutter & Flame',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Geliştirici bilgisi
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Geliştirici: Barış',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tema mağazası diyalog penceresi
  void _showThemeShopDialog(BuildContext context) {
    // ... existing code ...
  }

  // Seviye seçim diyalog penceresi
  void _showLevelSelectDialog(BuildContext context) {
    final gameState = Provider.of<GameState>(context, listen: false);
    final levels = gameState.availableLevels;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade900, Colors.indigo.shade900],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SEVİYE SEÇ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Her seviye farklı zorluk ve puan çarpanları içerir',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      final bool isUnlocked = level.isUnlocked;
                      final bool isCurrent =
                          level.id == gameState.currentLevelId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? Colors.amber.withOpacity(0.3)
                              : Colors.black38,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isCurrent ? Colors.amber : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isUnlocked ? Colors.green : Colors.grey,
                            child: Text(
                              '${level.id}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            level.name,
                            style: TextStyle(
                              color: isUnlocked ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            level.description,
                            style: TextStyle(
                              color: isUnlocked
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Puan: ${(level.scoreMultiplier).toStringAsFixed(1)}x',
                                style: TextStyle(
                                  color:
                                      isUnlocked ? Colors.white70 : Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Hız: ${(level.speedMultiplier).toStringAsFixed(1)}x',
                                style: TextStyle(
                                  color:
                                      isUnlocked ? Colors.white70 : Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          enabled: isUnlocked,
                          onTap: isUnlocked
                              ? () {
                                  // Seviyeyi seç
                                  gameState.setCurrentLevel(level.id);
                                  Navigator.of(context).pop();
                                }
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                MenuButton(
                  text: 'KAPAT',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  width: 120,
                  height: 50,
                  color: Colors.redAccent,
                  onSoundCallback: _playButtonSound,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Menü butonları için özel widget
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
    return InkWell(
      onTap: () {
        // Ses efekti
        if (onSoundCallback != null) {
          onSoundCallback!();
        }
        onPressed();
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
